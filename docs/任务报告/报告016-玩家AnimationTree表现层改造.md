# 报告016：玩家 AnimationTree 表现层改造

## 1. 任务分类与计划

- 任务类型：玩家表现层、Godot 动画资源和场景回归改造
- 开发计划：`docs/开发计划文档/计划016-玩家AnimationTree表现层改造.md`
- 设计文档：`docs/superpowers/specs/2026-08-27-character-animation-tree-design.md`
- 最终状态：已完成

## 2. 完成内容

- 新增 `AnimationTreeActorPresenter`，把现有 `ActorPresenter` 语义映射到 `Idle`、`Move`、`Attack`、`Hit`、`Dead` 五态动画机。
- 玩家场景的 `Presenter` 子树现在拥有 `AnimatedSprite2D`、`AnimationPlayer` 和活动的 `AnimationTree`，状态图及可达过渡直接保存在场景资源中。
- Presenter 保留最近朝向，并在内部映射为 `down`、`left`、`right`、`up` 四组 SpriteFrames；停止移动不会丢失朝向。
- 攻击和受击为瞬态，结束后恢复当前移动或待机状态；死亡拥有最高优先级，复活恢复最近朝向的待机表现。
- 玩家脚本不再直接访问精灵可见性，也不包含 AnimationTree 节点路径、状态名或具体动画名；受伤信号只转交 `play_hit()`。
- 保留 `GrayboxActorPresenter` 供敌人和灰盒实体继续使用。

## 3. 修改与新增文件

### 动画表现

- 新增 `scripts/presentation/animation_tree_actor_presenter.gd`
- 新增 `scripts/presentation/animation_tree_actor_presenter.gd.uid`
- 修改 `scenes/characters/player/player.tscn`
- 修改 `scenes/characters/player/player.gd`

### 测试与文档

- 修改 `tests/run_scene_tests.gd`
- 新增 `docs/superpowers/specs/2026-08-27-character-animation-tree-design.md`
- 新增 `docs/开发计划文档/计划016-玩家AnimationTree表现层改造.md`
- 修改 `docs/开发计划文档目录.md`
- 新增本报告

工作区中的计划015、生存模型、GameManager、RunSessionModel、GrayboxActorPresenter 和模型测试修改属于既有并行工作，本任务没有回退或覆盖它们。同文件中的生存 HUD 与环境伤害内容也予以保留。

## 4. 接口与数据变化

- `ActorPresenter.set_movement(direction: Vector2) -> void`、`play_attack(direction: Vector2) -> void`、`play_hit() -> void`、`set_dead(dead: bool) -> void` 均保持不变。
- 新增实现类 `AnimationTreeActorPresenter`，调用方仍只依赖 `ActorPresenter` 语义。
- 未新增或修改 Autoload、输入映射、玩法规则、Resource schema、存档字段或未来联机命令边界。

## 5. 测试与验证

工作目录：`C:\work\project020-Afterglow\src\Afterglow`。

| 项目 | 命令 | 结果 |
|---|---|---|
| 模型测试 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_model_tests.gd` | 通过，`Model tests passed` |
| 场景回归 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/scene_test_runner.tscn` | 通过，`Scene tests passed`，无动画轨道警告 |
| 框架验证 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_framework_validation.gd` | 通过，`Framework validation passed` |
| 编辑器扫描 | `Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --quit` | 通过，退出码 0 |
| 主场景启动 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . --quit-after 3` | 通过，退出码 0 |
| 差异检查 | `git diff --check` | 通过 |

场景回归覆盖：初始待机、四方向映射、移动/停止切换、最近朝向保持、攻击瞬态、受击瞬态、死亡优先级、死亡期间拒绝移动和攻击、复活可见性恢复，以及原有完整玩法场景回归。

## 6. 风险与遗留问题

- 当前正式素材只有四方向行走帧，因此 `Attack`、`Hit` 和 `Dead` 首期使用颜色/可见性轨道表达；后续正式动作帧可以只替换 AnimationPlayer 动画，不改玩法脚本。
- 当前只改造玩家；敌人继续使用 `GrayboxActorPresenter`。敌人拥有正式动画素材后可复用同一语义边界，但应按实体动画需求另建计划。
- 动画时长只控制视觉瞬态恢复，不决定伤害判定、无敌时间或死亡合法性。

## 7. 结论

计划016完成。玩家角色现在通过可在 Godot 编辑器中检查和调整的 `AnimationPlayer + AnimationTree` 显示动画，玩法代码保持与具体动画资源解耦。
