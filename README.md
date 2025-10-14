# Agentic Coding with Specification

## GitHub Sources

### Copilot prompts and instructions

https://github.com/github/awesome-copilot

### Spec Kit

https://github.com/github/spec-kit

Installed release: [spec-kit-0.0.62](https://github.com/github/spec-kit/releases/download/v0.0.62/spec-kit-template-copilot-ps-v0.0.62.zip)

Run clm-helper.prompt.md after every update to unblock downloaded .ps1 files and make them compatible with powershell's contrained language mode.

## Artifacts

### constitution.md

Non-negotiable, governing principles and development guidelines for the project.

```
/speckit.constitution  
Pick 3 principles for static web apps using vanilla HTML/CSS/JS, no frameworks, minimal dependencies, no unit tests, no smoke tests.
```

```
/speckit.constitution  
A Python script without a user interface or command line arguments, but with a config.json file in the project root. Each project must have its own virtual environment in the .venv folder and a pyproject.toml file in the root folder. Each project must be installed in editable mode. Logging and pytest unit tests are required, but must be limited to the essentials. Do not use mocking frameworks or patched call sites in unit tests. Only create the bare minimum code. The ultimate goal is to keep things easy to change.
```

### spec.md

Definition of what to build, requirements and user stories.  
**Creates a new feature branch from main.**

```
/speckit.specify  
Neon-lit Tetris you can play in a browser. 
```

```
/speckit.specify
Mirror manuals hosted below given start urls into a local output path so the manuals are fully navigable offline. For each start URL, crawl only pages in the same path scope and download their HTML and same-site assets (CSS, JS, images, fonts). Rewrite internal links and asset references to local relative paths and save content under local output path, preserving the online relative structure. The site requires login via a login page with credentials from .env (dotenv). Additional configuration parameters are set in config.json in the project root. The output path has to be cleared before each run to avoid stale content. 
```

### plan.md

Technical implementation plan with a chosen tech stack

```
/speckit.plan 
```

### task.md

Actionable task list for implementation

```
/speckit.task
```

## Helper Scripts

### /speckit.clarify

Clarify underspecified areas, must be run before /speckit.plan

### /speckit.analyze

Check cross-artifact consistency & coverage analysis, run after /speckit.task, before /speckit.implement

### /speckit.checklist

Generate custom quality checklists that validate requirements completeness, clarity, and consistency

### /speckit.implement

Execute all tasks to build the feature according to the plan

---

