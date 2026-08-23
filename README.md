# Afterglow

一句话简介：Godot 4 俯视角 2D 生存 Roguelite 原型项目，当前包含基础场景切换、玩家移动、物品栏、近战攻击和训练人偶验证内容。

## 当前状态

进行中。项目级 AI 架构规范已经生效；生命、体力、玩家输入、库存、攻击资格、复活、物品交互和世界场景组装的核心边界已完成第一阶段收敛，剩余改造按新增规则逐步推进。

## AI 与开发入口

- 工具适配入口：`AGENTS.md`
- 唯一权威项目规范：`AI项目总规范.md`
- 统一 AI 总入口提示词：`outputs/AI统一总入口提示词.md`
- 专项规范：`docs/规范/`
- 开发计划索引：`docs/开发计划文档目录.md`
- 开发计划模板：`docs/模板/开发计划模板.md`

## 工程入口

- Godot 工程：`project.godot`
- 主场景配置：`project.godot` 中的 `run/main_scene`
- 当前主场景：`scenes/world/basement/basement.tscn`
- 既有源码：`scripts/`、`scenes/`

## 运行与验证

使用 Godot 4.7.1 打开本目录中的 `project.godot` 并运行项目。Godot 不在 PATH，但已使用 `C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe` 完成模型测试、编辑器扫描和主场景无头验证。

Git 验证：本目录是独立 Git 仓库，修改前工作区干净；本次改造完成后必须检查 `git diff` 和状态。

## 现有结构

```text
Afterglow/
├─ Art/
├─ assets/
├─ scenes/
├─ scripts/
├─ docs/
├─ tests/
├─ game.tscn
├─ project.godot
└─ AI项目总规范.md
```

## 当前差距

- `project.godot` 当前 `config/features` 声明为 `4.7`；已使用 Godot 4.7.1 完成编辑器扫描和主场景无头验证。
- 现有 `scenes/` 仍承担 Godot 节点组合和表现生命周期，这是有意保留的组合根职责；核心规则已逐步映射到 `player`、`combat`、`world`、`progression`、`items`、`presentation`。
- 已加入 `tests/run_model_tests.gd` 模型测试入口；已使用 `C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe` 完成模型测试、脚本扫描和主场景无头验证。
- 现有 `GameManager` 和 `Inventory` 是 Autoload；任何拆分、替换或新增全局服务都属于高风险变更，必须建立开发计划。

## 下一步

1. 仅在新增玩法或发现具体跨模块违规时建立新计划。
2. 按小步迁移方式继续收敛边界，不一次性重写现有场景。
