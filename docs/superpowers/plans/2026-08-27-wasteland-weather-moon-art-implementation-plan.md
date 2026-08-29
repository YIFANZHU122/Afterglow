# Wasteland Weather and Moon Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add licensed free weather and moon art plus a presentation-only Godot component that renders the existing day/night and disaster states in the approved hand-drawn wasteland style.

**Architecture:** A reusable `WorldEnvironmentPresenter` scene owns all overlays, particles, moon frames, and palette changes. It subscribes to the existing `GameManager` signals and exposes deterministic presentation methods for focused scene tests; no gameplay or persistence state is added.

**Tech Stack:** Godot 4.7.1, GDScript, `.tscn`, PNG/WebP source assets, existing headless test runners.

## Global Constraints

- Keep the existing player model and player AnimationTree unchanged.
- Do not change disaster probability, duration, damage, difficulty, random streams, or save schema.
- Do not add plugins, runtime dependencies, Autoloads, input actions, or project settings.
- Store every third-party asset under `res://assets/art/` and record source, author, license, download date, and URL.
- Preserve unrelated dirty-worktree changes and do not rewrite existing public interfaces.

---

### Task 1: Licensed Asset Intake

**Files:**
- Create: `assets/art/weather/source/`
- Create: `assets/art/moon/source/`
- Create: `assets/art/THIRD_PARTY_ASSETS.md`

**Interfaces:**
- Produces stable `res://assets/art/weather/` and `res://assets/art/moon/` paths consumed by Task 3.

- [x] Download only the selected CC0 moon, fog, smoke, and particle files from their canonical pages.
- [x] Verify downloaded files are non-empty images and record their SHA-256 hashes.
- [x] Add the attribution/license inventory with exact canonical URLs and download date `2026-08-27`.
- [x] Run `git diff --check` and confirm the Markdown contains no placeholder text.

### Task 2: Presenter Contract Tests

**Files:**
- Create: `tests/world_environment_presenter_focus_test.gd`
- Create: `tests/world_environment_presenter_focus.tscn`

**Interfaces:**
- Consumes future methods `present_survival(day_index: int, is_night: bool) -> void` and `present_disaster(kind: int, phase: int) -> void`.
- Asserts query methods `get_moon_phase_index() -> int`, `get_weather_mode() -> StringName`, and `get_weather_strength() -> float`.

- [x] Write a focused scene test asserting new moon fallback, eight-day wrap, day/night moon visibility, warning strength, active strength, and reset for invalid/idle disasters.
- [x] Run `Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/world_environment_presenter_focus.tscn`.
- [x] Confirm RED because `WorldEnvironmentPresenter` and its scene did not exist before implementation.

### Task 3: Reusable World Environment Presenter

**Files:**
- Create: `scripts/presentation/world_environment_presenter.gd`
- Create: `scenes/presentation/world_environment_presenter.tscn`

**Interfaces:**
- Produces `present_survival(day_index: int, is_night: bool) -> void`.
- Produces `present_disaster(kind: int, phase: int) -> void`.
- Produces read-only test queries `get_moon_phase_index() -> int`, `get_weather_mode() -> StringName`, and `get_weather_strength() -> float`.
- Subscribes to existing `GameManager.survival_changed` and `GameManager.disaster_changed` signals.

- [x] Implement deterministic moon index calculation with `(maxi(day_index, 1) - 1) % 8`.
- [x] Map rainstorm, heatwave, dense fog, and cold wave to presentation modes; map all other values to `&"clear"`.
- [x] Apply warning strength `0.35`, active strength `1.0`, and idle/reset strength `0.0`.
- [x] Control only child CanvasItems/particles and keep all rule changes outside the Presenter.
- [x] Re-run the focused test and confirm PASS.

### Task 4: Basement Composition and Regression

**Files:**
- Modify: `scenes/world/basement/basement.tscn`
- Modify: `tests/run_scene_tests.gd`

**Interfaces:**
- Consumes `res://scenes/presentation/world_environment_presenter.tscn` as a direct child named `WorldEnvironmentPresenter`.

- [x] Add a scene assertion that the environment Presenter exists and owns a moon, weather tint, fog layer, and particle layer.
- [x] Run the full scene runner and confirm RED before composition.
- [x] Instance the reusable Presenter into the basement scene behind HUD layers without modifying basement gameplay script paths.
- [x] Run the full scene runner and confirm PASS.

### Task 5: Validation and Documentation

**Files:**
- Modify: `docs/开发计划文档/计划020-荒野天气与月相美术接入.md`
- Modify: `docs/开发计划文档目录.md`
- Create: `docs/任务报告/报告021-荒野天气与月相美术接入.md`

**Interfaces:**
- No public API or schema changes.

- [x] Run model tests, focused presenter test, scene tests, framework validation, editor scan, and main-scene startup.
- [x] Run `git diff --check` and inspect the scoped diff without reverting unrelated files.
- [x] Record exact commands, results, source inventory, residual visual risk, and final task state.
- [x] Mark project plan 020 complete only when every required validation passes.
