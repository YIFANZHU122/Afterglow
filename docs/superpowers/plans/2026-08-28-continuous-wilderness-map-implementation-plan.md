# Continuous Wilderness Map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将慈航郊外改造成一张 `5760×3240` 的连续荒野地图，加入草原、枯森林、荒漠废墟分区和可真实阻挡玩家/敌人的环境障碍。

**Architecture:** 保留现有 `WorldSceneController`、玩家、敌人和地图切换边界。新增地形表现场景 `CihangTerrainArt` 负责底色、过渡带和道路；新增树、岩石、废车三种 `StaticBody2D` 可复用场景负责视觉与碰撞；慈航郊外场景只负责组装节点和放置固定实例，不引入运行时随机生成或新全局服务。

**Tech Stack:** Godot 4.7.1、GDScript 2D、`Node2D`、`Polygon2D`、`Line2D`、`StaticBody2D`、`CollisionShape2D`、现有 Godot headless 场景测试。

## Global Constraints

- 目标技术栈保持 Godot 4.7.1、GDScript、当前纯单机架构。
- 不新增插件、Autoload、外部依赖、网络同步或顶层存档字段。
- 不改写玩家移动、攻击、敌人感知、灾难、存档和地图切换规则。
- 所有环境阻挡必须拥有真实 `CollisionShape2D`，不能用纯贴图替代碰撞。
- 视口保持 `1280×720`；慈航郊外地图固定为 `5760×3240`；外围墙厚度固定为 `40 px`。
- 入口、出口、玩家出生点、寄生花和关键交互点周围保持至少 `160 px` 无障碍缓冲。
- 主要通道宽度不低于 `128 px`，至少保留北侧和南侧两条横向可通行路线。
- 修改前后保留工作区其他未提交修改，不使用 `reset`、`checkout`、`clean` 或覆盖式回滚。
- 先写并观察失败测试，再写生产代码；每个增量都运行相关 Godot 验证。

---

### Task 1: Add Failing Wilderness Map Regression Tests

**Files:**
- Modify: `tests/run_scene_tests.gd`
- Reference: `scenes/world/cihang_outskirts/cihang_outskirts.tscn`
- Reference: `scripts/world/world_scene_controller.gd`

**Interfaces:**
- Consumes: existing `CIHANG_SCENE`, `Camera2D`, `WorldSceneController` and player physics APIs.
- Produces: regression assertions for map size, terrain node names, obstacle collision contracts, safe spawn points and player blocking.

- [ ] **Step 1: Add assertions before the Cihang scene integration checks.**

Insert the following after the Cihang scene is added to the tree and its first frame has elapsed:

```gdscript
	var cihang_world_size := Vector2(5760.0, 3240.0)
	var cihang_camera: Camera2D = cihang.get_node_or_null("Player/Camera2D") as Camera2D
	_assert_true(cihang_camera != null and cihang_camera.enabled, "cihang camera remains enabled")
	if cihang_camera != null:
		_assert_equal(cihang_camera.limit_right - cihang_camera.limit_left, 5680, "cihang camera horizontal limits match the expanded map")
		_assert_equal(cihang_camera.limit_bottom - cihang_camera.limit_top, 3160, "cihang camera vertical limits match the expanded map")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt") != null, "cihang exposes the continuous terrain art layer")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt/Grassland") is Polygon2D, "terrain art exposes the grassland region")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt/DeadForest") is Polygon2D, "terrain art exposes the dead forest region")
	_assert_true(cihang.get_node_or_null("CihangTerrainArt/DesertRuins") is Polygon2D, "terrain art exposes the desert ruins region")
	for obstacle_name: String in ["WildernessTree0", "WildernessRock0", "WildernessWreck0"]:
		var obstacle: Node = cihang.get_node_or_null(obstacle_name)
		_assert_true(obstacle is StaticBody2D, "%s is a blocking StaticBody2D" % obstacle_name)
		var obstacle_shape: CollisionShape2D = obstacle.get_node_or_null("CollisionShape2D") as CollisionShape2D if obstacle != null else null
		_assert_true(obstacle_shape != null and obstacle_shape.shape != null, "%s owns a valid collision shape" % obstacle_name)
		if obstacle != null:
			_assert_equal((obstacle as StaticBody2D).collision_layer, 1, "%s blocks the environment collision layer" % obstacle_name)
	var player_for_blocking: CharacterBody2D = cihang.get_node("Player") as CharacterBody2D
	var tree_for_blocking: StaticBody2D = cihang.get_node("WildernessTree0") as StaticBody2D
	player_for_blocking.global_position = tree_for_blocking.global_position + Vector2(-120.0, 0.0)
	player_for_blocking.velocity = Vector2(300.0, 0.0)
	player_for_blocking.move_and_slide()
	_assert_true(player_for_blocking.global_position.x < tree_for_blocking.global_position.x - 20.0, "player cannot move through a wilderness tree")
	player_for_blocking.global_position = cihang.get_node("FromBasementSpawn").global_position
	var safe_points: Array[NodePath] = [NodePath("PlayerSpawn"), NodePath("FromBasementSpawn"), NodePath("TransitionZone")]
	for point_path: NodePath in safe_points:
		var point: Node2D = cihang.get_node_or_null(point_path) as Node2D
		_assert_true(point != null, "%s remains present after map expansion" % point_path)
		if point != null:
			_assert_true(point.global_position.x >= 160.0 and point.global_position.x <= cihang_world_size.x - 160.0, "%s stays inside the expanded map buffer" % point_path)
			_assert_true(point.global_position.y >= 160.0 and point.global_position.y <= cihang_world_size.y - 160.0, "%s stays inside the expanded map buffer" % point_path)
```

- [ ] **Step 2: Run the scene test and verify the new assertions fail for the missing implementation.**

Run:

```powershell
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/scene_test_runner.tscn
```

Expected: FAIL because the current Cihang map is `3840×2160`, `CihangTerrainArt` and the three obstacle instances do not exist, and no internal obstacle can block the player.

---

### Task 2: Create Reusable Wilderness Obstacle Scenes

**Files:**
- Create: `scenes/objects/wilderness_tree/wilderness_tree.tscn`
- Create: `scenes/objects/wilderness_rock/wilderness_rock.tscn`
- Create: `scenes/objects/wilderness_wreck/wilderness_wreck.tscn`

**Interfaces:**
- Consumes: no gameplay services; each scene is self-contained.
- Produces: root `StaticBody2D` with `collision_layer = 1`, `collision_mask = 0`, a `CollisionShape2D` child with a non-null shape, and a visual child.

- [ ] **Step 1: Create the tree scene with a capsule-like blocking body.**

Use this scene structure:

```ini
[gd_scene load_steps=3 format=3]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_tree"]
radius = 34.0
height = 112.0

[node name="WildernessTree" type="StaticBody2D"]
collision_layer = 1
collision_mask = 0

[node name="Visual" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-34, 42, -22, -8, -10, -52, 0, -30, 16, -64, 34, -16, 22, 42)
color = Color(0.16, 0.20, 0.13, 1)

[node name="Trunk" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-14, 58, 14, 58, 10, -4, -10, -4)
color = Color(0.25, 0.18, 0.12, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 8)
shape = SubResource("CapsuleShape2D_tree")
```

- [ ] **Step 2: Create the rock scene with a circular blocking body.**

Use a `CircleShape2D` with radius `48`, root name `WildernessRock`, collision layer `1`, and a muted gray-brown `Polygon2D` with an offset highlight polygon. The collision shape must be centered at the root and cover the main rock silhouette.

- [ ] **Step 3: Create the wreck scene with a rectangular blocking body.**

Use a `RectangleShape2D` of `Vector2(180, 76)`, root name `WildernessWreck`, collision layer `1`, a rust-red body polygon, two dark wheel polygons and a broken windshield line. The collision shape must remain inside the visual silhouette so the object is not unfairly larger than it looks.

- [ ] **Step 4: Run the scene test again.**

Expected: obstacle scene contract assertions can pass only after the three scenes are instanced by the world; terrain/map assertions remain red.

---

### Task 3: Build the Continuous Terrain Art Layer

**Files:**
- Create: `scenes/presentation/cihang_terrain_art.tscn`

**Interfaces:**
- Consumes: no gameplay state; only fixed map coordinates.
- Produces: `CihangTerrainArt` root with named `Polygon2D` regions `Grassland`, `DeadForest`, `DesertRuins`, named transition bands, and two visible route guides that remain behind gameplay entities.

- [ ] **Step 1: Create the terrain root and base background.**

Create a `Node2D` named `CihangTerrainArt` with `z_index = -8`. Add a full-map base polygon from `(40,40)` to `(5720,3200)` in desaturated olive green.

- [ ] **Step 2: Add three continuous terrain polygons.**

Add these named polygons and colors:

```ini
[node name="Grassland" type="Polygon2D" parent="."]
polygon = PackedVector2Array(40, 40, 2200, 40, 2200, 3200, 40, 3200)
color = Color(0.22, 0.30, 0.16, 1)

[node name="DeadForest" type="Polygon2D" parent="."]
polygon = PackedVector2Array(1900, 40, 4300, 40, 4300, 3200, 1900, 3200)
color = Color(0.18, 0.23, 0.17, 1)

[node name="DesertRuins" type="Polygon2D" parent="."]
polygon = PackedVector2Array(4000, 40, 5720, 40, 5720, 3200, 4000, 3200)
color = Color(0.46, 0.38, 0.23, 1)
```

The overlap ranges create the visual transition bands; do not add solid collision to these polygons.

- [ ] **Step 3: Add road and terrain-detail lines.**

Add `NorthRoute` and `SouthRoute` `Polygon2D` nodes as muted dirt paths, each at least `160 px` tall, crossing the full map from west to east. Add `GrassTufts`, `ForestMistBand`, `DuneBand`, `RuinStripe` as `Line2D`/`Polygon2D` decorative nodes. Keep all details behind gameplay entities and use no external runtime dependency.

- [ ] **Step 4: Run the scene test.**

Expected: terrain node assertions can pass only after the layer is instanced by the Cihang scene; map size and obstacle placement remain red.

---

### Task 4: Expand and Assemble the Cihang Outskirts Map

**Files:**
- Modify: `scenes/world/cihang_outskirts/cihang_outskirts.gd`
- Modify: `scenes/world/cihang_outskirts/cihang_outskirts.tscn`
- Modify: `scenes/world/cihang_outskirts/cihang_outskirts.gd.uid` only if Godot regenerates it
- Modify: `docs/开发计划文档/计划031-连续荒野地图与环境碰撞.md`

**Interfaces:**
- Consumes: `CihangTerrainArt`, the three obstacle scenes, existing player/transition/flower/environment scenes.
- Produces: a fixed `5760×3240` Cihang scene with four perimeter walls, safe entry/exit points, terrain art and fixed collision obstacle instances.

- [ ] **Step 1: Update the world size contract.**

Change `_get_world_size()` in `cihang_outskirts.gd` to return `Vector2(5760.0, 3240.0)` and update its comment to describe the continuous three-biome map.

- [ ] **Step 2: Expand the background and perimeter walls.**

In `cihang_outskirts.tscn`:

- Change the horizontal wall shape to `Vector2(5760, 40)` and vertical wall shape to `Vector2(40, 3240)`.
- Set `Background` position to `Vector2(2880, 1620)` and polygon corners to `(-2880,-1620)..(2880,1620)`.
- Place `WallTop` at `(2880,20)`, `WallBottom` at `(2880,3220)`, `WallLeft` at `(20,1620)`, and `WallRight` at `(5740,1620)`.
- Keep wall visuals aligned with their collision shapes and preserve the existing collision layer behavior.

- [ ] **Step 3: Preserve flow nodes and place safe points.**

Use these fixed positions:

| Node | Position |
|---|---:|
| `PlayerSpawn` | `(2880, 1620)` |
| `FromBasementSpawn` | `(760, 1620)` |
| `TransitionZone` | `(280, 1620)` |
| `Player` initial position | `(2880, 1620)` |
| `ParasiticFlowerScarlet` | `(1320, 900)` |
| `ParasiticFlowerAshen` | `(4700, 2460)` |
| `ParasiticFlowerViolet` | `(3400, 720)` |

The entry and exit route must remain clear for at least `160 px` around their centers.

- [ ] **Step 4: Instance terrain art and the three obstacle types.**

Add an external scene resource for `cihang_terrain_art.tscn`, plus external scene resources for the three obstacle scenes. Add at least these instances, leaving the north and south routes open:

| Instance | Position | Scale/variant |
|---|---:|---|
| `WildernessTree0` | `(2550, 1620)` | `(1,1)` |
| `WildernessTree1` | `(2820, 1380)` | `(0.9,0.9)` |
| `WildernessTree2` | `(3100, 1860)` | `(1.1,1.1)` |
| `WildernessTree3` | `(3440, 1420)` | `(0.85,0.85)` |
| `WildernessTree4` | `(3700, 1840)` | `(1,1)` |
| `WildernessRock0` | `(1780, 1180)` | `(1,1)` |
| `WildernessRock1` | `(4200, 1120)` | `(1.2,0.9)` |
| `WildernessRock2` | `(4900, 2040)` | `(0.9,1.1)` |
| `WildernessWreck0` | `(4580, 1540)` | `(1,1)` |
| `WildernessWreck1` | `(5200, 2480)` | `(0.9,0.9)` |

Keep obstacle centers at least `160 px` from the listed safe points and ensure no obstacle chain spans both routes.

- [ ] **Step 5: Run the focused scene test and tune only map coordinates if needed.**

Run:

```powershell
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/scene_test_runner.tscn
```

Expected: all new Cihang map, terrain, obstacle and player-blocking assertions pass while the prior scene assertions remain green.

---

### Task 5: Add Collision/Navigation Boundary Regression Coverage

**Files:**
- Modify: `tests/run_scene_tests.gd`
- Modify: `docs/开发计划文档/计划031-连续荒野地图与环境碰撞.md`

**Interfaces:**
- Consumes: assembled Cihang scene and existing `CharacterBody2D` movement API.
- Produces: explicit checks for route clearance, obstacle shape validity, safe point clearance and camera boundary consistency.

- [ ] **Step 1: Add route and obstacle-spacing assertions.**

Add assertions that the two route polygons exist, have at least `160 px` vertical span, and that every obstacle center is outside both route center bands. Check each obstacle's distance from `PlayerSpawn`, `FromBasementSpawn` and `TransitionZone` is at least `160 px`.

- [ ] **Step 2: Add a boundary movement assertion.**

Move the Cihang player toward the right wall for one physics step and assert that its x-position remains below `5720 - 32`, then restore the player to `PlayerSpawn`. This covers the expanded perimeter collision and camera limit assumptions without changing player movement code.

- [ ] **Step 3: Run the focused scene test.**

Expected: `Scene tests passed`, with only the existing ObjectDB leak warning if it remains present.

---

### Task 6: Complete Documentation and Full Verification

**Files:**
- Modify: `docs/开发计划文档/计划031-连续荒野地图与环境碰撞.md`
- Modify: `docs/开发计划文档目录.md`
- Create: `docs/任务报告/报告032-连续荒野地图与环境碰撞.md`

**Interfaces:**
- Consumes: completed code, tests and verification outputs.
- Produces: final project plan status, numeric tuning record, change inventory, test evidence and known warnings.

- [ ] **Step 1: Update the development plan.**

Mark every acceptance item complete only after the corresponding command passes. Record the final obstacle count, map dimensions, route width and safe-point buffer used by the scene.

- [ ] **Step 2: Run the complete verification matrix.**

Run from `C:\work\project020-Afterglow\src\Afterglow`:

```powershell
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_model_tests.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/scene_test_runner.tscn
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_framework_validation.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/run_save_integration_test.tscn
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 3
git diff --check
```

Expected: model, scene, framework and save tests print their `passed` messages; editor and main scene exit with code `0`; `git diff --check` produces no output.

- [ ] **Step 3: Write the final task report.**

Include the exact files changed, the map and collision values, the commands and exit codes, the pre-existing leak warnings, and any remaining visual-density limitations. Do not claim completion if any required command fails.

---

## Review Checklist

- [ ] No placeholder terms (`TODO`, `TBD`, vague “later” steps) remain in this plan.
- [ ] Every new scene has an explicit node contract and collision shape.
- [ ] Test names describe observable behavior, not implementation trivia.
- [ ] Map dimensions, safe buffers and route widths match the approved design document.
- [ ] Existing scene, save and flow tests remain part of final verification.
