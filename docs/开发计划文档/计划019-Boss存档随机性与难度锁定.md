# 计划019：Boss、存档随机性与难度锁定

## 1. 基本信息

- 状态：已完成
- 创建日期：2026-08-27
- 完成日期：2026-08-27
- 任务分类：Boss 核心规则、运行会话、确定性随机、存档、最终地图跨模块功能
- 总设计：`docs/superpowers/specs/2026-08-27-survival-tuning-baseline-design.md`
- 总实施计划：`docs/superpowers/plans/2026-08-27-survival-systems-implementation-plan.md`

## 2. 目标

完成首版整局终局闭环：第 6 张地图由 Boss 核心封锁出口，玩家可以选择三阶段战斗路线或收集 3 个抑制组件并依次启动环境装置；运行难度在开局后锁定；同一运行种子能够复现并恢复各命名随机流；安全退出使用带版本校验的原子快照；最终死亡会使本局存档失效并清理局内状态，同时保留局外结晶。

## 3. 范围

### 包含

- `RunSessionModel` 持有难度、总楼层数和难度锁定状态；第 6 层作为默认最终层，最终层不能继续进入下一层。
- `RunRandomStreamModel` 持有运行种子、地图种子和地形、资源、天气、灾难、容器、敌人生成、掉落七条独立随机流；保存 RNG 状态和事件编号。
- `BossProgressModel` 支持战斗/资源环境两条可混合推进但互斥结算的路线；战斗路线固定 3 阶段并禁止高伤害跳阶段，环境路线固定 3 个抑制组件和 3 台顺序装置。
- `RunSnapshotData` 定义安全退出快照的固定 schema；运行状态、随机流、生存、Boss、逃生目标、灾难、玩家、敌人、物品、建筑和交互进度分区保存。
- `RunSaveModel` 使用临时文件写入和替换，校验版本与结算标识；主快照损坏时允许回退到最近完成楼层边界快照；最终死亡可使本局快照失效。
- `GameManager` 组合上述模型，提供运行种子、Boss 命令、存档/恢复、胜利/最终失败和局外结晶只读接口。
- 新增最终核心区灰盒场景、Boss 实体、抑制组件、环境装置、HUD 和出口接线，并登记框架/场景验证。

### 不包含

- 正式 Boss 美术、完整动画、音效、复杂技能树、导航网格和正式地图生成器。
- 云存档、跨设备同步、网络同步、加密防篡改和旧版存档迁移；首版存档版本为 `1`，不兼容版本明确拒绝。
- 局外成长商店和配方解锁 UI；本轮只建立“局外结晶不随本局最终死亡清空”的数据边界。
- 新插件、第三方依赖、输入映射或新增 Autoload。

## 4. 设计决定

- 难度由 `RunSessionModel` 持有并在 `start_run` 成功后锁定，`GameManager` 不再维护第二份可漂移的锁定状态。
- 随机流使用固定名称和固定盐值，不使用调用顺序相关的共享 RNG；地图种子由运行种子与楼层序号确定性派生。
- 每次随机调用都推进对应流的事件编号；读档恢复 RNG 内部状态和事件编号，因此重载不会重抽天气、灾难、生成或掉落。
- Boss 战斗阶段生命阈值为 `300 -> 200 -> 100 -> 0`。伤害在阶段边界钳制，调用 `acknowledge_phase_transition()` 后才能进入下一阶段。
- 环境路线要求收集索引 `0/1/2` 的三个组件，并按 `0 -> 1 -> 2` 启动装置；组件放入任务状态，不进入背包或负重。
- 任一路线先完成即锁定 `completion_route`；另一条路线和重复奖励领取均被拒绝。Boss 完成后只解除最终出口，不自动重复结算。
- 安全退出快照与楼层边界快照使用不同文件；主快照解析、版本、结算标识或 schema 校验失败时读取边界快照。
- 最终失败先写入失效标识，再清理局内 XP、强化、背包、逃生目标、Boss 和灾难；局外结晶属于独立状态，不进入本局快照清理集合。

## 5. 公共接口

### RunSessionModel

- `configure_difficulty(difficulty: int) -> bool`
- `start_run(difficulty: int = -1, total_floors: int = 6) -> bool`
- `start_next_floor() -> bool`
- `complete_run() -> bool`
- `get_difficulty() -> int`
- `is_difficulty_locked() -> bool`
- `get_total_floors() -> int`
- `is_final_floor() -> bool`
- `create_snapshot() -> Dictionary`
- `restore_snapshot(snapshot: Dictionary) -> bool`

### RunRandomStreamModel

- `start(run_seed: int, floor_number: int = 1) -> bool`
- `begin_floor(floor_number: int) -> bool`
- `randi_range(stream_name: StringName, from: int, to: int) -> int`
- `randf(stream_name: StringName) -> float`
- `get_run_seed() -> int`
- `get_map_seed() -> int`
- `get_event_index(stream_name: StringName) -> int`
- `create_snapshot() -> Dictionary`
- `restore_snapshot(snapshot: Dictionary) -> bool`

### BossProgressModel

- `apply_combat_damage(amount: float) -> bool`
- `acknowledge_phase_transition() -> bool`
- `collect_suppression_component(component_index: int) -> bool`
- `activate_environment_device(device_index: int) -> bool`
- `claim_completion_route() -> int`
- `get_phase() -> int`
- `get_health() -> float`
- `get_completion_route() -> int`
- `create_snapshot() -> Dictionary`
- `restore_snapshot(snapshot: Dictionary) -> bool`

### RunSaveModel / RunSnapshotData

- `save_safe_exit(snapshot: RunSnapshotData) -> bool`
- `save_floor_boundary(snapshot: RunSnapshotData) -> bool`
- `load_latest() -> RunSnapshotData`
- `invalidate_run(settlement_id: String) -> bool`
- `has_valid_run() -> bool`
- `RunSnapshotData.to_dictionary() -> Dictionary`
- `RunSnapshotData.from_dictionary(data: Dictionary) -> bool`

### GameManager

- Boss 进度命令、查询和 `boss_progress_changed` 信号。
- 运行种子、地图种子、随机流取值和事件编号只读/命令接口。
- `save_safe_exit(snapshot: RunSnapshotData = null) -> bool`、`restore_safe_exit() -> bool`、`save_floor_boundary() -> bool`。
- `complete_run() -> bool`、`finalize_run_failure() -> bool`。
- `add_meta_crystals(amount: int) -> bool`、`get_meta_crystals() -> int`；重置或最终失败不清除此值。

## 6. TDD 与任务拆分

- [x] Task 1：为难度锁定、总楼层边界和会话快照写失败测试，确认红灯后实现。
- [x] Task 2：为命名随机流复现、跨流隔离、地图种子和随机位置恢复写失败测试，确认红灯后实现。
- [x] Task 3：为 Boss 三阶段战斗、环境顺序路线、混合推进和单次结算写失败测试，确认红灯后实现。
- [x] Task 4：为存档 schema、原子替换、损坏回退和失效标识写失败测试，确认红灯后实现。
- [x] Task 5：接入 GameManager，会话恢复、最终失败清理与局外结晶保留均先写场景/集成红灯。
- [x] Task 6：新增最终核心区场景、Boss 与环境设施，接入 HUD、出口和资源验证。
- [x] Task 7：运行全部标准验证，补任务报告并更新总实施计划。

## 7. 验收标准

- [x] 普通、困难、地狱难度只能在空闲会话选择，开始运行后到结束前不可修改，读档后仍保持锁定。
- [x] 默认运行共有 6 层；第 6 层不能进入下一层，只能在 Boss 完成并清层后完成整局。
- [x] 相同运行种子和楼层得到相同地图种子；相同随机流快照恢复后得到相同后续结果；其他流的调用不改变目标流结果。
- [x] Boss 战斗路线必须经历三个阶段；环境路线必须收集并顺序启动三个装置；任一路线完成后奖励只可领取一次。
- [x] 安全退出快照保存固定 schema 的全部状态分区；损坏主快照回退楼层边界；不兼容版本和已结算快照拒绝恢复。
- [x] 最终死亡使本局存档不可恢复，并清空本局 XP、强化、背包、任务状态、Boss 与灾难；局外结晶保持不变。
- [x] 最终核心区可以通过战斗或环境路线解除出口封锁并完成整局。
- [x] 模型、场景、框架、编辑器、主场景和 `git diff --check` 全部通过。

## 8. 风险与回滚

| 风险 | 缓解 | 回滚 |
|---|---|---|
| 存档字段扩散到各模块内部 | 由 `RunSnapshotData` 固定分区，模型只暴露显式快照方法 | 暂停运行时恢复，只保留 `RunSaveModel` 文件往返与边界快照 |
| GameManager 职责继续膨胀 | Boss 规则、随机规则和文件规则分别留在纯模型，GameManager 只编排 | 保留纯模型，撤回场景接入接口 |
| 最终地图复用现有出口导致普通楼层推进回归 | 最终出口使用独立 `completes_run` 语义并补场景回归 | 禁用最终出口交互，保留 Boss 目标模型 |
| 原子替换在 Windows 文件占用时失败 | 临时文件、备份和失败恢复均返回显式 `false`，不覆盖现有有效快照 | 保留旧主快照并删除临时文件 |

## 9. 执行记录

- 2026-08-27：计划创建并登记。沿用已确认的第 6 图 Boss 双路线、三档难度整局锁定、命名随机流和安全退出存档方案；首版使用灰盒表现，不引入新依赖或 Autoload。
- 2026-08-27：按 TDD 完成会话边界、确定性随机、Boss 双路线、固定 schema 存档和原子回退模型；GameManager 接入运行种子、Boss 命令、胜利/失败结算、安全退出恢复和局外结晶保留。
- 2026-08-27：新增 `FinalCore` 灰盒终局场景、Boss 核心、三个抑制组件、三个环境装置、Boss HUD 和最终出口，并通过场景回归。

## 10. 验证结果

- 模型测试：通过，输出 `Model tests passed`。
- 场景测试：通过，输出 `Scene tests passed`。
- 框架资源验证：通过，输出 `Framework validation passed`。
- Godot 编辑器无头扫描：通过，退出码 0。
- 主场景无头启动：通过，退出码 0。
- `git diff --check`：通过，无输出。

## 11. 完成结论

- 已完成。Task 8 建立了完整的终局规则、确定性随机和安全存档边界；正式 Boss 美术、正式随机地图/导航、复杂技能表现和局外成长 UI 仍属于后续内容阶段。
