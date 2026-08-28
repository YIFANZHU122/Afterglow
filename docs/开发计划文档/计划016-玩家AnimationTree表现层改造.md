# 计划016：玩家 AnimationTree 表现层改造

## 1. 基本信息

- 状态：已完成
- 创建日期：2026-08-27
- 完成日期：2026-08-27
- 任务分类：跨场景表现层改造、Godot 动画资源与场景回归
- 设计文档：`docs/superpowers/specs/2026-08-27-character-animation-tree-design.md`

## 2. 目标

在不改变玩家玩法规则和 `ActorPresenter` 公共契约的前提下，用 `AnimationPlayer + AnimationTree` 接管玩家的待机、移动、攻击、受击和死亡表现。

## 3. 背景与问题

当前玩家使用 `AnimatedSprite2D + GrayboxActorPresenter`，方向切换依赖具体 SpriteFrames 动画名，停止移动时未持续发送零方向，且玩家脚本直接控制 Sprite 可见性。动作增多后，具体动画名、优先级和恢复逻辑容易进入玩法脚本。项目已经建立 `ActorPresenter` 语义边界，本计划在该边界内替换具体实现。

## 4. 范围

### 包含

- 新增通用 `AnimationTreeActorPresenter`。
- 在玩家场景现有 `Presenter` 子树中封装精灵、AnimationPlayer 和 AnimationTree。
- 用 `AnimationTreeActorPresenter` 替换玩家的 `GrayboxActorPresenter`。
- 玩家移动每帧向 Presenter 报告含零向量的移动意图。
- 玩家死亡/复活不再直接访问具体精灵节点。
- 补状态机和场景冷启动回归测试。

### 不包含

- 新增或绘制正式待机、攻击、受击、死亡素材。
- 修改攻击判定窗口、伤害、移动、体力、死亡或复活规则。
- 改造敌人和训练人偶的动画资源。
- 引入插件、Autoload、外部依赖或联机代码。

## 5. 受影响模块与文件

| 模块/文件 | 影响 |
|---|---|
| `scripts/presentation/animation_tree_actor_presenter.gd` | 新增 AnimationTree 语义适配器 |
| `scenes/characters/player/player.tscn` | 在 Presenter 子树内配置精灵、动画资源和五态 AnimationTree |
| `scenes/characters/player/player.gd` | 移除具体精灵依赖，补零方向表现事件 |
| `tests/run_scene_tests.gd` | 新增动画状态和优先级回归 |

## 6. 架构与设计方案

数据流保持为 `PlayerCommand -> 玩家移动/战斗规则 -> ActorPresenter 语义方法 -> AnimationTreeActorPresenter -> AnimationTree/AnimationPlayer -> AnimatedSprite2D`。玩法脚本只表达移动方向、攻击、受击和死亡语义；具体状态名、节点路径、帧和颜色轨道封装在表现层。

首期采用 `Idle`、`Move`、`Attack`、`Hit`、`Dead` 五个语义状态，方向由 Presenter 映射到现有四组 SpriteFrames，不引入无实际素材支撑的 BlendSpace。攻击和受击是非循环瞬态，完成后恢复最新移动/待机状态；死亡状态拥有最高优先级。

## 7. 接口与数据变化

`ActorPresenter.set_movement(direction: Vector2) -> void`、`play_attack(direction: Vector2) -> void`、`play_hit() -> void`、`set_dead(dead: bool) -> void` 均保持不变。新增实现类只消费这些接口。无配置 schema、存档或未来联机影响。

## 8. 任务拆分

- [x] Task 1：添加失败的玩家动画状态机场景测试。
- [x] Task 2：实现 AnimationTreeActorPresenter 和玩家场景动画资源。
- [x] Task 3：移除玩家脚本具体视觉依赖并接入新 Presenter。
- [x] Task 4：完成完整验证、计划记录和任务报告。

## 9. 测试计划

| 场景 | 测试类型 | 命令或操作 | 预期结果 |
|---|---|---|---|
| 玩家动画状态 | 场景自动化 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/scene_test_runner.tscn` | 初始待机，移动/停止/攻击/受击/死亡状态正确 |
| 模型回归 | 自动化 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_model_tests.gd` | `Model tests passed` |
| 内容契约 | 自动化 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_framework_validation.gd` | `Framework validation passed` |
| 工程加载 | Godot 无头编辑器 | `Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --quit` | 退出码 0，无脚本/资源错误 |
| 主场景 | Godot 无头运行 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . --quit-after 3` | 退出码 0，无运行时错误 |

## 10. 验收标准

- [x] 玩家通过 AnimationTree 状态机显示待机和四方向移动。
- [x] 停止移动后进入最近朝向的待机状态。
- [x] 攻击、受击完成后恢复当前基础状态，死亡状态阻止其他表现覆盖。
- [x] 玩家脚本不引用具体精灵、AnimationPlayer、AnimationTree 或动画名。
- [x] 公共 Presenter 接口、玩法规则和资源 schema 不变。
- [x] 标准验证和 Git diff 检查通过。

## 11. 风险与回滚

| 风险 | 触发条件 | 缓解措施 | 回滚方式 |
|---|---|---|---|
| AnimationTree 资源路径或轨道错误 | 场景加载出现缺失轨道/节点警告 | 场景测试、编辑器扫描和主场景冷启动共同覆盖 | 玩家场景恢复旧内嵌精灵和 GrayboxActorPresenter |
| 瞬态动画覆盖移动或死亡 | 攻击/受击结束回写错误状态 | Presenter 内统一优先级并测试死亡期间的拒绝行为 | 保留语义接口，回退到无瞬态的基础状态切换 |
| 当前素材缺少正式动作帧 | 攻击/死亡视觉辨识度不足 | 首期沿用颜色和可见性反馈，后续只替换表现资源 | 不影响玩法逻辑，无需数据迁移 |

## 12. 执行记录

- 2026-08-27：确认采用 Presenter 内封装 `AnimationPlayer + AnimationTree` 的方案，首期只改玩家，保护工作区中计划015及生存系统的既有未提交修改。
- 2026-08-27：实现五态 AnimationTree 和四方向 SpriteFrames 映射。状态图及过渡持久化在玩家场景中，Presenter 只发出语义切换请求。
- 2026-08-27：场景测试先因缺少动画节点失败，接入后覆盖待机、移动、方向保持、攻击、受击、死亡优先级和复活恢复。

## 13. 验证结果

工作目录：`C:\work\project020-Afterglow\src\Afterglow`。

- 模型测试：通过，输出 `Model tests passed`。
- 场景测试：通过，输出 `Scene tests passed`，无动画轨道警告。
- 框架验证：通过，输出 `Framework validation passed`。
- Godot 4.7.1 编辑器无头加载：退出码 0。
- 主场景无头冷启动：退出码 0。
- `git diff --check`：通过。
- 静态扫描确认 `player.gd` 不包含 AnimatedSprite2D、AnimationPlayer、AnimationTree 或具体动画名引用。

## 14. 完成结论

已完成。玩家动画表现已由 `AnimationPlayer + AnimationTree` 接管，现有玩法规则、Presenter 公共接口、数据资源和存档边界均未改变。
