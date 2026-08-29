# 第三方美术素材清单

本清单记录本轮天气与月相表现接入使用的免费素材。游戏运行时只引用 `res://assets/art/` 下的稳定路径；`source/` 目录按来源包保留原始文件名和许可证文本，便于后续替换和追溯。

下载日期：2026-08-27

## Kenney Particle Pack

- 作者：Kenney Vleugels（Kenney.nl）
- 许可证：Creative Commons Zero（CC0 1.0）
- 资源页：https://kenney.nl/assets/particle-pack
- 许可证页：https://creativecommons.org/publicdomain/zero/1.0/
- 用途：`dust_particle.png`、`rain_streak.png`
- 上游文件：`dirt_01.png`、`trace_01.png`
- 原件目录：`assets/art/weather/source/kenney_particle_pack/`
- SHA-256：
  - `assets/art/weather/dust_particle.png` — `6827A0A32A293EC9570FB98D63963B8DD6E6AABA9E1096AFAD932E93A378BEA9`
  - `assets/art/weather/rain_streak.png` — `34DE69BC3F665B23FE9BED15F388EFD8E8E4DC1A99F2FC5DB9BA8715C525711F`

## Kenney Smoke Particles

- 作者：Kenney Vleugels（Kenney.nl）
- 许可证：Creative Commons Zero（CC0 1.0）
- 资源页：https://kenney.nl/assets/smoke-particles
- 许可证页：https://creativecommons.org/publicdomain/zero/1.0/
- 用途：`smoke_particle.png`、`frost_particle.png`
- 上游文件：`smoke_01.png`、`whitePuff00.png`
- 原件目录：`assets/art/weather/source/kenney_smoke_particles/`
- SHA-256：
  - `assets/art/weather/smoke_particle.png` — `E8724C219E8D35859167FC0A7E207E13C72CCF0C29704909B9BB3D3DC71C6CF7`
  - `assets/art/weather/frost_particle.png` — `33F894C2279BEE9F77874DBFA3C0E9F071A0EE5E1A7065DCC40196029D699F58`

## Fog Animation

- 作者：AntumDeluge
- 许可证：Creative Commons Zero（CC0 1.0）
- 资源页：https://opengameart.org/content/fog-animation
- 许可证页：https://creativecommons.org/publicdomain/zero/1.0/
- 用途：`fog_animation.png`，作为浓雾与远景灰化遮罩
- 原件路径：`assets/art/weather/source/fog_animation/fog_1.png`
- SHA-256：`A31B96A7FB54F0CD393B454B7E020F3C131064A163F7E10F09F1E25228812740`

## 2 Moon Phases Sets

- 作者：BizmasterStudios（StarNinjas）
- 许可证：Creative Commons Zero（CC0 1.0）
- 资源页：https://opengameart.org/content/2-moon-phases-sets
- 许可证页：https://creativecommons.org/publicdomain/zero/1.0/
- 用途：夜间 8 相月亮；采用白色月相组并统一重命名为稳定顺序
- 上游文件：`moon_new.png`、`moon_waxing_crescent.png`、`moon_first_qaurter.png`、`moon_waxing_gibbous.png`、`moon_full.png`、`moon_waning_gibbous.png`、`moon_third_quarter.png`、`moon_waning_crescent.png`
- 原件目录：`assets/art/moon/source/white_phases_starninjas/`
- SHA-256：
  - `assets/art/moon/moon_00_new.png` — `B0E7359DD03E6DE1B349AE9517DB506CEA2BB0A28DB6708AE3A642417E3A7CAE`
  - `assets/art/moon/moon_01_waxing_crescent.png` — `4ADBC2FE3D755910C04AC49D16265187FA66D3597F6C845B75E5796D1F0AD3BB`
  - `assets/art/moon/moon_02_first_quarter.png` — `032E37A863CC63A6B34D3FEE5A24D31E19B2B0A83B11D58924A5ADB5235AC0DC`
  - `assets/art/moon/moon_03_waxing_gibbous.png` — `5EEE8DF24E5AB3B6F3DC68FA7208F50F0EABB28DB01B3BBE814A17C42ECA903A`
  - `assets/art/moon/moon_04_full.png` — `2A3FBDD712D45DE3FDE656CB310955038D97A69D72017E1A78EBF5AAF3DA9723`
  - `assets/art/moon/moon_05_waning_gibbous.png` — `6886BDCB0AF342AA6066987A8D82111FF21D2416F1F78AD59E37767BF0181FC3`
  - `assets/art/moon/moon_06_third_quarter.png` — `515FF1478C8333C895FC8AB24314D1AA015199DCD49D3325F71CDB90C0CB3592`
  - `assets/art/moon/moon_07_waning_crescent.png` — `85BC9E1014E7E50473207AA4B584174CD8B26D9ADD2F6297F52895E8959023B0`

## 备注

- 天气素材只承担表现层纹理和粒子职责，不改变灾难概率、持续时间、伤害、难度、随机流或存档数据。
- 月相文件名中的 `first_qaurter` 是上游原始拼写；项目稳定路径修正为 `moon_02_first_quarter.png`。
- 若未来替换素材，应保留本清单中的原始来源和许可证记录，并更新对应 SHA-256 与用途。
