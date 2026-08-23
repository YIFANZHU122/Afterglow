# Afterglow 内容契约速查表

本表用于快速创建和检查灰盒内容。完整工作流见 `docs/框架/Afterglow框架使用指南-面向AI.md`。

## Resource 契约

| 类型 | 脚本 | 必填/合法条件 | 典型失败 |
|---|---|---|---|
| Spawn | `scripts/data/encounter_spawn_definition.gd` | `entity_scene != null`；`spawn_position` 为局部坐标 | 空场景、挂错脚本 |
| Encounter | `scripts/data/encounter_definition.gd` | `spawns` 至少包含一个合法 Spawn；清单内每项都应合法 | 空清单、null 项、错误 Resource |
| Area | `scripts/data/area_definition.gd` | `id` 非空且稳定；`display_name` 非空；`encounter` 合法 | 内嵌场景资源、空 ID、错误遭遇脚本 |
| Upgrade | `scripts/data/upgrade_definition.gd` | `id`、`display_name` 非空；`amount > 0`；effect 受支持 | 重复/空 ID、非正数、未知 effect |

校验调用：

```gdscript
var validator := ContentValidationModel.new()
var errors: PackedStringArray = validator.validate_area(area_definition)
if not errors.is_empty():
	push_error("invalid area: %s" % ", ".join(errors))
```

校验器严格检查 Resource 脚本身份。返回空数组表示合法；它不会实例化实体或修改资源。

## 遭遇实体契约

| 要求 | 原因 |
|---|---|
| 根节点可转换为 `Node2D` | `EncounterController` 需要设置位置并挂到 `content_root` |
| 存在 `EncounterMember` 子节点 | 控制器通过其 `defeated` 信号统计目标 |
| 存在 `HealthComponent` | 当前受伤/死亡流程依赖生命组件 |
| `EncounterMember.reward_xp >= 0` | 击败奖励会以非负数传给本局经验模型 |
| 可选 `Presenter` 节点 | 隔离美术、动画和反馈实现 |

## Presenter 契约

```gdscript
set_movement(direction: Vector2) -> void
play_attack(direction: Vector2) -> void
play_hit() -> void
set_dead(dead: bool) -> void
```

Presenter 只能表现结果，不能修改生命、伤害、奖励、目标或层状态。

## 内容接入检查单

- [ ] `.tres` 位于 `assets/areas/` 或 `assets/upgrades/`。
- [ ] 世界 `.tscn` 使用 `ExtResource`，未复制内嵌 Area/Encounter/Spawn。
- [ ] 新正式资源已登记到 `tests/run_framework_validation.gd`。
- [ ] 世界组装变化已在 `tests/run_scene_tests.gd` 回归。
- [ ] 新规则先有失败测试；纯资源字段变化至少通过框架验证和场景加载。
- [ ] 未把运行时状态写入 `.tres`。
- [ ] 未新增 Autoload、依赖或跨模块私有字段访问。

## 一键式验证清单

```powershell
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_model_tests.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/scene_test_runner.tscn
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_framework_validation.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 3
git diff --check
```

预期关键输出：`Model tests passed`、`Scene tests passed`、`Framework validation passed`，其余命令退出码为 0，`git diff --check` 无输出。
