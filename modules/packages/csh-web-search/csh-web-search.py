#!/usr/bin/env python3
"""MCP stdio server exposing a Codex ``web.run``-style search tool.

The tool mirrors the search subset of Codex's standalone web-search tool so a
DeepSeek-backed Codex session gets a familiar interface. DeepSeek exposes no
dedicated retrieval endpoint, so each query runs one Anthropic-compatible
Messages request with the native ``web_search_20250305`` server tool and the
answer and source list are returned to the model.
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request

SERVER_NAME = "csh-web-search"
SERVER_VERSION = "1.0.0"
TOOL_NAME = "run"
DEFAULT_BASE_URL = "https://api.deepseek.com/anthropic"
DEFAULT_MODEL = "deepseek-flash"
API_VERSION = "2023-06-01"
SEARCH_TIMEOUT_SECONDS = 60

RESPONSE_LENGTHS = {
    "short": (2048, 3),
    "medium": (8192, 6),
    "long": (16384, 10),
}

SEARCH_SYSTEM_PROMPT = "\n".join(
    [
        "You are a web search assistant. Follow these rules strictly:",
        "",
        "1. Use web_search to find relevant, up-to-date information for the query.",
        "2. After receiving search results, write a concise, factual answer in plain",
        "   text based only on what the results contain. Include dates and specifics.",
        "3. Do not output tool-call markup or call web_search again once you have",
        "   results.",
        "4. Answer in the same language as the query.",
        "5. If the results are irrelevant, say so instead of guessing.",
    ]
)

TOOL_DESCRIPTION = """\
Tool for accessing the internet.

Searches the internet for one or more queries and returns a synthesized answer
plus a numbered source list. Sources carry internal reference IDs (for example
`turn0search0`) that are only valid inside this tool; never expose them in the
final response.

## Examples

* `search_query`: {"search_query": [{"q": "What is the capital of France?"}]}
* Multiple queries: {"search_query": [{"q": "bitcoin news"}, {"q": "ethereum news"}]}
* Filters: {"search_query": [{"q": "NixOS release notes", "recency": 30, "domains": ["nixos.org"]}]}

## Usage hints

* Use multiple queries in one call to get more results faster.
* `search_query` must have length at most 4 in each call. If it has length > 3,
  `response_length` must be `medium` or `long`.
* Use `response_length` (`short`, `medium`, `long`) to control how much is
  returned; omit it to get `short`.
* Only write required parameters; do not write empty lists or nulls where they
  can be omitted.

## Decision boundary

If the user makes an explicit request to search the internet, find the latest
information, look something up, or not to do so, you must obey that request.
When you make an assumption, consider whether it is temporally stable; if there
is even a small (>10%) chance it has changed, verify it by searching.

Browse the internet when:

- The information could have changed recently: news, prices, laws, schedules,
  product specs, sports scores, economic indicators, public/company figures,
  rules, regulations, standards, software libraries, recommendations, and
  similar.
- The user is seeking recommendations that could lead them to spend substantial
  time or money.
- The user wants direct quotes, links, or precise source attribution.
- A specific page, paper, dataset, PDF, or site is referenced and you have not
  been given its contents.
- You are unsure about a fact, the topic is niche or emerging, or you suspect a
  >=10% chance of misremembering it.
- High-stakes accuracy matters (medical, legal, financial guidance).
- The user explicitly says to search, browse, verify, or look it up.

## Citations

Cite sources in the final response using Markdown links to the page that
supports the claim. Place each citation next to the claim it supports, normally
at the end of the sentence or paragraph and after punctuation. Do not link to
search-result pages or use bare URLs, and do not collect all citations at the
end of the response.
"""

TOOL_SCHEMA = {
    "type": "object",
    "properties": {
        "search_query": {
            "type": "array",
            "description": "Queries to run against the internet search engine.",
            "items": {
                "type": "object",
                "properties": {
                    "q": {
                        "type": "string",
                        "description": "Search query.",
                    },
                    "recency": {
                        "type": "integer",
                        "description": "Filter by recency, as a number of recent days.",
                    },
                    "domains": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Restrict results to these domains.",
                    },
                },
                "required": ["q"],
                "additionalProperties": False,
            },
        },
        "response_length": {
            "type": "string",
            "enum": ["short", "medium", "long"],
            "description": "How much search output to return.",
        },
    },
    "additionalProperties": False,
}


class ToolError(Exception):
    """A user-facing tool failure that should be reported to the model."""


def log(*parts: object) -> None:
    print(f"[{SERVER_NAME}]", *parts, file=sys.stderr, flush=True)


def send(message: dict) -> None:
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


def send_result(request_id: object, result: object) -> None:
    send({"jsonrpc": "2.0", "id": request_id, "result": result})


def send_error(request_id: object, code: int, message: str) -> None:
    send({"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}})


def http_post_json(url: str, body: dict, api_key: str) -> dict:
    data = json.dumps(body).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={
            "content-type": "application/json",
            "x-api-key": api_key,
            "anthropic-version": API_VERSION,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=SEARCH_TIMEOUT_SECONDS) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace").strip()
        raise ToolError(f"DeepSeek search failed with HTTP {error.code}: {detail}") from error
    except (urllib.error.URLError, TimeoutError, OSError) as error:
        raise ToolError(f"DeepSeek search request failed: {error}") from error


def search_once(
    query: str,
    *,
    api_key: str,
    base_url: str,
    model: str,
    max_tokens: int,
    recency: int | None,
    domains: list[str] | None,
) -> tuple[str, list[dict]]:
    prompt = f"Perform a web search for the query: {query}"
    filters = []
    if recency is not None:
        filters.append(f"prefer results from the last {recency} days")
    if domains:
        filters.append(f"restrict results to these domains: {', '.join(domains)}")
    if filters:
        prompt += f" ({'; '.join(filters)})"

    tool: dict = {"type": "web_search_20250305", "name": "web_search", "max_uses": 5}
    if domains:
        tool["allowed_domains"] = domains

    body = {
        "model": model,
        "max_tokens": max_tokens,
        "system": SEARCH_SYSTEM_PROMPT,
        "messages": [{"role": "user", "content": prompt}],
        "tools": [tool],
        "tool_choice": {"type": "auto"},
    }
    payload = http_post_json(base_url.rstrip("/") + "/v1/messages", body, api_key)

    answer_parts: list[str] = []
    results: list[dict] = []
    for block in payload.get("content", []) if isinstance(payload, dict) else []:
        block_type = block.get("type")
        if block_type == "web_search_tool_result":
            for item in block.get("content") or []:
                if item.get("type") != "web_search_result":
                    continue
                results.append(
                    {
                        "title": item.get("title") or "Untitled",
                        "url": item.get("url") or "",
                        "page_age": item.get("page_age"),
                    }
                )
        elif block_type == "text":
            text = (block.get("text") or "").strip()
            if text:
                answer_parts.append(text)

    return "\n\n".join(answer_parts), results


def format_output(query: str, answer: str, results: list[dict], start_index: int) -> str:
    lines = [f"Search results for: {query}", ""]
    if answer:
        lines.extend([answer, ""])
    if results:
        lines.append("Sources:")
        for offset, result in enumerate(results):
            reference = f"turn0search{start_index + offset}"
            age = f" ({result['page_age']})" if result.get("page_age") else ""
            lines.append(f"* {reference}: [{result['title']}]({result['url']}){age}")
    elif not answer:
        lines.append("No results found. Try rephrasing the query.")
    return "\n".join(lines).rstrip() + "\n"


def call_tool(arguments: dict) -> dict:
    api_key = os.environ.get("DEEPSEEK_API_KEY") or os.environ.get("WEBSEARCH_API_KEY")
    if not api_key:
        raise ToolError("DEEPSEEK_API_KEY is not set for the csh-web-search server.")

    queries = arguments.get("search_query") or []
    if not isinstance(queries, list) or not queries:
        raise ToolError("Provide at least one entry in `search_query`.")

    response_length = arguments.get("response_length") or "short"
    max_tokens, max_sources = RESPONSE_LENGTHS.get(response_length, RESPONSE_LENGTHS["short"])

    base_url = os.environ.get("CSH_WEB_SEARCH_BASE_URL", DEFAULT_BASE_URL)
    model = os.environ.get("CSH_WEB_SEARCH_MODEL", DEFAULT_MODEL)

    sections: list[str] = []
    next_index = 0
    for entry in queries[:4]:
        if not isinstance(entry, dict) or not (entry.get("q") or "").strip():
            raise ToolError("Every `search_query` entry needs a non-empty `q`.")
        answer, results = search_once(
            entry["q"].strip(),
            api_key=api_key,
            base_url=base_url,
            model=model,
            max_tokens=max_tokens,
            recency=entry.get("recency"),
            domains=entry.get("domains"),
        )
        results = [result for result in results if result.get("url")]
        sections.append(format_output(entry["q"].strip(), answer, results[:max_sources], next_index))
        next_index += min(len(results), max_sources)

    return {"content": [{"type": "text", "text": "\n".join(sections).strip()}]}


def handle(request: dict) -> None:
    method = request.get("method")
    request_id = request.get("id")

    if method == "initialize":
        params = request.get("params") or {}
        protocol_version = params.get("protocolVersion") or "2025-06-18"
        send_result(
            request_id,
            {
                "protocolVersion": protocol_version,
                "capabilities": {"tools": {}},
                "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
            },
        )
        return

    if method == "ping":
        send_result(request_id, {})
        return

    if method == "tools/list":
        send_result(
            request_id,
            {
                "tools": [
                    {
                        "name": TOOL_NAME,
                        "description": TOOL_DESCRIPTION,
                        "inputSchema": TOOL_SCHEMA,
                    }
                ]
            },
        )
        return

    if method == "tools/call":
        params = request.get("params") or {}
        if params.get("name") != TOOL_NAME:
            send_result(
                request_id,
                {
                    "content": [
                        {"type": "text", "text": f"Unknown tool: {params.get('name')}"}
                    ],
                    "isError": True,
                },
            )
            return
        try:
            result = call_tool(params.get("arguments") or {})
        except ToolError as error:
            send_result(
                request_id,
                {"content": [{"type": "text", "text": str(error)}], "isError": True},
            )
        else:
            send_result(request_id, result)
        return

    if isinstance(request_id, (str, int)):
        send_error(request_id, -32601, f"Method not found: {method}")


def main() -> int:
    log(f"{SERVER_NAME} {SERVER_VERSION} listening")
    for raw_line in sys.stdin.buffer:
        line = raw_line.decode("utf-8", "replace").strip()
        if not line:
            continue
        try:
            request = json.loads(line)
        except json.JSONDecodeError:
            log("ignoring invalid JSON:", line[:200])
            continue
        if not isinstance(request, dict):
            continue
        if request.get("id") is None:
            continue
        try:
            handle(request)
        except Exception as error:  # noqa: BLE001 - report any failure to the client
            log("internal error:", error)
            send_error(request.get("id"), -32603, f"Internal error: {error}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
