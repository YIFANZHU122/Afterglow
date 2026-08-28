# World Scene Environment Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reuse the existing `WorldEnvironmentPresenter` in every currently enterable world scene.

**Architecture:** World scenes remain composition roots and instantiate the reusable presentation scene as a root child. The Presenter continues to consume only `GameManager` read-only state and existing signals, so no gameplay or persistence rules move into presentation.

**Tech Stack:** Godot 4.7.1, GDScript, `.tscn` scene composition, project scene test runner.

## Global Constraints

- Preserve all existing uncommitted work and do not use destructive Git operations.
- Do not change GameManager, survival, disaster, combat, Boss, save, or input contracts.
- Follow test-first red-green verification and run the full project validation suite.

---

### Task 1: Add Failing World Coverage Assertions

**Files:**
- Modify: `tests/run_scene_tests.gd`

**Interfaces:**
- Consumes: `WorldEnvironmentPresenter` scene node names from plan 020.
- Produces: scene-level regression coverage for Cihang Outskirts and Final Core.

- [x] Add assertions that both scenes contain `WorldEnvironmentPresenter`.
- [x] Assert each instance contains `MoonSprite`, `WeatherTint`, `FogLayer`, and `ParticleLayer`.
- [x] Run `scene_test_runner.tscn` and confirm failures identify only the two missing instances.

### Task 2: Compose Presenter Into Remaining World Scenes

**Files:**
- Modify: `scenes/world/cihang_outskirts/cihang_outskirts.tscn`
- Modify: `scenes/world/final_core/final_core.tscn`

**Interfaces:**
- Consumes: `res://scenes/presentation/world_environment_presenter.tscn`.
- Produces: root child named `WorldEnvironmentPresenter` in both scenes.

- [x] Add one `PackedScene` external resource to each world scene.
- [x] Instantiate the Presenter once at the world root without altering gameplay nodes.
- [x] Run `scene_test_runner.tscn` and confirm the scene suite passes.

### Task 3: Document And Verify

**Files:**
- Modify: `docs/开发计划文档/计划022-世界场景环境表现覆盖.md`
- Modify: `docs/开发计划文档目录.md`
- Create: `docs/任务报告/报告023-世界场景环境表现覆盖.md`

**Interfaces:**
- Consumes: project plan/report format and standard validation commands.
- Produces: completed plan record and reproducible verification evidence.

- [x] Record changed files, red-green evidence, risks, and residual work.
- [x] Run model, Presenter focus, scene, framework, editor, main-scene, and diff checks.
- [x] Mark plan 022 and its index entry complete only after every verification succeeds.
