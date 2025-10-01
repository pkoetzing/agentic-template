Overview of PowerShell helper scripts used by the specify workflow

This folder contains small PowerShell helper scripts that support the Spec-Driven Development workflow used in this repository.

Files
-----

- `common.ps1` — Shared helper functions used by the other scripts. Provides utilities to locate the repository root, determine the current feature branch, build feature path values (spec.md, plan.md, tasks.md, etc.), and simple test helpers for files and directories.

- `create-new-feature.ps1` — Creates a new feature directory and (when available) a git branch. Generates a numbered feature name from an incremental counter in `specs/`, copies a spec template if present, and sets `SPECIFY_FEATURE` in the session. Supports a `-Json` flag for machine-readable output.

- `get-feature-paths.ps1` — Prints computed feature-related paths (repo root, branch, feature dir, spec.md, plan.md, tasks.md). Validates that the current branch looks like a feature branch.

- `setup-plan.ps1` — Ensures a feature's implementation plan file (`plan.md`) exists by creating the feature directory and copying a plan template if available. Outputs created paths and supports `-Json`.

- `check-prerequisites.ps1` — Consolidated prerequisite checker for different workflow phases. Validates branch naming, presence of `plan.md`, and optionally `tasks.md`. Can output results in JSON or plain text, support `-PathsOnly`, and include `tasks.md` in the AVAILABLE_DOCS list.

- `check-implementation-prerequisites.ps1` — Phase-specific check used before implementation. Ensures the current branch is a feature branch and that `plan.md` and `tasks.md` exist; prints available optional docs. Supports `-Json` output.

- `check-task-prerequisites.ps1` — Phase-specific check used before writing tasks. Ensures the current branch is a feature branch and that `plan.md` exists; prints available optional docs. Supports `-Json` output.

- `update-agent-context.ps1` — Parses `plan.md` and updates or creates various AI agent context files (CLAUDE.md, GEMINI.md, GitHub Copilot instructions, Cursor/Qwen/Windsurf rule files, etc.) from a template. Extracts fields like language, framework, storage, and project type to populate and/or update agent files and recent changes. Supports updating a single agent via `-AgentType` or all existing agents.

Usage notes
-----------
- Most scripts source `common.ps1` and expect to be run from the repository (they compute the repo root automatically). Many scripts avoid typed switches and ConvertTo-Json to remain compatible with constrained language mode and invocations via `pwsh -File`.
- Several scripts support a `-Json` flag which returns minimal JSON built manually so the output remains usable in environments where `ConvertTo-Json` may be restricted.

If you want me to expand any of these descriptions into longer documentation (examples, flags, and sample outputs), tell me which scripts to expand.
