---
name: update-project-docs
description: Reconcile AGENTS.md and README.md with project skills, plans, and recent changes. Use when maintaining repository guidance or user documentation, or when a repository change makes either document stale.
---

# Update Project Docs

Keep AGENTS.md and README.md concise. References to important files or other docs are optional; use them where they help the reader. Give each document a `Last updated at` commit marker.

## Establish what changed

Read both documents and their revision markers. Review project skills under `.agents/skills/`, relevant plans under `docs/`, recent commits, and the working-tree diff. Use each valid marker to compare changes since that document was last reviewed; if it is missing or unavailable in local history, review the relevant history and files directly. When recomposing AGENTS.md, inspect its earlier revisions for important standing rules lost through previous edits; retain those that still apply without restoring obsolete project descriptions.

Skills describe how contributors work; plans describe intended behavior. Confirm claims about available features, installation, commands, and support against the implementation, manifests, and configuration. Do not present a proposal or an old verification record as a shipped feature or a new passing check. Preserve unrelated work already in progress.

## AGENTS.md: durable guidance

Keep common knowledge and standing project-wide rules that remain useful across ordinary changes, such as language constraints, commit conventions, environment policy, and testing or lifecycle requirements. State important rules directly in AGENTS.md. It may reference important files or supporting docs, but need not be a reference list.

- Do not add or retain skill lists or catalogs in AGENTS.md; the harness automatically injects the available skills.
- Move workflows, procedures, checklists, and detailed task instructions into the appropriate project skill, preserving their requirements. Do not extract a standing rule merely because it could also appear in a skill.
- Remove snapshots of code or documentation: directory inventories, current architecture, tool versions, feature status, and descriptions of what files currently contain.
- Prefer an existing skill over a duplicate. If a new skill is needed, keep it scoped to the extracted task. Repair references affected by the move, including skills that previously sent readers to AGENTS.md or README.md for those details.

## README.md: potential users

Explain what the project does, who can use it, and the shortest supported path to getting started. Mention only the capabilities and limitations that help someone decide whether to use it.

Link to setup details, contributor guidance, or specialist docs when needed. Keep implementation inventories, internal verification procedures, CI tuning, exhaustive configuration options, and plan-by-plan history out of the README. Retain useful detail in its owning skill or supporting doc rather than copying it across documents. Do not invent release downloads or installation channels.

## Revision markers and review

Use a footer in each document: ``Last updated at: `<full commit hash>`.`` Resolve the hash with `git rev-parse HEAD` after reviewing that revision. It records the project revision reviewed, not the commit containing the documentation edit; do not amend repeatedly to chase a self-referential hash. When including current working-tree changes, retain this committed baseline and identify those changes in the delivery summary. Never advance a marker past changes actually reviewed.

Check local links, commands, feature claims, formatting, preservation of extracted requirements, and retention of important standing rules. Confirm both documents serve their intended readers without duplicating detailed skill procedures. For documentation-only changes, use document and skill validation. Report the documents updated, the reviewed revision, and any unresolved discrepancies.
