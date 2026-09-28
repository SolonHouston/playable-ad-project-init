---
name: playable-ad-project-init
description: Initialize a new playable-ad project from a deterministic, non-overwriting workspace template with requirement, interaction, acceptance, asset, change, development, and decision records. Use when starting a new playable-ad production or reskin project; do not use to implement the ad or restructure an existing project.
---

# Playable Ad Project Init

Create only the project workspace and intake records. Do not implement gameplay, install dependencies, generate assets, transform supplied materials, or make product decisions.

## Intake

Before running the initializer:

1. Read applicable instruction files and inspect the requested destination parent directory.
2. Obtain a clear project name. Ask only if the name or destination cannot be inferred safely.
3. Confirm that the exact destination project directory does not already exist. If it exists, stop; this skill is not an updater or merger.
4. Treat briefs, references, existing code, and company assets as inputs to inventory after initialization. Do not move, copy, rename, or edit them unless the user explicitly requests that separate action.

## Initialize

Run the bundled script with absolute paths:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<skill-folder>\scripts\init_playable_ad_project.ps1" -ProjectName "<project-name>" -DestinationRoot "<existing-parent-directory>"
```

The script must remain the source of truth for the generated layout. Do not recreate the tree manually when the script can run. It creates a new project directory, copies the maintained templates, substitutes the project name and creation date, and creates the empty intake, categorized asset, source, test, and tooling directories.

## Safety boundaries

- Never pass a workspace root, drive root, home directory, or existing project directory as the new project itself. `DestinationRoot` is the existing parent; `ProjectName` becomes one new child directory.
- Never delete, replace, or merge an existing target to make initialization succeed.
- Never infer that initialization authorizes implementation.
- Never populate requirement fields from filenames alone. Leave unknown fields marked `待填写` until the source artifacts are inspected.
- Keep supplied source materials intact. Recommend placing planning and reference files under `docs/references/` and unclassified company assets under `assets/inbox/`, but do not copy them without explicit authorization.
- If the user wants to initialize inside an existing codebase, stop and propose a non-destructive document-only plan instead of running this initializer.

## Verify and hand off

After running the script:

1. Confirm every path reported by the script exists.
2. Confirm the project contains `README.md`, `AGENTS.md`, all maintained `docs/` templates, and the expected empty directories.
3. Confirm no files outside the new project directory changed.
4. Report the created path and list inputs still needed: planning brief, reference playable or media, source code when applicable, asset package, target platform, and delivery constraints.
5. Stop after initialization. Recommend using `$playable-ad-workflow` for requirement confirmation and staged implementation when it is available, but do not invoke it automatically.
