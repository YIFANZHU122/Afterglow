# 报告030：Buff 存档与运行时边界加固

## 1. 任务分类

- 跨模块回归修复、存档边界和玩家属性消费。
- 关联计划：`docs/开发计划文档/计划029-Buff存档与运行时边界加固.md`。

## 2. 修改内容

- `MetaProgressionModel`：局外快照严格校验整数、Buff ID、装备槽和刷新等级；恢复失败不污染原状态；兼容历史 `speed` 标识并规范化为 `move_speed`。
- `RunBuffDraftModel`：校验幸运、刷新次数和 Buff 堆栈的类型、有限值和范围。
- `RunBuildModel`：校验新增倍率、减伤、幸运、品质和堆栈；非法扩展字段和空 ID 被拒绝。
- `UpgradeDefinition`：拒绝非有限的效果值和品质倍率。
- `HealthModel`/`HealthComponent`：拒绝非有限生命快照；最大生命缩放保留死亡状态和零血。
- `GameManager`：校验奖励品质参数，并把高品质幸运奖励的实际数值同步给候选抽取模型；兼容 `speed` 初始 Buff 注入。
- 首页疾行成长改用 `move_speed`；模型与场景测试新增上述回归覆盖。

## 3. 接口与数据变化

- 未新增顶层存档字段。
- 既有 `survival_state["build"]`、`survival_state["buff_draft"]` 和局外 JSON 字段保持兼容。
- 新增恢复边界：错误类型、非有限值、负数、非法堆栈和空 Buff ID 返回 `false`，且不改变现有模型状态。
- `speed` 仅作为历史局外成长输入别名，内部及新 UI 使用 `move_speed`。

## 4. 测试与验证

执行目录：`C:\work\project020-Afterglow\src\Afterglow`

```text
Godot --headless -s res://tests/run_model_tests.gd       -> Model tests passed
Godot --headless res://tests/scene_test_runner.tscn      -> Scene tests passed
Godot --headless -s res://tests/run_framework_validation.gd -> Framework validation passed
Godot --headless res://tests/run_save_integration_test.tscn -> Run save integration test passed
Godot --headless --editor --quit                     -> exit code 0
Godot --headless --quit-after 3                      -> exit code 0
git diff --check                                      -> passed
```

场景测试和存档集成测试仍报告既有 ObjectDB/RID 泄漏警告，但测试退出码为 0，未发现本轮新增脚本错误。

## 5. 风险与遗留

- 未执行带窗口的人工点击巡检；启动界面、相机、奖励候选和死亡血量边界已由无头场景测试覆盖。
- 工作区仍保留其他计划产生的未提交修改，本轮未清理或回滚。

## 6. 结论

计划029验收标准已满足，状态：已完成。
