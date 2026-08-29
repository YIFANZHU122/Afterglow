# Afterglow 框架优先灰盒垂直切片设计

## 1. 背景与目标

Afterglow 已确定为 Godot 4.7.1、2D 俯视角、实时动作战斗、生存 Roguelite。单局结构确定包含开始、探索战斗、局内构筑、区域完成、死亡或通关结算、重新开局；爬塔形式和正式美术方向尚未确定。

当前阶段的目标不是建设通用 2D 引擎，而是形成一套始终可玩的灰盒游戏骨架。未来玩法内容和美术资源到位后，应主要通过新增 Resource、替换 Presentation 子场景、调整挂点与碰撞来扩充，不重写生命、伤害、奖励、目标和本局状态逻辑。

## 2. 已确认的设计决策

### 2.1 固定边界

- 实时移动、主动攻击、受伤、死亡和敌人行为属于稳定核心。
- 本局开始、战斗探索、局内强化、死亡或结算、重新开局属于稳定核心。
- 输入只能产生命令，玩法规则产生状态和事件，表现层消费事件。
- 每个阶段必须交付可实际游玩的垂直切片，不能只铺设未接通的系统骨架。

### 2.2 可替换边界

- “楼层”不作为长期领域概念，长期统一使用“区域 Area”。区域可表现为楼层、房间、路线节点、开放地图分区或战斗波次。
- 武器数量、技能组合、敌人种类、地图拓扑、正式 HUD、美术风格和局外成长规则不在当前阶段固化。
- 正式美术通过 Presentation 子场景接入，不成为生命、伤害、奖励或目标判定的唯一依据。

### 2.3 选择灰盒垂直切片方案

不采用一次性建设所有系统的“大框架”，也不继续扩大硬编码原型。每个框架能力都通过当前地下室场景证明：配置可替换、流程可玩、测试可重复、美术可后接。

## 3. 总体架构

数据流固定为：

```text
输入适配器 → 类型化命令 → 领域模型/组件 → 状态变化与事件 → 场景组装 → Presentation/HUD
```

模块职责：

- `core`：本局生命周期、区域序号和跨场景状态，不实现具体敌人或 UI。
- `player`：玩家命令、移动、体力和角色能力，不推进区域目标。
- `combat`：攻击、伤害、敌人行为和遭遇成员契约，不写 HUD。
- `world`：区域定义、遭遇生成、目标进度和区域完成。
- `progression`：XP、局内强化选择和本局属性修正。
- `items`：物品和武器定义，不直接修改区域状态。
- `presentation`：动画、闪烁、特效、音效和 HUD，只消费语义事件。
- `scenes`：实例化实体、注入 Resource、连接模块，不保存共享配置的运行状态。

## 4. 第一阶段内容数据

第一阶段只引入当前垂直切片真正需要的 Resource。

### 4.1 EncounterSpawnDefinition

字段：

- `entity_scene: PackedScene`：要生成的完整灰盒实体场景。
- `spawn_position: Vector2`：相对于区域内容根节点的位置。

拒绝空场景。第一阶段不实现权重、波次和随机生成，避免在玩法未确定时过度设计。

### 4.2 EncounterDefinition

字段：

- `objective_text: String`：灰盒 HUD 的目标描述。
- `spawns: Array[EncounterSpawnDefinition]`：本区域生成项。

目标数量由有效生成项数量得出，不在另一个字段重复保存。

### 4.3 AreaDefinition

字段：

- `id: StringName`：稳定内容标识。
- `display_name: String`：HUD 使用的区域名称。
- `encounter: EncounterDefinition`：当前区域遭遇。

第一阶段继续使用现有场景切换路径，区域路线策略留到后续独立计划，避免同时重写流程状态机。

### 4.4 UpgradeDefinition

字段：

- `id: StringName`
- `display_name: String`
- `description: String`
- `effect_type: enum`，第一阶段只包含 `DAMAGE_MULTIPLIER` 和 `MOVE_SPEED_MULTIPLIER`。
- `amount: float`，表示加法修正值，例如 `0.2` 表示增加 20%。

不提前实现复杂效果脚本、任意 Dictionary 或技能树。

## 5. 区域遭遇契约

### 5.1 EncounterMember

每个参与区域目标的敌人场景必须包含名为 `EncounterMember` 的组件。组件监听同一实体的 `HealthComponent.died`，只发送一次：

```text
defeated(reward_xp: int)
```

奖励数值由组件配置。敌人行为脚本不再各自重复实现奖励事件。地图和遭遇控制器只认识 EncounterMember，不读取敌人内部 AI 字段。

### 5.2 EncounterController

职责：

- 接收 `EncounterDefinition` 和内容根节点。
- 清理自己上一轮生成的实体。
- 实例化有效生成项并连接 EncounterMember。
- 使用 `ObjectiveProgressModel` 记录完成数量。
- 发出 `progress_changed(completed, target)`、`reward_earned(amount)` 和 `completed`。

空遭遇应立即完成；空实体场景应被忽略并给出警告；重复死亡事件不能重复发奖。

区域场景负责把奖励转交 GameManager、把完成事件转交本局状态，并更新 HUD。

## 6. 局内构筑与奖励选择

### 6.1 RunBuildModel

本局构筑模型只保存运行时修正：

- 伤害倍率，初始为 `1.0`。
- 移动速度倍率，初始为 `1.0`。
- 已选择升级 ID 及层数。

规则：空 ID、非正修正值和未知效果被拒绝；同一升级可以叠加；重置恢复默认倍率并清空层数。

### 6.2 GameManager 接口

GameManager 持有 RunBuildModel，提供：

- `apply_run_upgrade(definition: UpgradeDefinition) -> bool`
- `get_run_damage_multiplier() -> float`
- `get_run_move_speed_multiplier() -> float`
- `get_run_upgrade_stack(id: StringName) -> int`
- `is_floor_clear() -> bool`，作为现有状态机的兼容查询；长期区域命名迁移另立计划。

新局和显式重置必须清除本局构筑。玩家只读取倍率，不直接修改模型。

### 6.3 奖励选择流程

区域目标完成后：

1. 本局进入现有 `OBJECTIVE_COMPLETE` 状态。
2. 灰盒奖励面板展示两项由场景注入的 UpgradeDefinition。
3. 玩家选择一项后调用 GameManager 应用升级。
4. 成功应用后调用 `clear_floor()`，进入现有 `FLOOR_CLEAR` 状态。
5. 出口只允许 `FLOOR_CLEAR` 状态进入，并开始下一区域准备。

该流程先复用现有状态名，避免在同一阶段同时迁移所有公共状态接口。UI 重复点击、空定义或非法状态不会重复应用奖励。

## 7. 表现替换边界

第一阶段建立最小 ActorPresenter 语义接口：

- `set_movement(direction: Vector2)`
- `play_attack(direction: Vector2)`
- `play_hit()`
- `set_dead(dead: bool)`

玩家和追击敌人的可见节点移入各自 Presentation 子场景。逻辑脚本只调用上述语义方法，不读取具体动画帧或 Polygon2D。正式美术可用新的 Presentation 场景替换灰盒场景，并保留稳定的实体根、碰撞、HealthComponent、AttackOrigin 和 EffectAnchor。

如果正式资源使用不同动画体系，只需更换 Presenter 实现；战斗规则不调用具体动画名。

## 8. 场景模板

### 8.1 角色实体

```text
ActorEntity
├── CollisionShape2D
├── HealthComponent
├── EncounterMember（敌人需要）
├── Presentation
├── AttackOrigin
├── EffectAnchor
└── UIAnchor
```

### 8.2 区域场景

```text
AreaScene
├── Environment
├── Walls/Navigation
├── PlayerSpawnPoints
├── Player
├── ContentRoot
├── EncounterController
├── TransitionZone
└── AreaHUD
```

地图正式美术只替换 Environment、墙体表现、装饰、光照和环境特效；ContentRoot 中的敌人由遭遇配置生成。

## 9. 错误处理

- Resource 缺失时拒绝启动对应内容并输出带资源/节点上下文的警告，不使用无约束 Dictionary 兜底。
- EncounterController 忽略空 PackedScene，但有效目标数量只统计成功生成且带 EncounterMember 的实体。
- 奖励面板只有在 OBJECTIVE_COMPLETE 时可提交；成功提交后立即禁用全部按钮。
- Presentation 缺失时玩法逻辑仍可运行，输出警告而不是中断战斗。
- 当前无存档 schema 变更，不把 Resource 或运行时 Node 直接写入存档。

## 10. 测试策略

### 10.1 模型测试

- RunBuildModel：默认值、合法升级、重复叠加、空 ID、非正数、未知效果、重置和重复重置。
- EncounterDefinition：空生成项和有效生成项计数。

### 10.2 场景测试

- 地下室从 AreaDefinition 生成两个目标实体。
- 玩家真实攻击输入能伤害生成后的敌人。
- 敌人真实接近能伤害玩家。
- 每个敌人死亡只发放一次奖励，目标最终为 `2/2`。
- 目标完成后出口仍锁定，奖励面板出现。
- 选择伤害强化后倍率变化、面板关闭、区域进入 FLOOR_CLEAR、出口解锁。
- 新局重置清除倍率和升级层数。
- Player 和 ChaserEnemy 在 Presentation 可替换后仍可加载和完成战斗链。

### 10.3 完成验证

- 模型测试。
- 场景回归测试。
- Godot 编辑器无头扫描。
- 主场景无头冷启动。
- `git diff --check`。
- 可见游戏窗口冷启动，确认 HUD、奖励按钮、伤害和出口流程。

## 11. 分阶段路线

### 阶段一：计划010——框架优先灰盒垂直切片

完成本设计第 4 至第 10 节：数据驱动遭遇、局内奖励选择、最小 Presenter 边界和完整场景回归。

### 阶段二：武器与攻击模式内容化

在已有近战闭环稳定后，引入 AttackDefinition、ProjectileDefinition、冷却和攻击模式执行器；每次只增加一个经过完整场景验证的攻击模式。

### 阶段三：区域序列策略

将现有 floor 命名迁移为 area，并实现线性、分支路线或波次策略中的一种。具体选择在地图玩法明确后决定，不在阶段一预埋多套实现。

### 阶段四：正式美术接入工具与规范

根据最终美术类型确定像素密度、方向数量、导入预设、动画命名、材质和资源校验工具。当前只保证 Presenter 契约，不猜测最终美术规格。

### 阶段五：局外成长与存档

在局外成长规则明确后单独设计存档 schema、版本迁移和局内/局外数据边界；阶段一不写临时存档格式。

## 12. 非目标

- 程序化地图、导航网格重构、复杂 AI 状态树。
- 完整武器库、技能树、状态效果系统和局外成长。
- 正式美术、正式音效、完整设置菜单和发布平台适配。
- 网络同步或为未来联机新增当前无用途的抽象。

## 13. 回滚条件

- Resource 化导致当前地下室无法稳定冷启动时，先保留原预放置实体并回滚遭遇生成，不影响其他模块。
- Presenter 迁移无法保持玩家和敌人行为一致时，单独回滚 Presentation 子场景迁移，保留数据和奖励模型。
- 奖励选择改变区域状态导致现有场景切换不稳定时，恢复出口触发清层的旧流程，保留 RunBuildModel，另立状态迁移计划。
