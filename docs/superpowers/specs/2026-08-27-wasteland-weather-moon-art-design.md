# Afterglow 荒野墨痕天气与月相美术设计

## 1. 背景与已确认方向

Afterglow 的美术方向确定为手绘荒野末日生存。玩家模型保持不变；敌人后续以裂口动物为主，寄生花只作为少量污染变体。本轮优先补足天气、月相和环境覆盖层，让现有昼夜与灾难系统获得可读、可替换的正式表现入口。

## 2. 目标

- 采用“荒野墨痕”作为常规天气风格：粗墨边、脏纸噪点、低饱和沙黄/灰蓝/骨白配色。
- 使用 8 相月相素材，同时服务夜间天空层和 HUD 月相提示。
- 使用许可证清晰的免费素材作为首轮骨架，保留来源、作者、许可证、下载日期和原始 URL。
- 通过独立 `WorldEnvironmentPresenter` 消费现有 `GameManager.survival_changed` 与 `GameManager.disaster_changed`，不修改生存或灾难规则。
- 将污染天象保留为后续异常事件变体，本轮不常驻、不新增 SAN 规则。

## 3. 非目标

- 不替换玩家模型或玩家 AnimationTree。
- 不在本轮接入裂口动物、寄生花或其他怪物素材。
- 不修改灾难概率、持续时间、难度、伤害、存档 schema 或随机流。
- 不新增插件、第三方运行时依赖、Autoload 或项目设置。
- 不制作完整天空盒、光照系统、音效系统或 SAN 数值系统。

## 4. 视觉语言

### 4.1 常规环境

- 白天：旧纸沙黄底色，轻微浮尘，不使用明亮卡通蓝天。
- 夜晚：灰蓝暗化，月亮为骨白至灰黄，不使用纯黑遮罩。
- 边缘：通过不规则雾带、烟尘和墨线雨形成手绘覆盖层。
- 可读性：天气覆盖层不得遮住玩家 HUD；默认透明度受控，暴雨、浓雾只在灾难生效阶段达到高强度。

### 4.2 天气映射

| 现有灾难 | 首轮表现 |
|---|---|
| 暴雨 | 斜向墨线雨、冷灰覆盖、轻微闪光 |
| 烈日 | 沙黄曝光、热浪感、缓慢浮尘 |
| 浓雾 | 两层错速雾带、远景灰化 |
| 寒潮 | 灰蓝覆盖、白色细粒与边缘霜色 |
| 其他灾难 | 保持昼夜基底，仅显示轻微风险色；后续专项补齐 |

灾难预警阶段使用低强度提示，生效阶段使用完整覆盖，结束后恢复昼夜基底。

### 4.3 月相

月相使用 8 相顺序：新月、娥眉月、上弦月、盈凸月、满月、亏凸月、下弦月、残月。首轮采用纯表现映射：`phase_index = (day_index - 1) mod 8`。该映射不写入核心模型、不影响怪物、天气概率或数值，只根据现有天数计算显示帧。

## 5. 架构与数据流

```text
GameManager.survival_changed
  -> WorldEnvironmentPresenter.present_survival(day_index, is_night)
  -> 昼夜色调 + 月相帧 + 月相可见性

GameManager.disaster_changed
  -> WorldEnvironmentPresenter.present_disaster(kind, phase)
  -> 天气覆盖层、粒子开关与强度
```

`WorldEnvironmentPresenter` 位于 `scripts/presentation/`，只控制其子节点的颜色、透明度、纹理区域与粒子发射。世界场景只负责实例化组件，不读取组件内部节点。

## 6. 资源与授权

- Kenney Particle Pack，作者 Kenney，Creative Commons CC0。
- Kenney Smoke Particles，作者 Kenney，Creative Commons CC0。
- Fog Animation，作者 AntumDeluge，Creative Commons CC0。
- 2 Moon Phases Sets，作者 BizmasterStudios，Creative Commons CC0。

项目内仅保留实际使用的原始文件与派生文件。`assets/art/THIRD_PARTY_ASSETS.md` 记录原始 URL、许可证页、下载日期和用途；派生文件不改变原始许可证声明。

## 7. 失败与降级

- 任一可选纹理缺失时，Presenter 使用纯色覆盖层继续运行并输出一次警告。
- 未收到有效灾难类型或阶段时恢复昼夜基底，不抛出异常。
- `day_index <= 0` 时月相回退到新月。
- 测试可直接调用表现方法，不依赖真实计时或随机触发灾难。

## 8. 验收

- 地下室场景含独立 `WorldEnvironmentPresenter`，不修改玩法节点层级和公共接口。
- 白天、夜晚、8 相月相、暴雨、烈日、浓雾、寒潮的表现状态可通过聚焦测试验证。
- 所有外部素材都位于稳定的 `res://assets/art/` 路径并有授权记录。
- 模型测试、环境 Presenter 聚焦测试、完整场景回归、框架验证、编辑器扫描、主场景启动和 `git diff --check` 均完成。
