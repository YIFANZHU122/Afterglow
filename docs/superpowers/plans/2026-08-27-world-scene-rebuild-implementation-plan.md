# 区域重建与多地图快照恢复实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让楼层边界自动存档和安全退出恢复能够定位、加载并重建正确的地图场景。

**Architecture:** `WorldSceneCatalog` 作为纯数据模型提供楼层到场景的双向校验。GameManager 只编排位置元数据、边界存档和恢复切场景；WorldSceneController 负责注册场景并在动态实体组装完成后应用待恢复状态。

**Tech Stack:** Godot 4.7.1、GDScript、现有 `RunSnapshotData`/`RunSaveModel` 和无头测试场景。

## Global Constraints

- 不修改 `RunSnapshotData` 顶层 11 个分区和 schema 版本 1。
- 不新增插件、依赖、输入映射、网络同步或万能 Autoload。
- 保持规则、场景节点和表现层解耦；场景路径只由 `WorldSceneCatalog` 校验。
- 每个生产变更先有失败测试，再实现最小通过代码。

### Task 1: 场景目录模型

**Files:**
- Create: `scripts/world/world_scene_catalog.gd`
- Test: `tests/world_scene_catalog_test.gd`
- Test: `tests/world_scene_catalog_test.tscn`

**Interfaces:**
- `get_scene_id(floor_number: int) -> StringName`
- `get_scene_path(floor_number: int) -> String`
- `get_default_spawn_point(floor_number: int) -> StringName`
- `is_valid_location(floor_number: int, scene_id: StringName, scene_path: String) -> bool`

- [ ] 写失败测试：有效楼层映射、非法楼层拒绝、错误路径/id 拒绝。
- [ ] 运行 `Godot_v4.7.1-stable_win64_console.exe --headless --path . tests/world_scene_catalog_test.tscn`，确认因脚本缺失红灯。
- [ ] 实现固定灰盒目录和严格校验。
- [ ] 重跑测试，确认输出 `World scene catalog test passed`。

### Task 2: 运行快照位置元数据与边界自动保存

**Files:**
- Modify: `scripts/autoload/game_manager.gd`
- Modify: `scripts/world/world_scene_controller.gd`
- Modify: `scripts/core/run_snapshot_data.gd`（仅补充文档注释，不改 schema）
- Test: `tests/run_save_integration_test.gd`

**Interfaces:**
- `GameManager.restore_safe_exit_to_scene() -> bool`
- `GameManager.get_resume_scene_path() -> String`
- `GameManager.get_resume_scene_id() -> StringName`
- `GameManager.get_resume_spawn_point_name() -> StringName`
- `GameManager.depart_floor() -> bool` 保持签名，内部自动写边界快照。

- [ ] 写失败测试：第二层位置元数据进入快照、`depart_floor()` 自动写边界、恢复后返回正确路径。
- [ ] 运行集成测试确认红灯。
- [ ] 实现场景注册、位置元数据写入、目录校验和恢复切场景入口。
- [ ] 在离层推进前自动保存边界，失败时保持原状态。
- [ ] 重跑集成测试，确认跨地图恢复和后续随机流一致。

### Task 3: 场景加载与实体回填

**Files:**
- Modify: `scripts/world/world_scene_controller.gd`
- Modify: `scenes/world/basement/basement.gd`
- Modify: `scenes/world/final_core/final_core.gd`
- Test: `tests/run_save_integration_test.gd`

- [ ] 写失败测试：错误场景不消费 pending 状态，正确场景 deferred 后回填玩家/敌人/交互。
- [ ] 实现位置匹配保护和 deferred 回填。
- [ ] 验证地下室、慈航郊外和终局核心场景均能注册目录位置。

### Task 4: 边界与回归验收

**Files:**
- Modify: `docs/开发计划文档/计划022-区域重建与多地图快照恢复.md`
- Modify: `docs/开发计划文档目录.md`
- Create: `docs/任务报告/报告024-区域重建与多地图快照恢复.md`

- [ ] 覆盖空存档、损坏存档、非法位置、重复恢复、边界保存失败和结算后不可恢复。
- [ ] 运行模型、场景、存档集成、框架、编辑器、主场景和 `git diff --check`。
- [ ] 更新计划状态、任务报告和交接记录。
