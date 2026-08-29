# Afterglow 生存系统实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将已确认的生存数值与核心循环基线逐步接入 Godot 运行时，形成可测试的“资源消耗 → 时间压力 → 灾难 → 地图推进”基础闭环，并为敌人、Boss、存档和 HUD 保留稳定接口。

**Architecture:** 采用“集中静态配置 + 纯领域模型 + 运行会话组装 + 场景表现”的分层。数值和难度规则集中在 `scripts/data/`，生存值、时间和灾难调度作为不依赖节点树的 `RefCounted` 模型；`GameManager` 只负责运行会话生命周期和公开状态事件，世界场景与 HUD 后续通过明确接口消费模型状态。

**Tech Stack:** Godot 4.7.1、GDScript 2.0、现有无头模型/场景测试入口。

## Global Constraints

- 保持 `AI项目总规范.md`、相关专项规范和现有模块边界不变。
- 不新增插件、第三方依赖、网络同步或万能 Autoload。
- 运行时可变状态不得写回共享 `.tres`；静态配置与运行时状态分离。
- 核心规则先写失败测试，再写最小实现；每个增量执行 Godot 模型测试和 `git diff --check`。
- 不覆盖工作区已有的计划013、设计基线和目录修改。
- 目标发布平台、手柄、触控和默认键位未确定，本计划不修改输入映射。

## 交付阶段

1. **核心生存循环模型**：集中配置、饥饿/水分、昼夜时钟、驻留压力、难度配置和灾难调度。
2. **运行会话接入**：将模型挂接到 `GameManager`，增加开始运行、暂停冻结、地图切换和死亡/复活所需的只读状态事件。
3. **世界与资源闭环**：地图资源预算、容器/净水、篝火燃料和基础逃生物资接入现有世界场景。
4. **敌人和灾难表现**：威胁预算、感知/脱战、普通/困难灾难设施和 HUD 预警。
5. **终局、存档与随机性**：Boss 双路线、确定性随机流、安全退出快照和难度锁定。

本轮先完成第 1 阶段，并以模型测试作为独立可验收交付；后续阶段必须继续沿用本计划的接口和测试顺序。

## Task 1: 集中配置与难度规则

**Files:**
- Create: `scripts/data/survival_tuning.gd`
- Test: `tests/run_model_tests.gd`

**Interfaces:**
- `SurvivalTuning.difficulty_resource_richness(difficulty: int) -> float`
- `SurvivalTuning.disaster_slot_limit(difficulty: int) -> int`
- `SurvivalTuning.disaster_base_probability(day_index: int) -> float`
- `SurvivalTuning.overtime_probability_bonus(overtime_stage: int) -> float`

- [x] 为三档难度、昼夜、资源消耗、灾难检查和状态阈值写失败断言。
- [x] 运行 `& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_model_tests.gd`，确认测试因脚本缺失失败。
- [x] 实现只含静态常量和纯函数的 `SurvivalTuning`，不保存运行时状态。
- [x] 重新运行模型测试，确认配置边界、非法难度和超时边际递减通过。

## Task 2: 饥饿、水分与环境伤害模型

**Files:**
- Create: `scripts/player/survival_vitals_model.gd`
- Modify: `tests/run_model_tests.gd`

**Interfaces:**
- `SurvivalVitalsModel.tick(delta: float, consumption_multiplier: float = 1.0) -> float`
- `SurvivalVitalsModel.consume_food(amount: float) -> bool`
- `SurvivalVitalsModel.consume_water(amount: float) -> bool`
- `SurvivalVitalsModel.get_hunger() -> float`
- `SurvivalVitalsModel.get_water() -> float`
- `SurvivalVitalsModel.is_critical() -> bool`

- [x] 先覆盖初始值、连续小数消耗、低于 0 截断、负数补给拒绝、0 值警告和 1%/秒伤害上限。
- [x] 运行模型测试确认新测试按预期失败。
- [x] 实现 0–100 状态值、5 秒归零警告、独立食物/水分补给和双归零伤害总上限。
- [x] 运行模型测试并检查负 delta、重复补给和死亡前边界。

## Task 3: 昼夜时钟与驻留压力

**Files:**
- Create: `scripts/world/survival_clock_model.gd`
- Modify: `tests/run_model_tests.gd`

**Interfaces:**
- `SurvivalClockModel.advance(delta: float) -> bool`
- `SurvivalClockModel.get_elapsed_seconds() -> float`
- `SurvivalClockModel.get_day_index() -> int`
- `SurvivalClockModel.is_night() -> bool`
- `SurvivalClockModel.get_overtime_stage() -> int`
- `SurvivalClockModel.get_overtime_probability_bonus() -> float`

- [x] 覆盖白天/夜晚边界、第三昼夜、54 分钟正常窗口和超时边际递减。
- [x] 运行模型测试确认边界测试先失败。
- [x] 实现不依赖 `Timer` 或场景节点的纯时钟模型。
- [x] 运行模型测试并验证负 delta 与大步长推进。

## Task 4: 灾难调度模型

**Files:**
- Create: `scripts/world/disaster_scheduler_model.gd`
- Modify: `tests/run_model_tests.gd`

**Interfaces:**
- `DisasterSchedulerModel.should_check(delta: float) -> bool`
- `DisasterSchedulerModel.get_trigger_probability(elapsed_seconds: float) -> float`
- `DisasterSchedulerModel.roll_trigger(rng: RandomNumberGenerator, elapsed_seconds: float, active_count: int) -> bool`
- `DisasterSchedulerModel.roll_disaster_kind(rng: RandomNumberGenerator, elapsed_seconds: float, is_night: bool) -> int`
- `DisasterSchedulerModel.register_trigger(kind: int, elapsed_seconds: float) -> bool`

- [x] 覆盖每 60 秒检查、槽位已满跳过、触发后概率回落、同类冷却、第一天不出困难灾难和昼夜权重。
- [x] 运行模型测试确认测试先失败。
- [x] 实现显式概率曲线、困难灾难权重表、同类冷却和命名事件枚举。
- [x] 运行模型测试并使用固定 RNG 验证结果可复现。

## Task 5: 运行会话接入与暂停边界

**Files:**
- Modify: `scripts/autoload/game_manager.gd`
- Modify: `scripts/core/run_session_model.gd`
- Modify: `tests/run_model_tests.gd`

**Interfaces:**
- `GameManager.tick_survival(delta: float) -> float`
- `GameManager.pause_run() -> bool`
- `GameManager.resume_run() -> bool`
- `GameManager.get_hunger() -> float`
- `GameManager.get_water() -> float`
- `GameManager.get_floor_elapsed_seconds() -> float`

- [x] 先为开始运行、暂停冻结、死亡/复活和地图切换写模型/场景回归断言。
- [x] 接入模型并发出只读状态事件，不让 UI 直接修改领域状态。
- [x] 运行全部模型测试、场景测试、框架验证和编辑器无头检查。

## Task 6: 世界资源、篝火和基础逃生物资

> 2026-08-27：计划017已完成资源预算、逃生物资目标、地下室任务拾取和出口启动闭环。篝火燃料与净水运行时仍按计划017边界拆分到后续计划，不视为本任务已实现。

**Files:**
- Modify: `scripts/world/world_scene_controller.gd`
- Modify: `scripts/world/objective_progress_model.gd`
- Create/Modify: `scripts/world/resource_budget_model.gd`
- Modify: `tests/run_model_tests.gd`
- Modify: relevant world scenes/resources under `scenes/world/` and `assets/areas/`

**Interfaces:**
- `ResourceBudgetModel.get_guaranteed_food() -> int`
- `ResourceBudgetModel.get_guaranteed_water() -> int`
- `ObjectiveProgressModel` escape-material progress methods

- [x] 以无固定开局补给、地图资源预算和 6 分钟普通食物保底为模型/场景测试前置；容器、水源和正式地图生成保留后续接入。
- [x] 接入难度资源丰富度和出口物资任务栏；篝火燃料、容器容量与净水耗时按计划017边界拆分。
- [x] 运行模型、场景和框架验证，确认任务物资不进入背包且出口启动不依赖单一工具耐久。

## Task 7: 灾难、敌人感知与 HUD 反馈

**Files:**
- Modify: `scripts/world/encounter_controller.gd`
- Modify: `scripts/combat/chaser_enemy.gd`
- Create: `scripts/combat/enemy_perception_model.gd`
- Create: `scripts/world/disaster_event_model.gd`
- Modify: relevant HUD/UI scenes and tests

- [x] 先覆盖威胁预算、刷新保护区、听声调查、15 秒脱战和灾难预警事件。
- [x] 接入普通/困难灾难目录、唯一主应对设施和并发可解性验证。
- [x] 运行模型、场景和可视反馈验证。

## Task 8: Boss、存档随机性与难度锁定

**Files:**
- Modify: `scripts/core/run_session_model.gd`
- Create: `scripts/core/run_random_stream_model.gd`
- Create: `scripts/core/run_save_model.gd`
- Create: `scripts/combat/boss_progress_model.gd`
- Modify: `scripts/autoload/game_manager.gd`
- Modify: tests and final-map scenes/resources

- [x] 先覆盖 Boss 战斗/资源环境双路线、难度锁定、随机流位置和最终死亡存档失效。
- [x] 接入地图种子派生、原子存档和安全退出快照。
- [x] 运行全部标准验证命令，并记录未实现的正式表现内容。

## 验证命令

所有任务完成前至少运行：

```powershell
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_model_tests.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/scene_test_runner.tscn
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_framework_validation.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 3
git diff --check
```

## Self-review

- 所有首版数值都引用 `survival_tuning.gd` 或设计基线，不在场景脚本复制魔法数字。
- Task 1–4 可独立作为纯模型交付；Task 5 之后才接入 Autoload 和场景。
- Boss、存档和输入平台边界明确列入后续任务，没有把未确认的平台假设写入实现。
