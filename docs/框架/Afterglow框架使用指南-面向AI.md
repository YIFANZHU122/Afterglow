# Afterglow 框架使用指南（面向 AI）

本文说明如何在当前 Afterglow 灰盒框架中安全新增区域、遭遇、升级、实体和表现资源。它是开发入口说明，不替代项目规范；发生冲突时以根目录 `AI项目总规范.md` 为准。

## 1. 开始任何任务前

按以下顺序读取并执行：

1. `AI项目总规范.md`
2. `AGENTS.md`
3. 与任务命中的 `docs/规范/*.md`
4. `docs/开发计划文档目录.md` 和相关计划正文
5. 目标源码、场景、资源与测试

修改前运行 `git status --short`。工作区中可能存在其他计划的未提交修改；不得使用 reset、checkout、clean 或覆盖方式处理它们。预计修改三个以上源码文件、跨两个以上模块、修改公共契约或核心规则时，必须先创建并登记开发计划。

## 2. 当前架构边界

主数据流为：

```text
输入适配器 → 类型化命令 → 领域规则 → 状态/事件 → 场景组装 → 表现
```

目录职责：

| 目录/模块 | 当前职责 | 不应承担 |
|---|---|---|
| `scripts/core/` | 本局会话和流程状态模型 | 具体敌人、武器或 UI 规则 |
| `scripts/player/` | 玩家输入命令、输入适配和体力模型 | 关卡通关与掉落规则 |
| `scripts/combat/`、`scripts/components/` | 生命、攻击资格、敌人与遭遇成员 | UI 和存档写入 |
| `scripts/world/` | 遭遇生成、目标进度和世界组装基类 | 局外成长 |
| `scripts/progression/` | 本局经验、升级构筑和复活模型 | 深层节点路径访问 |
| `scripts/items/`、`scripts/item_data.gd` | 库存模型、物品定义和掉落服务 | 推进关卡 |
| `scripts/data/` | 静态 typed Resource schema 和只读内容校验 | 运行时生命、位置、冷却或库存 |
| `scripts/presentation/`、`scenes/ui/` | 动画、反馈、HUD 和用户命令 | 决定战斗或升级是否成功 |
| `scenes/` | 节点组合、依赖注入和生命周期连接 | 集中承载全部领域计算 |

现有全局服务只有明确职责的 `GameManager` 与 `Inventory`。不要新增“万能 Autoload”，也不要直接访问它们的内部字段。

## 3. 静态内容模型

内容资源使用以下脚本：

- `scripts/data/encounter_spawn_definition.gd`
- `scripts/data/encounter_definition.gd`
- `scripts/data/area_definition.gd`
- `scripts/data/upgrade_definition.gd`
- `scripts/data/content_validation_model.gd`

`ContentValidationModel` 是只读校验器。四个公共方法均返回 `PackedStringArray`；空数组代表合法，非空数组包含错误原因：

```gdscript
validate_spawn(definition: Resource) -> PackedStringArray
validate_encounter(definition: Resource) -> PackedStringArray
validate_area(definition: Resource) -> PackedStringArray
validate_upgrade(definition: Resource) -> PackedStringArray
```

校验器会检查 Resource 挂载的脚本身份。不要用普通 `Resource`、Dictionary 或复制字段的临时对象冒充 typed Resource，也不要在运行时把生命、击杀进度或已选奖励写回 `.tres`。

## 4. 新增区域与遭遇

参考实现：`assets/areas/basement_area.tres` 与 `scenes/world/basement/basement.tscn`。

### 4.1 准备可生成实体

实体场景根节点必须能实例化为 `Node2D`。若实体计入遭遇目标，场景中必须包含：

- 名为 `HealthComponent` 的生命组件；
- 名为 `EncounterMember` 的节点；
- `EncounterMember` 必须提供 `defeated(reward_xp)` 信号语义；
- 如需要可替换美术表现，加入名为 `Presenter` 的节点并遵守 `ActorPresenter` 契约。

可参考：

- `scenes/objects/training_dummy/training_dummy.tscn`
- `scenes/objects/chaser_enemy/chaser_enemy.tscn`

`EncounterController` 会拒绝非 `Node2D` 实体或缺少 `EncounterMember` 的场景。拒绝项不会计入目标数量。

### 4.2 创建内容资源

推荐在 `assets/areas/` 创建一个外部 `.tres`，结构为：

1. 每个生成项使用 `EncounterSpawnDefinition`，设置非空 `entity_scene` 与 `spawn_position`。
2. 使用 `EncounterDefinition`，设置 `objective_text`，并将生成项放入 `spawns: Array[Resource]`。
3. 使用 `AreaDefinition`，设置唯一且非空的 `id`、非空 `display_name` 和合法 `encounter`。

不要把这些配置长期内嵌在世界 `.tscn` 中。外部资源路径是内容包的稳定身份，也便于独立验证和复用。

### 4.3 在世界场景中注入

世界场景根脚本导出 `area_config: Resource`，场景文件通过 `ExtResource` 指向区域 `.tres`。组装脚本将 `area_config.encounter` 交给：

```gdscript
EncounterController.start(encounter_definition: Resource, content_root: Node2D) -> bool
```

调用前置条件：控制器尚未启动、遭遇定义脚本正确、`content_root` 非空。成功后实体生成到 `content_root`，并通过以下信号反馈：

- `progress_changed(completed: int, target: int)`
- `reward_earned(amount: int)`
- `completed`

场景脚本可以把这些事件转交给 `GameManager` 和 HUD，但 HUD 不得自行判定目标完成。

### 4.4 登记验证资源

当前框架验证入口采用显式清单。新增正式区域后，必须在 `tests/run_framework_validation.gd` 增加资源路径并调用 `validate_area`，同时在 `tests/run_scene_tests.gd` 增加外部路径、加载和关键组装回归。

## 5. 新增局内升级

参考实现：

- `assets/upgrades/damage_upgrade.tres`
- `assets/upgrades/move_speed_upgrade.tres`

使用 `UpgradeDefinition`，必填：

- `id: StringName`：本局升级栈的稳定键，不得为空；
- `display_name: String`：展示名称，不得为空；
- `description: String`：面向玩家的说明；
- `effect_type`：当前仅支持 `DAMAGE_MULTIPLIER` 或 `MOVE_SPEED_MULTIPLIER`；
- `amount: float`：必须大于 `0.0`。

应用升级只能调用：

```gdscript
GameManager.apply_run_upgrade(definition: Resource) -> bool
```

当前前置条件为：本层目标已完成、本层尚未清除、本层尚未选择奖励、升级定义合法。成功后升级进入 `RunBuildModel`，发出 `run_build_changed`，并清除当前层。不要从按钮脚本直接改玩家伤害、速度或 GameManager 内部字段。

新增正式升级后，将资源加入 `tests/run_framework_validation.gd` 的显式清单，并为效果接入补模型和场景测试。新增新的 `effect_type` 属于公共 schema 与规则变化，必须创建开发计划，不能只改 `.tres`。

## 6. 新增或替换 Presenter

表现实现应继承 `scripts/presentation/actor_presenter.gd`，至少保持以下方法签名：

```gdscript
set_movement(direction: Vector2) -> void
play_attack(direction: Vector2) -> void
play_hit() -> void
set_dead(dead: bool) -> void
```

这些方法只负责动画、Sprite、粒子、音效或临时视觉反馈，不改变伤害、生命、死亡合法性和奖励。无正式美术时可使用 `GrayboxActorPresenter`；美术资源到位后替换 Presenter 节点或脚本，不需要重写领域规则。

调用方应依赖上述语义，不依赖 Presenter 内部 Sprite 路径、动画播放器层级或具体素材名称。

## 7. 常用公共 API

| API | 用途 | 重要拒绝条件 |
|---|---|---|
| `EncounterController.start(encounter, content_root) -> bool` | 生成一次配置化遭遇 | 重复启动、空参数、错误脚本 |
| `GameManager.apply_run_upgrade(definition) -> bool` | 应用一次本层奖励并清层 | 目标未完成、重复选择、非法升级 |
| `GameManager.is_floor_clear() -> bool` | 只读查询出口是否应解锁 | 无 |
| `GameManager.add_run_xp(amount) -> bool` | 增加本局经验；返回是否升级 | 非正数或模型未初始化 |
| `Inventory.add_item(item: ItemData) -> bool` | 将物品加入第一个空槽 | 空/非法物品或物品栏已满 |
| `Inventory.get_selected_item() -> ItemData` | 只读获取当前物品 | 空槽返回 `null` |

跨模块调用只使用公共方法、信号和 typed Resource。禁止通过深层 `get_node("../../...")`、字符串反射或直接读取 `_run_build`、`_model` 等内部字段完成业务。

## 8. AI 标准开发流程

1. 读取总规范、专项规范、相关计划和源码。
2. 运行 `git status --short`，确认并保护既有修改。
3. 判断是否必须新建开发计划；若已有计划，更新任务状态和执行记录。
4. 先写最小失败测试，运行并确认失败原因正是缺少目标行为。
5. 小步实现，不附带重构无关模块。
6. 每个增量后运行相关模型或场景测试。
7. 完成前运行全部标准验证。
8. 更新计划、索引、README（如入口变化）和 `docs/任务报告/` 标准报告。

标准验证命令（在项目根目录执行）：

```powershell
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_model_tests.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/scene_test_runner.tscn
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_framework_validation.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 3
git diff --check
```

## 9. 禁止事项

- 不把战斗、升级、通关或库存规则写进 HUD/Presenter。
- 不直接访问其他模块的私有字段或依赖未记录的深层节点路径。
- 不用无约束 Dictionary 代替长期内容 schema。
- 不把运行时状态写回共享 Resource。
- 不新增万能 Autoload、插件、依赖、网络抽象或存档字段，除非计划明确批准。
- 不复制世界场景中的内嵌区域配置；创建外部内容资源。
- 不跳过红灯测试、Godot 实际加载验证、diff 检查和任务报告。
- 不用破坏性 Git 命令处理他人的未提交修改。

字段级要求请同时查看 `docs/框架/Afterglow内容契约速查表.md`。
