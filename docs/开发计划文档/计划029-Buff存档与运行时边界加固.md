# 计划029：Buff 存档与运行时边界加固

## 1. 基本信息

- 状态：已完成
- 创建日期：2026-08-28
- 完成日期：2026-08-28
- 任务分类：跨模块回归修复、存档边界和玩家属性消费
- 任务来源：继续完善计划028后的实现审计

## 2. 目标

1. 对局外成长、局内 Buff 草稿和本局构筑快照执行严格类型、有限值和范围校验。
2. 快照恢复失败时不污染已有运行时状态，并保留合法旧快照兼容。
3. 最大生命 Buff 在死亡状态下保持死亡，不因重建血量模型意外复活。
4. 首页疾行成长使用与局内资源一致的 `move_speed` 标识，同时兼容历史 `speed` 标识。
5. 高品质幸运 Buff 的实际数值同步到候选抽取模型。

## 3. 非目标

- 不重做 Buff 数值、品质权重、存档文件版本或 UI 布局。
- 不清理工作区中其他计划的未提交修改。
- 不引入新依赖、Autoload 或网络抽象。

## 4. 修改范围

- `scripts/progression/meta_progression_model.gd`
- `scripts/progression/run_buff_draft_model.gd`
- `scripts/progression/run_build_model.gd`
- `scripts/data/upgrade_definition.gd`
- `scripts/combat/health_model.gd`
- `scripts/components/health_component.gd`
- `scripts/autoload/game_manager.gd`
- `scenes/flow/start_screen.gd`
- `tests/run_model_tests.gd`
- `tests/run_scene_tests.gd`

## 5. 验收标准

- [x] 三类 Buff/成长快照拒绝错误类型、负数、非有限值和非法堆栈，且失败不改变原状态。
- [x] 旧快照缺失新增字段仍可恢复。
- [x] 死亡血量组件应用最大生命倍率后仍为死亡且血量为零。
- [x] 首页疾行成长写入 `move_speed`，旧 `speed` 存档仍可注入。
- [x] 传说幸运 Buff 的构筑幸运与候选模型幸运一致。
- [x] 模型、场景、框架、编辑器、主场景和 diff 验证全部通过。

## 6. 测试策略

- 先在模型/场景测试中加入会失败的回归断言。
- 实现最小校验和状态重建修复。
- 运行完整 Godot 验证矩阵，并更新任务报告和计划索引。

## 7. 执行记录（2026-08-28）

- 为局外成长、局内 Buff 草稿、本局构筑和共享血量模型增加严格类型、有限值、范围和堆栈校验；恢复采用先解析后提交，失败不覆盖当前状态。
- 修复死亡实体应用最大生命倍率时被重建为满血存活的问题，并保留死亡与零血边界。
- 统一首页疾行成长的 `move_speed` 标识，兼容历史 `speed` 存档；高品质幸运奖励将实际倍率同步给候选抽取模型。
- 先运行失败回归测试确认缺陷，再实现修复并完成全量回归。

## 8. 验证记录

- 模型测试：`Model tests passed`。
- 场景测试：`Scene tests passed`。
- 框架资源验证：`Framework validation passed`。
- 存档集成：`Run save integration test passed`。
- Godot 编辑器无头扫描：退出码 0。
- 主场景无头启动 `--quit-after 3`：退出码 0。
- `git diff --check`：通过。

## 9. 风险

- 旧 JSON 数值可能以整数或浮点形式解析；对整数语义字段允许有限且无小数的数值。
- 历史局外成长可能使用 `speed` 标识，迁移逻辑必须保持其可用性。
- 场景和存档集成测试仍有既有 ObjectDB/RID 泄漏警告，但退出码为 0，未发现本轮新增失败。
- 本轮未执行带窗口的人工点击巡检；启动菜单、奖励节点、相机属性和交互路径均已由无头场景测试覆盖。
