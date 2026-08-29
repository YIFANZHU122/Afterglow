# 计划028：启动流程、镜头跟随与局内外 Buff 系统

## 1. 基本信息

- 状态：已完成
- 创建日期：2026-08-28
- 设计文档：`docs/superpowers/specs/2026-08-28-start-camera-buff-design.md`
- 任务来源：补齐开始界面、玩家跟随镜头、局内外 Buff 规则

## 2. 目标

1. 冷启动进入开始界面，支持开始、继续、难度选择、成长和退出。
2. Camera2D 平滑跟随玩家并保留世界边界。
3. 局内 Buff 改为四选一、品质、重复次数和幸运体系；刷新只由局外成长提供。
4. 首页局外成长使用局外结晶，升级初始 Buff 并装备一个带入本局；局内构筑在运行结束后清空。
5. 旧伤害/移速升级资源、旧 build 快照和现有核心循环保持兼容。

## 3. 范围与非目标

### 包含

- `MetaProgressionModel`：局外结晶、初始 Buff 等级、装备槽、刷新等级。
- `RunBuildModel`：品质、重复次数、幸运和可消费效果。
- 启动场景、成长面板、四选一奖励面板、Buff HUD。
- Player/生存模型对新增效果的最小真实消费。

### 不包含

- 新增 Autoload、插件、网络同步和完整技能树。
- 改写生存、灾难、Boss、地图、库存和复活规则。
- 将尚不存在的攻速、暴击、弹道或范围伤害伪接入现有战斗。

## 4. 任务拆分

- [x] Task 1：失败测试与局外成长模型。
- [x] Task 2：局内 Buff 品质、重复次数、幸运和刷新模型。
- [x] Task 3：启动场景、成长面板和主入口切换。
- [x] Task 4：Camera2D 平滑跟随与世界边界回归。
- [x] Task 5：四选一奖励 UI、玩家/生存效果消费和存档兼容。
- [x] Task 6：完整验证、任务报告和索引收尾。

## 5. 接口与数据变化

- 新增 `MetaProgressionModel`，局外 JSON 在原有 `meta_crystals` 旁增加 `meta_upgrades`、`equipped_initial_buff`。
- 扩展 `UpgradeDefinition.EffectType` 和品质字段；旧资源缺失字段使用普通品质和默认叠加规则。
- `RunBuildModel` 的新增运行时字段位于既有 `survival_state["build"]` 区域，不新增顶层快照字段。
- GameManager 新增局外成长、当前候选、刷新和 Buff 查询命令；调用方不访问私有模型字段。

## 6. 验收标准

- 冷启动菜单可见，开始游戏后进入地下室，继续游戏只在有效快照存在时可用。
- 成长面板可使用结晶升级初始 Buff 或刷新能力，并装备一个初始 Buff。
- 局内奖励显示四个候选，候选具有品质；重复获得同一 Buff 时次数递增；幸运改变品质权重；刷新消耗局外提供的次数。
- 伤害、移速、最大体力、体力恢复、饥饿/水分消耗至少各有一条真实效果验证。
- Camera2D 启用平滑跟随，世界边界和多地图恢复不回归。
- 标准模型、场景、框架、编辑器、主场景启动和 diff 验证通过。

## 7. 风险

- 历史旧快照没有品质/幸运字段：使用默认值恢复，不拒绝合法旧快照。
- 现有场景测试直接实例化地下室：保留世界控制器的空闲兜底，只由正式主入口负责显式开始运行。
- 工作区存在大量前序未提交修改：只修改本计划列出的文件，不执行破坏性 Git 操作。

## 8. 执行记录（2026-08-28）

- 新增 `MetaProgressionModel` 与 `RunBuffDraftModel`，并为结晶、初始 Buff 装备槽、刷新等级、品质、幸运、重复次数和局内刷新次数补充模型测试。
- 扩展 `UpgradeDefinition` 与 `RunBuildModel`；旧伤害/移速资源和旧 `build` 快照继续兼容，新增构筑字段仍位于 `survival_state["build"]`。
- `GameManager` 接入局外 JSON 扩展、开局初始 Buff 注入、Buff 查询/选择/刷新命令、XP/生存消耗倍率和运行快照恢复。
- 新增 `scenes/flow/start_screen.tscn`，主入口改为启动界面；成长面板支持六类初始 Buff 和刷新能力升级。
- `Player/Camera2D` 开启平滑跟随并保留世界边界；玩家 HUD 增加当前 Buff/幸运显示。
- 奖励界面改为六种 Buff 资源池中的四选一，显示品质、描述、重复次数、当前构筑和刷新次数，并保留旧 `choose_upgrade()` 调用兼容。
- 新增并登记四个正式升级资源：最大体力、体力恢复、节制、幸运。

## 9. 验证记录

- `run_model_tests.gd`：通过（`Model tests passed`）。
- `scene_test_runner.tscn`：通过（`Scene tests passed`）。
- `run_framework_validation.gd`：通过（`Framework validation passed`）。
- Godot 编辑器无头扫描：退出码 0。
- 主场景无头启动 `--quit-after 3`：退出码 0。
- `git diff --check`：通过。

## 10. 遗留风险

- 本轮未执行带窗口的人工点击巡检；自动场景测试已覆盖启动菜单、奖励候选节点、Camera2D 属性和旧流程兼容。
- 工作区仍包含其他计划产生的未提交文件，未在本计划中处理。
