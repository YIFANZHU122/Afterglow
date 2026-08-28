# Afterglow 正式天空、污染表现与裂口动物设计

## 1. 目标

在既有 `WorldEnvironmentPresenter` 与 `ActorPresenter` 边界内，连续补齐荒野末日的正式表现：天空层与荒野底景、天气专属动画/音效/后处理、裂口动物与少量寄生花污染变体，以及异常月相、污染天象和 SAN 视觉反馈。

## 2. 约束

- 只消费现有 `GameManager` 昼夜/灾难信号和只读查询，不修改生存、灾难概率、伤害、敌人规则、存档或随机流。
- 不新增 Autoload、插件、运行时依赖或输入动作。
- 所有新增表现都可在纹理缺失、音频不可用或后处理不支持时降级为纯色/几何图形。
- 裂口动物与寄生花使用独立 Presenter/场景，实体逻辑仍通过现有语义接口驱动。
- SAN 只表现当前传入的压力值，不保存、不改变任何核心数值。

## 3. 架构

```text
GameManager 状态/信号
  -> WorldEnvironmentPresenter
     -> Sky/Horizon/Weather/Audio/PostProcess/Anomaly/SAN 子树

ChaserEnemy
  -> RiftAnimalPresenter

静态污染点
  -> ParasiticFlower 场景 + Presenter
```

`WorldEnvironmentPresenter` 新增确定性表现方法：

- `present_anomaly(anomaly_kind: int, intensity: float) -> void`
- `present_san(sanity_ratio: float) -> void`

两者均为表现状态，不写回 `GameManager`。新增只读查询用于聚焦测试：
`get_anomaly_kind()`, `get_anomaly_intensity()`, `get_san_intensity()`。

## 4. 分阶段内容

1. 正式天空层与荒野末日底景：天空渐变、地平线光、尘埃/剪影层和统一色板。
2. 天气专属动画、音效和后处理：雨、热浪、浓雾、寒潮分别控制粒子、程序化生成音效、颜色/抖动/暗角后处理。
3. 裂口动物素材与动画：新增裂口动物 SVG 素材和 Presenter，接入追击敌人，不改变追击/攻击逻辑。
4. 少量寄生花污染变体：三种静态污染花场景，带呼吸/摆动/颜色变体，仅作为世界装饰。
5. 异常月相、污染天象与 SAN 表现：异常月相遮罩、裂隙天象、污染色偏和低 SAN 视觉反馈，默认关闭。

## 5. 验收

- 三个世界场景继续复用同一环境 Presenter，并能加载新增节点。
- 聚焦测试覆盖天空、四种天气特效开关、异常/SAN 强度边界和非法输入降级。
- 追击敌人场景使用裂口动物 Presenter，攻击/受击/死亡仍通过 `ActorPresenter` 语义调用。
- 岐巷郊外含不超过三个寄生花污染点，均不加入遭遇目标。
- 模型、聚焦、场景、框架、编辑器扫描、主场景启动和 `git diff --check` 全部通过。
