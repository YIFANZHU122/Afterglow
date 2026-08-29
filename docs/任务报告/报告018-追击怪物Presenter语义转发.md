# 报告018：追击怪物 Presenter 语义转发

## 1. 任务分类与计划

- 任务类型：小范围战斗实体表现层接入、场景回归测试
- 开发计划：无（范围受控，仅修改追击怪物脚本与场景测试）
- 关联框架契约：`ActorPresenter` 的移动、攻击、受击和死亡语义接口
- 最终状态：已完成

## 2. 完成内容

- 追击怪物远距离追击时调用 `Presenter.set_movement(normalized_direction)`。
- 玩家进入攻击距离后调用 `Presenter.set_movement(Vector2.ZERO)`，表现层可正确切换待机。
- 接触伤害成功造成实际生命值下降后调用 `Presenter.play_attack(direction_to_player)`。
- 零伤害、玩家已死亡或缺少生命组件时不发送攻击表现事件。
- 保留原有接触伤害、攻击冷却、追击距离和死亡判定规则。
- 受击继续通过 `Presenter.play_hit()` 转发。
- 死亡通过 `Presenter.set_dead(true)` 转发；移除怪物脚本直接设置 `Visual.visible` 的逻辑，视觉可见性由 Presenter 负责。
- 新增记录型测试 Presenter，验证调用语义而不依赖具体动画资源。

## 3. 修改与新增文件

- 修改 `scripts/combat/chaser_enemy.gd`
- 修改 `tests/run_scene_tests.gd`
- 新增 `tests/recording_actor_presenter.gd`
- 新增 `tests/recording_actor_presenter.gd.uid`

工作区中计划013至计划017及其他并行未提交修改均被保留，未作回退或覆盖。

## 4. 接口与数据变化

- 未修改 `ActorPresenter` 公共方法签名。
- 未新增 Resource schema、Autoload、输入映射、存档字段、插件、依赖或网络抽象。
- 怪物玩法脚本只依赖 Presenter 语义方法，不访问具体动画节点、Sprite 路径或动画名称。
- 伤害与冷却仍由原有战斗逻辑决定，Presenter 只接收表现结果。

## 5. TDD 记录

- 先加入记录型 Presenter 与场景断言。
- 首次运行场景测试确认移动、停止和攻击转发缺失导致红灯。
- 实现最小语义转发后场景测试转绿。
- 补充零伤害不触发攻击表现的失败路径断言，确认先红后绿。

## 6. 测试与验证

工作目录：`C:\work\project020-Afterglow\src\Afterglow`。

| 项目 | 命令 | 结果 |
|---|---|---|
| 模型测试 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_model_tests.gd` | 通过，`Model tests passed` |
| 场景回归 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/scene_test_runner.tscn` | 通过，`Scene tests passed` |
| 框架验证 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . -s res://tests/run_framework_validation.gd` | 通过，`Framework validation passed` |
| 编辑器扫描 | `Godot_v4.7.1-stable_win64_console.exe --headless --editor --path . --quit` | 通过，退出码 0 |
| 主场景启动 | `Godot_v4.7.1-stable_win64_console.exe --headless --path . --quit-after 3` | 通过，退出码 0 |
| 差异检查 | `git diff --check` | 通过，无输出 |

场景回归覆盖：远距离追击方向、攻击范围内停止表现、成功接触伤害攻击事件、零伤害失败路径、受击事件、死亡事件以及死亡视觉由 Presenter 接管。

## 7. 风险与遗留问题

- 当前怪物仍使用灰盒 `Polygon2D + GrayboxActorPresenter`，没有正式攻击、受击和死亡动作素材。
- 本轮未接入怪物专用 `AnimationTree`；待正式动画资源到位后，可在不修改怪物玩法脚本的前提下替换 Presenter 实现。
- 怪物脚本缺少 Presenter 时仍允许玩法继续运行，并只输出一次警告。

## 8. 结论

追击型怪物已完成与 `ActorPresenter` 的表现语义解耦。移动、攻击、受击和死亡结果均由 Presenter 接管，原有战斗规则保持不变，标准验证全部通过。
