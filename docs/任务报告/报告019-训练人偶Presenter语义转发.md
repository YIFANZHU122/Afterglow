# 报告019：训练人偶 Presenter 语义转发

## 1. 任务分类与计划

- 任务类型：小范围战斗实体表现层接入、场景与回归测试
- 开发计划：无（单一实体表现边界改造，未修改公共契约或核心规则）
- 关联框架契约：`ActorPresenter` 的攻击、受击、死亡和复活语义接口
- 最终状态：实现完成；工作区完整场景回归受既有并行基线阻塞

## 2. 完成内容

- 训练人偶场景新增可替换的 `Presenter` 节点，当前使用 `GrayboxActorPresenter`。
- 受击时调用 `Presenter.play_hit()`，移除脚本直接闪红的视觉逻辑。
- 子弹成功生成后调用 `Presenter.play_attack(direction)`，方向使用归一化射击方向。
- 死亡调用 `Presenter.set_dead(true)`，移除脚本直接设置 `Visual.visible` 的逻辑。
- 复活调用 `Presenter.set_dead(false)`，由表现层恢复可见性。
- 保留训练人偶原有射击范围、发射间隔、子弹伤害、复活计时、血条和碰撞规则。
- 缺少 Presenter 时玩法继续运行，并只输出一次警告。

## 3. 修改与新增文件

- 修改 `scenes/objects/training_dummy/training_dummy.gd`
- 修改 `scenes/objects/training_dummy/training_dummy.tscn`
- 修改 `tests/run_scene_tests.gd`
- 新增 `tests/training_dummy_presenter_focus_test.gd`
- 新增 `tests/training_dummy_presenter_focus.tscn`

工作区中计划013至计划018及其他并行未提交修改均被保留，未作回退或覆盖。

## 4. 接口与数据变化

- 未修改 `ActorPresenter` 公共方法签名。
- 训练人偶在场景就绪时解析 `Presenter` 依赖，调用方只使用 Presenter 语义方法。
- 未新增 Resource schema、Autoload、输入映射、存档字段、插件、依赖或网络抽象。
- 未改变训练人偶的战斗、射击、死亡或复活规则。

## 5. TDD 记录

- 先新增训练人偶 Presenter 聚焦测试。
- 临时撤回转发实现后运行测试，确认受击、发射、死亡、复活和视觉边界五项断言失败。
- 恢复最小 Presenter 转发实现后，聚焦测试通过。
- 同样的语义断言已并入 `run_scene_tests.gd` 的地下室回归链路。

## 6. 测试与验证

工作目录：`C:\work\project020-Afterglow\src\Afterglow`。

| 项目 | 命令 | 结果 |
|---|---|---|
| 训练人偶聚焦测试 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/training_dummy_presenter_focus.tscn` | 通过，`Training dummy presenter focus test passed` |
| 模型测试 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_model_tests.gd` | 通过，`Model tests passed` |
| 完整场景回归 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/scene_test_runner.tscn` | 未通过：在训练人偶行为断言执行前，并行新增的威胁预算断言调用了尚未实现的 `EncounterController.get_used_threat_budget` |
| 框架验证 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_framework_validation.gd` | 通过，`Framework validation passed` |
| 编辑器扫描 | `Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --quit` | 通过，退出码 0 |
| 主场景启动 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . --quit-after 3` | 通过，退出码 0 |
| 差异检查 | `git diff --check` | 通过，无输出 |

## 7. 阻塞与风险

- 当前 `tests/run_scene_tests.gd` 已包含并行加入的遭遇威胁预算断言，但 `EncounterController` 尚未提供 `get_used_threat_budget`；因此完整场景测试在进入本任务行为断言前停止。
- 该阻塞与训练人偶 Presenter 改造无关；聚焦测试已覆盖本任务的核心行为。
- 当前训练人偶仍使用灰盒 `Polygon2D + GrayboxActorPresenter`，暂不接入专用 AnimationTree。
- 训练人偶的发射动画只表达“子弹已生成”的结果，不改变攻击判定或伤害时机。

## 8. 结论

训练人偶已完成与 `ActorPresenter` 的表现语义解耦。受击、发射、死亡和复活均通过 Presenter 转发，玩法规则保持不变。完整项目回归需等待工作区既有灾难接口基线补齐后重新执行。
