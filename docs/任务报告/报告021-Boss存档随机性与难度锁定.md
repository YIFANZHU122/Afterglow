# 报告021：Boss、存档随机性与难度锁定

## 1. 任务分类与计划

- 任务类型：跨模块核心循环功能、Boss、运行会话、确定性随机、本地存档和终局场景
- 开发计划：[计划019-Boss存档随机性与难度锁定.md](../开发计划文档/计划019-Boss存档随机性与难度锁定.md)
- 总实施计划：[2026-08-27-survival-systems-implementation-plan.md](../superpowers/plans/2026-08-27-survival-systems-implementation-plan.md)
- 设计基线：[2026-08-27-survival-tuning-baseline-design.md](../superpowers/specs/2026-08-27-survival-tuning-baseline-design.md)
- 最终状态：已完成

## 2. 完成内容

- `RunSessionModel` 增加三档难度锁定、默认六层、最终层边界、整局胜利状态和严格快照恢复。
- `RunRandomStreamModel` 增加运行种子、地图种子和七条独立命名随机流；随机流保存 RNG 状态与事件编号，恢复后继续相同后续序列。
- `BossProgressModel` 增加 `300/200/100/0` 三阶段战斗路线、阶段确认门槛、三个抑制组件顺序装置、混合推进和单次结算互斥。
- `RunSnapshotData` 与 `RunSaveModel` 建立版本为 1 的固定分区 schema、临时文件原子替换、主快照损坏回退楼层边界和最终失效标识。
- `GameManager` 接入 Boss 命令/信号、运行/地图种子、命名随机读取、安全退出保存/恢复、胜利/最终失败清理和局外结晶保留。
- 新增 `FinalCore` 灰盒终局场景、Boss 核心、三个抑制组件、三个环境装置、Boss HUD 和最终出口。
- 奖励模型、强化模型、生存值、时钟、逃生目标、灾难调度/实例、威胁预算和库存均提供快照往返接口。

## 3. 修改与新增文件

新增主要文件：

- `scripts/core/run_random_stream_model.gd`
- `scripts/core/run_snapshot_data.gd`
- `scripts/core/run_save_model.gd`
- `scripts/combat/boss_progress_model.gd`
- `scripts/combat/boss_core.gd`
- `scenes/world/final_core/final_core.gd`
- `scenes/world/final_core/final_core.tscn`
- `scenes/objects/suppression_component/*`
- `scenes/objects/environment_device/*`
- `scenes/objects/final_exit/*`

修改主要文件：

- `scripts/core/run_session_model.gd`
- `scripts/autoload/game_manager.gd`
- `scripts/progression/run_reward_model.gd`
- `scripts/progression/run_build_model.gd`
- `scripts/player/survival_vitals_model.gd`
- `scripts/world/survival_clock_model.gd`
- `scripts/world/disaster_scheduler_model.gd`
- `scripts/world/disaster_event_model.gd`
- `scripts/world/threat_budget_model.gd`
- `scripts/world/escape_objective_model.gd`
- `scripts/items/inventory_model.gd`
- `scripts/autoload/inventory.gd`
- `tests/run_model_tests.gd`
- `tests/run_scene_tests.gd`
- `docs/开发计划文档目录.md`
- `docs/superpowers/plans/2026-08-27-survival-systems-implementation-plan.md`

## 4. 接口与数据变化

- 新增会话、随机流、Boss、快照和存档公共接口，详细契约见计划019第 5 节。
- `GameManager.start_run` 扩展为 `start_run(difficulty: int = -1, run_seed: int = 20260827, total_floors: int = 6)`；旧的单参数和无参数调用保持兼容。
- `RunSnapshotData` 顶层固定保存 11 个状态分区，schema 版本固定为 1；不兼容版本、损坏数据、失效标识均拒绝恢复。
- 未新增插件、第三方依赖、输入映射或 Autoload；`GameManager` 继续作为既有全局会话服务。

## 5. TDD 与调试记录

- 先加入会话、随机流、Boss、存档和集成场景失败断言，分别确认缺少接口/脚本导致红灯。
- 按垂直切片实现并逐轮转绿：会话边界 -> 随机流 -> Boss -> 存档 -> GameManager -> FinalCore 场景。
- 复核时补上活动会话快照不能解除难度锁定、Boss 只能在最终层探索状态领取、损坏 JSON 不输出预期错误堆栈等边界。

## 6. 测试与验证

工作目录：`C:\work\project020-Afterglow\src\Afterglow`

| 项目 | 命令 | 结果 |
|---|---|---|
| 模型测试 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_model_tests.gd` | 通过，`Model tests passed` |
| 场景回归 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/scene_test_runner.tscn` | 通过，`Scene tests passed` |
| 框架资源验证 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_framework_validation.gd` | 通过，`Framework validation passed` |
| 编辑器扫描 | `Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --quit` | 通过，退出码 0 |
| 主场景启动 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . --quit-after 3` | 通过，退出码 0 |
| 差异检查 | `git diff --check` | 通过，无输出 |

## 7. 风险与遗留问题

- `FinalCore` 当前是可验证的灰盒终局场景，尚未接入正式 Boss 美术、动画、音效、技能反馈和正式地图导航。
- 安全退出快照已经覆盖核心纯模型和库存；玩家节点位置、敌人节点实例、建筑实体和场景交互的正式序列化仍由后续随机地图/实体持久化阶段继续扩展。
- 运行种子已驱动命名随机流和灾难抽取；正式地图生成器尚未使用全部随机流生成地形和容器。
- 局外结晶当前在运行会话内保持，尚未建立独立的长期用户存档文件和成长 UI。

## 8. 结论

计划019已完成。Afterglow 现在具备可测试的六层终局边界、Boss 双路线、难度锁定、确定性随机流、安全退出/回退存档和最终失败失效机制；后续可进入正式随机地图与 Boss 表现内容阶段。
