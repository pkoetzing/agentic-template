# Constrained Language Mode (CLM) Helper Prompt


## Description

Helper prompt for converting repository PowerShell scripts to be compatible
with PowerShell Constrained Language Mode (CLM). Use this prompt
when an agent or reviewer needs to scan `.specify/scripts/powershell/*.ps1`
and produce safe, minimal edits that avoid non-core types
and disallowed operations in CLM.

## Usage

1. Run
  `powershell -NoProfile -Command "Get-ChildItem -Path '.specify\\scripts\\powershell\\*.ps1' | Unblock-File"`
  to clear the downloaded-file block on every script in `.specify/scripts/powershell`.
2. Read all scripts in `.specify/scripts/powershell/` and identify any non-CLM-safe  constructs while still in read-only mode.
3. Propose minimal, deterministic fixes that keep behavior unchanged and document the rationale before applying them.
4. Apply the approved fixes, keeping edits incremental and well-commented.
5. Run the smoke test `powershell -NoProfile -ExecutionPolicy Bypass -File
  .\.specify\scripts\powershell\check-prerequisites.ps1 -Json` to verify the changes.

## Goals

- Ensure scripts do not rely on PSCustomObject conversions that fail in CLM.
- Avoid ConvertTo-Json on complex objects; if JSON is required, build JSON
  strings using only strings, arrays, and hashtables.
- Avoid parameter binding patterns that require complex type coercion in CLM.
- Prefer hashtables and indexer access (`$h['KEY']`) over property access on
  complex objects that may be PSCustomObject.
- Keep changes small and reversible; add compatibility paths rather than remove
  original implementations.

## Checklist (detection)

Scan all `.ps1` files under `.specify/scripts/powershell/` for these patterns:

- Creation of `[PSCustomObject]@{ ... }` and subsequent `ConvertTo-Json`.
- Calls to `ConvertTo-Json` on non-primitive structures.
- Parameter declarations using `[switch]` or strongly-typed parameters that
  may be passed string values when invoked via `-File` and `$args`.
- Use of `.GetType()` or other runtime type introspection and dynamic
  conversions.
- Use of advanced pipeline binding patterns that create non-core objects.

## Recommendations (fix patterns)

1. Replace `PSCustomObject` returns with plain hashtables when possible.

   Example:
   ```powershell
   # From:
   [PSCustomObject]@{ FEATURE_DIR=$repoRoot; AVAILABLE_DOCS=$docs }

   # To:
   @{ 'FEATURE_DIR' = $repoRoot; 'AVAILABLE_DOCS' = $docs }
   ```

2. Avoid `ConvertTo-Json` on complex objects in CLM. If JSON output is required
   by automation, build the JSON string using core types:
   - Ensure strings are escaped for double-quotes
   - Build arrays with string elements `['a','b']` and join with `,`
   - Compose final JSON as `'{"k":"v","arr":["a"]}'` and `Write-Output` it

3. Replace `[switch]$Flag` parameters with lightweight `$args` detection for
   scripts executed via `powershell -File script.ps1 -Flag` in environments
   that may coerce switches to strings. Example:
   - Detect: `if ($args -contains '-Json') { $Json = $true }`

4. When returning path collections or config, prefer hashtable indexer access
   (e.g., `$paths['FEATURE_DIR']`) so callers that expect plain hashtables or
   strings will work in CLM.

5. Avoid creating or returning types not in the set of core CLR types that
   CLM allows. If a library call returns complex types, convert them to
   primitive representations (strings, numbers, booleans, arrays) immediately.

6. If script logic relies on `Get-ChildItem | Select-Object -First 1` or
   similar pipeline constructs that can return objects, convert the result to
   strings explicitly before placing them into shared structures.

## Quality Gates for Proposed Edits

- All edited scripts must run in a restricted CLM environment and not throw
  the earlier "Cannot convert value to type 'System.Management.Automation.LanguagePrimitives+InternalPSCustomObject'" error.
- Edits must preserve the original script's external behavior (same outputs
  and exit codes under normal conditions).
- Keep diffs minimal: prefer targeted replacements over broad rewrites.

## Example Workflow for an Agent Using This Prompt

1. Read all `.ps1` files under `.specify/scripts/powershell/` and list
   detected risky constructs with file locations.
2. For each risky construct, propose a minimal replacement snippet and the
   rationale (one-line). Do not apply changes yet.
3. After approval, apply edits file-by-file and run a smoke script:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\.specify\scripts\powershell\check-implementation-prerequisites.ps1 -Json`
4. If the smoke script emits valid JSON and no CLM conversion errors occur,
   consider the file fixed. Otherwise iterate.

## Security and Testing Notes

- Do not modify scripts that manage secrets or credentials; only convert
  general-purpose helper scripts. If a script touches secret storage, flag
  it for manual review.
- Run checks in a safe environment; do not attempt to change system-wide
  PowerShell policy from within the agent.

## Limitations

- This prompt cannot guarantee the absence of all CLM incompatibilities; it
  focuses on common causes (PSCustomObject, ConvertTo-Json, typed switches).
- Manual review is recommended for scripts that use advanced APIs or COM
  interop.

---
