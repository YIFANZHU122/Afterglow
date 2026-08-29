# Framework Content Pack and AI Handoff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Afterglow content authoring explicit and self-validating, then document the framework workflow so another AI can add areas, encounters, upgrades, entities, and presentation without breaking core rules.

**Architecture:** Keep static content in typed Resources, runtime state in existing models/components, and scene scripts limited to composition. Add a pure `ContentValidationModel` for resource contracts, externalize the basement example into an area content pack, and write an AI-facing guide from the verified contracts and commands.

**Tech Stack:** Godot 4.7.1, typed GDScript Resources, headless Godot model/scene tests, Markdown documentation.

## Global Constraints

- Preserve existing uncommitted changes; never reset, discard, or clean unrelated files.
- Do not add plugins, third-party dependencies, Autoloads, networking, or save schema.
- Use `apply_patch` for manual edits.
- Production behavior must have a failing regression test before implementation where practical.
- Static content Resources must not hold runtime mutable state.
- Run model tests, scene tests, editor scan, main-scene startup, and `git diff --check` before completion.

### Task 1: Define the content validation contract

**Files:**
- Modify: `tests/run_model_tests.gd`
- Create: `scripts/data/content_validation_model.gd`

**Interfaces:**
- `ContentValidationModel.validate_spawn(definition: Resource) -> PackedStringArray`
- `ContentValidationModel.validate_encounter(definition: Resource) -> PackedStringArray`
- `ContentValidationModel.validate_area(definition: Resource) -> PackedStringArray`
- `ContentValidationModel.validate_upgrade(definition: Resource) -> PackedStringArray`
- An empty error array means valid; errors must explain the rejected contract and never mutate the Resource.

- [ ] Write failing assertions for valid and invalid spawn, encounter, area, and upgrade Resources.
- [ ] Run `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_model_tests.gd` and confirm the new assertions fail because the validator is missing.
- [ ] Implement the smallest validator using the existing Resource scripts and their public `is_valid()` contracts. Validate the Resource script identity before reading fields.
- [ ] Re-run model tests and confirm `Model tests passed`.

### Task 2: Externalize the basement content pack

**Files:**
- Create: `assets/areas/basement_area.tres`
- Modify: `scenes/world/basement/basement.tscn`
- Modify: `tests/run_scene_tests.gd`

**Interfaces:**
- `basement.tscn` consumes `res://assets/areas/basement_area.tres` through the existing `Basement.area_config: Resource` export.
- The generated encounter must remain two valid members at the same positions and with the same entity scenes.

- [ ] Add a scene regression asserting `Basement.area_config.resource_path == "res://assets/areas/basement_area.tres"` and that the loaded AreaDefinition validates through `ContentValidationModel`.
- [ ] Run the scene test and confirm it fails because the external resource does not exist and the scene still embeds a subresource.
- [ ] Create `assets/areas/basement_area.tres` with embedded typed spawn and encounter subresources referencing the existing dummy/chaser scenes.
- [ ] Replace the inline AreaDefinition subresource in `basement.tscn` with an ext_resource reference while preserving scene composition and gameplay nodes.
- [ ] Re-run scene tests and editor scan.

### Task 3: Add a framework validation entry point and AI guide

**Files:**
- Create: `tests/run_framework_validation.gd`
- Create: `docs/框架/Afterglow框架使用指南-面向AI.md`
- Create: `docs/框架/Afterglow内容契约速查表.md`
- Modify: `README.md`
- Modify: `docs/开发计划文档目录.md`

**Interfaces:**
- `run_framework_validation.gd` loads the external basement AreaDefinition and both upgrade Resources, runs the validator, and exits non-zero on any contract error.
- The AI guide must document: authority files, module ownership, content creation recipes, stable public APIs, scene assembly rules, test commands, failure diagnosis, and prohibited shortcuts.

- [ ] Write the validation runner so it reports each resource path and validation error, then exits `0` only when all content contracts pass.
- [ ] Run the runner before documentation changes and confirm it passes with the external basement pack.
- [ ] Write the AI guide using only verified paths and signatures; include a minimal “add one area” procedure and a “change gameplay rule” escalation procedure.
- [ ] Write the compact contract table for quick agent lookup.
- [ ] Link the guide from `README.md` and register Plan 012 in `docs/开发计划文档目录.md`.
- [ ] Run model tests, scene tests, framework validation, editor scan, main-scene startup, and `git diff --check`.

## Acceptance Criteria

- [ ] Basement area content is external Resource data, not embedded in the scene.
- [ ] Invalid content definitions produce explicit validation errors without crashing or mutating data.
- [ ] Existing combat, pickup, reward, transition, and reset behavior remains green.
- [ ] A standalone framework validation command exists and passes.
- [ ] Another AI can follow the guide to add an area or upgrade without guessing node paths or public APIs.
- [ ] Plan, report, index, and README links are synchronized.

## Risks and Rollback

- External Resource path mistakes could prevent the main scene from loading; scene tests and editor scan must run immediately after migration. Rollback is restoring the original inline subresources in `basement.tscn`.
- Validator strictness could reject existing prototype data; only enforce already-stable public Resource contracts in this plan.
- Documentation can drift from code; every API example must be checked against current signatures before completion.
