# GitHub Copilot Instructions

## Purpose

This repository uses GitHub Copilot to assist with code suggestions, documentation, and tests. These instructions provide Copilot with context on how to contribute effectively.

## General Guidelines

- Prefer clear, readable, and maintainable code over overly clever or compressed solutions.
- Follow existing code style and conventions in this repository (naming, formatting, comments).
- Add comments or docstrings for complex functions or classes.
- When suggesting examples, keep them minimal and focused.
- Only implement the bare minimum code needed to satisfy the current request.
- Work in small, incremental steps and avoid rushing ahead.
- Follow the "You Ain't Gonna Need It" (YAGNI) principle.
- Keep solutions easy to change.

## Testing & Robustness

- Include error handling where appropriate.
- When writing tests, cover happy path and edge cases.
- Prefer deterministic outputs to reduce flaky tests.
- Avoid mocked tests; unit tests must verify actual behavior, not just theoretical outcomes.

## Documentation

- Use plain, concise language for comments and docs.
- Provide examples when introducing new concepts or APIs.

## Code Quality Preferences

- Favor standard libraries before third-party dependencies, unless clearly beneficial.
- Strive for modularity: break down large functions into smaller, reusable pieces.
- Use descriptive names for variables, functions, and classes.

## Non-Code Tasks

- Suggest README updates if code changes introduce new functionality.
- Help maintain consistent formatting across Markdown and config files.
