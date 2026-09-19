---
name: ask-astra
description: "Consult gpt-6-astra through Herdr for design advice and substantive reviews that benefit from extensive thinking. Use for difficult architectural tradeoffs, challenging a proposed approach, or an independent review of consequential changes. Requires a Herdr-managed caller."
---

# Ask Astra

`gpt-6-astra` is OpenAI's most capable model for complex, demanding work. Use it as a thinking partner for design and review: give it room to reason extensively about competing approaches, module boundaries, hidden assumptions, and failure modes. A focused consultation can expose weaknesses before implementation or catch problems in a substantial change.

Proactively reach out when a consequential design choice remains uncertain or an independent review would materially improve confidence. Ask early enough for the advice to change the approach. You remain responsible for the decision, implementation, and verification.

## Consult through Herdr

Check `HERDR_ENV=1` before interacting with Herdr. If it is absent, explain that this consultation needs a Herdr-managed pane and continue any independent work; do not control an unrelated session or silently substitute another delegation mechanism.

Read the available `herdr` skill for pane creation, agent lifecycle, and output retrieval. If it is not available in the skill catalog, read `herdr --skill` after the environment check. Use the installed CLI's help for current syntax.

Create a sibling pane using Herdr's layout guidance, preserving the caller's working directory and focus. Choose a unique agent name, and use the pane ID returned by Herdr. Start Codex with the exact model and an explicit reasoning effort, for example:

```bash
herdr agent start astra-design --kind codex --pane <returned-pane-id> -- \
  --model gpt-6-astra -c 'model_reasoning_effort="xhigh"' \
  --sandbox read-only --no-alt-screen
```

Use `xhigh` for substantial design and review questions; consider `max` for especially difficult, intertwined constraints when the extra thinking time is worthwhile. Honor an explicit user preference. Confirm startup succeeds with the requested model; report an unavailable model rather than silently substituting one. Reuse an advisor you started for follow-up questions on the same task.

## Give Astra a useful brief

A new agent does not inherit your conversation. Include the user's objective, constraints, relevant file paths, and the exact question you need answered. For a review, identify the diff or baseline and distinguish your changes from unrelated work. For design advice, describe viable options and uncertainties without steering Astra toward agreement.

Ask for advisory work: inspect the relevant material and return recommendations, without editing the working tree or launching further advisors. Give it permission to spend time thinking deeply. Request a concise rationale, tradeoffs, and actionable findings grounded in the code or supplied evidence. Useful prompts include:

- Design: “Compare these approaches against the constraints. Challenge my assumptions, recommend a boundary or design, and identify what evidence would change your recommendation.”
- Review: “Review this change against the intended behavior. Identify correctness risks and missing cases, with file locations and concrete failure scenarios. State any remaining uncertainty.”

Send the complete brief with `herdr agent prompt`. Allow extended reasoning to finish; a wait timeout alone is not a failed consultation. Use bounded waits, inspect status and output between them, and continue useful independent work while Astra thinks. If the advisor is blocked, inspect the cause and follow Herdr's guidance rather than answering an approval dialog blindly.

## Use the advice

Read the completed response through `herdr agent read`, following the Herdr skill's fallback if terminal output is incomplete. Check the recommendation against the user's constraints and the actual code. Ask a focused follow-up when a material claim is unclear, then apply the advice you judge sound and explain consequential disagreements. Report the resulting decision and remaining uncertainty to the user; Astra's review complements your own verification.
