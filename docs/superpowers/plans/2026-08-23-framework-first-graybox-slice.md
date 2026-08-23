# Framework-First Graybox Slice Implementation Plan

> **For agentic workers:** This plan is executed inline in the current session with the project plan at `docs/开发计划文档/计划010-框架优先灰盒垂直切片.md` as the authoritative checklist.

**Goal:** Deliver a playable, data-driven graybox slice with configurable encounters and a one-choice in-run upgrade before area clear.

**Architecture:** Keep input, rules, state, events, and presentation separated. Use typed Godot Resources for static content, runtime models for in-run state, and scene controllers only for assembly and presentation. Keep the existing floor-compatible run state until a later area naming migration.

**Tech Stack:** Godot 4.7.1, GDScript 2.0, typed Resource classes, existing headless model and scene test runners.

## Global Constraints

- Preserve existing uncommitted user/agent changes; never reset or discard them.
- No plugins, third-party dependencies, new Autoloads, networking, or save schema.
- Use `apply_patch` for manual edits.
- Every logic change gets a failing test before implementation where practical.
- Run model tests, scene tests, editor scan, main-scene startup, and `git diff --check` before completion.

## Task List

### Phase 1: Data and Runtime Rules

- [x] Task 1: Add typed encounter/area/upgrade Resources and `RunBuildModel`.
- [x] Task 2: Add `EncounterMember` and `EncounterController`; migrate basement spawning.

### Checkpoint: Configured Encounter

- [x] Model tests pass.
- [x] Basement loads configured enemies and preserves real attack/contact damage.
- [x] Editor scan passes.

### Phase 2: In-Run Construction

- [x] Task 3: Add GameManager upgrade APIs and reward selection scene.
- [x] Task 4: Add minimal presenter boundary and complete scene regression.

### Checkpoint: Playable Slice

- [x] Objective completion opens reward selection.
- [x] Reward selection applies a runtime modifier and unlocks area clear.
- [x] Reset clears modifiers.

### Final Checkpoint

- [x] All acceptance criteria in plan 010 are checked.
- [x] Godot cold start is verified through editor scan and main-scene startup.
- [x] Task report and plan handoff are complete.
