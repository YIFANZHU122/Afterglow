# 报告029：启动流程、镜头跟随与局内外 Buff 系统

## 任务类型

跨模块高风险功能开发，涉及流程入口、场景、玩家表现、局内成长、局外存档和公共接口。

## 计划

`docs/开发计划文档/计划028-启动流程镜头跟随与局内外Buff系统.md`

## 已完成

- 新增启动界面：开始游戏、继续游戏、难度选择、局外成长和退出。
- 主场景切换为 `res://scenes/flow/start_screen.tscn`；继续按钮只在有效安全退出快照存在时启用。
- 新增 `MetaProgressionModel`，持久化局外结晶、初始 Buff 等级、单一装备槽和刷新能力等级。
- 新增 `RunBuffDraftModel`，支持四选一候选、品质权重、幸运、重复次数和局内刷新次数。
- 扩展 `UpgradeDefinition`/`RunBuildModel`，支持伤害、移速、最大体力、体力恢复、生存消耗、幸运等实际效果；旧资源与旧快照兼容。
- 玩家接入最大体力、体力恢复和伤害减免消费，HUD 显示 Buff 次数及幸运。
- `Camera2D` 启用平滑跟随，世界边界逻辑保持不变。
- 奖励界面由两个硬编码按钮改为六类资源池中的四张候选卡，显示品质、说明、次数和刷新状态。

## 主要文件

- `scripts/progression/meta_progression_model.gd`
- `scripts/progression/run_buff_draft_model.gd`
- `scripts/progression/run_build_model.gd`
- `scripts/data/upgrade_definition.gd`
- `scripts/autoload/game_manager.gd`
- `scenes/flow/start_screen.tscn`
- `scenes/flow/start_screen.gd`
- `scenes/ui/reward_selection/reward_selection.tscn`
- `scenes/ui/reward_selection/reward_selection.gd`
- `scenes/characters/player/player.tscn`
- `scenes/characters/player/player.gd`
- `scripts/components/health_component.gd`
- `assets/upgrades/max_stamina_upgrade.tres`
- `assets/upgrades/stamina_regen_upgrade.tres`
- `assets/upgrades/survival_efficiency_upgrade.tres`
- `assets/upgrades/luck_upgrade.tres`

## 接口与数据变化

- `UpgradeDefinition.EffectType` 增加最大生命、减伤、最大体力、体力恢复、XP、幸运和生存消耗倍率类型。
- `RunBuildModel` 新增聚合查询、品质/次数摘要及兼容恢复字段。
- `GameManager` 新增局外成长、Buff 候选/刷新、Buff 查询和有效继续存档查询命令。
- `afterglow_meta.json` 保留 `meta_crystals`，并追加局外模型字段；旧文件可读取。
- 运行快照新增字段位于 `survival_state["build"]` 和同区域的 `buff_draft`，旧快照缺失时采用默认值。

## 验证

```text
Model tests passed
Scene tests passed
Framework validation passed
Godot editor headless exit code 0
Main scene headless exit code 0
git diff --check passed
```

## 风险与遗留

- 当前没有带窗口的人工点击记录；自动场景测试覆盖关键节点和交互入口。
- 工作区中的其他前序计划修改保持原样，未做清理或回滚。

## 结论

计划028验收标准已满足，状态标记为“已完成”。
