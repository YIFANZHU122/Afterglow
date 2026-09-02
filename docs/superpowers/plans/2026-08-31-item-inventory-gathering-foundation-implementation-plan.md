# Item, Inventory, and Gathering Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the stable item-instance, stacked inventory, weight, eight-slot HUD, finite world-resource, and snapshot foundation used by every later survival system.

**Architecture:** Typed `ItemData` and `WorldResourceDefinition` resources describe immutable content. `ItemStackModel`, `InventoryModel`, and `GatherableResourceModel` own runtime state without scene dependencies; Autoload and scene scripts translate commands and present results. Existing `ItemData` callers remain compatible through `get_selected_item()` and `add_item()`, while new quantity-aware APIs carry stacks.

**Tech Stack:** Godot 4.7.1, GDScript, typed Resource content, RefCounted domain models, Godot scene composition, JSON run snapshots.

## Global Constraints

- Keep the project pure single-player and add no plugin, dependency, network layer, or new Autoload.
- Base inventory capacity is exactly `8`; backpack capacity changes belong to plan039.
- Difficulty changes resource richness through `SurvivalTuning.difficulty_resource_richness()` and does not change base slot count.
- Task materials remain in the independent escape objective and never occupy inventory slots or weight.
- Static resources never store runtime quantity, durability, remaining gathers, or depletion.
- All item and world entities use stable IDs; snapshots never rely on node order.
- Preserve existing stone-sword combat and old schema-version-1 inventory snapshots.
- Every task follows red-green-refactor and ends with its focused test command.

---

## File Structure

### New domain and data files

- `scripts/items/item_stack_model.gd`: one runtime stack and its quantity/durability snapshot.
- `scripts/items/item_catalog.gd`: stable ID-to-typed-resource lookup used by restore and validation.
- `scripts/data/world_resource_definition.gd`: immutable resource-node content schema.
- `scripts/world/gatherable_resource_model.gd`: remaining-unit and depletion rules.

### New content and scene files

- `assets/items/wood.tres`, `stone.tres`, `wild_food.tres`, `scrap_parts.tres`: first material definitions.
- `assets/world_resources/*.tres`: typed gathering definitions for those materials.
- `scenes/objects/gatherable_resource/gatherable_resource.gd`: interaction and presentation adapter.
- `scenes/objects/gatherable_resource/gatherable_resource.tscn`: reusable finite resource node.

### Existing files changed

- `scripts/item_data.gd`: immutable stack and weight fields plus validation.
- `scripts/items/inventory_model.gd`: quantity-aware stacks, atomic addition, weight, versioned snapshots.
- `scripts/autoload/inventory.gd`: eight-slot service and quantity-aware signals/API.
- `scripts/items/item_drop_service.gd`, `scenes/objects/item_world/*`: world stacks and full-stack dropping.
- `scripts/player/player_input_adapter.gd`, `project.godot`: select slots 1 through 8.
- `scenes/ui/inventory_bar/*`: dynamic eight-slot quantities and weight display.
- `scripts/core/run_snapshot_data.gd`, `scripts/core/run_save_model.gd`: schema version 2 and version-1 migration.
- `scripts/autoload/game_manager.gd`: aggregate/restore stable resource-node snapshots only.
- `scenes/world/basement/basement.tscn`, `scenes/world/cihang_outskirts/cihang_outskirts.tscn`: deterministic first resource placements.
- `scripts/data/content_validation_model.gd`, `tests/run_framework_validation.gd`: item/resource validation.
- `tests/run_model_tests.gd`, `tests/run_scene_tests.gd`, `tests/run_save_integration_test.gd`: logic, interaction, and persistence coverage.

---

### Task 1: Typed Item Contract and Runtime Stack

**Files:**
- Modify: `scripts/item_data.gd`
- Create: `scripts/items/item_stack_model.gd`
- Modify: `tests/run_model_tests.gd`

**Interfaces:**
- Produces: `ItemData.is_valid() -> bool`
- Produces: `ItemStackModel.setup(item: ItemData, quantity: int, durability: int = -1) -> bool`
- Produces: `ItemStackModel.create_snapshot() -> Dictionary`
- Produces: `ItemStackModel.restore_snapshot(snapshot: Dictionary, catalog: RefCounted) -> bool`

- [ ] **Step 1: Add failing model tests**

Add `_run_item_stack_model_tests()` to the test entrypoint and cover valid setup, zero quantity, stack overflow, negative weight, durability bounds, snapshot round-trip, unknown item ID, and malformed snapshots.

```gdscript
func _run_item_stack_model_tests() -> void:
	var wood := ItemData.new()
	wood.id = &"wood"
	wood.display_name = "木材"
	wood.item_type = ItemData.ItemType.MATERIAL
	wood.max_stack = 10
	wood.unit_weight = 0.5
	_assert_true(wood.is_valid(), "wood definition is valid")
	var stack: RefCounted = ITEM_STACK_MODEL_SCRIPT.new()
	_assert_true(stack.setup(wood, 4), "stack accepts a valid quantity")
	_assert_equal(stack.get_quantity(), 4, "stack exposes quantity")
	_assert_float_equal(stack.get_total_weight(), 2.0, "stack calculates total weight")
	_assert_true(not ITEM_STACK_MODEL_SCRIPT.new().setup(wood, 11), "stack rejects quantity above max")
```

- [ ] **Step 2: Run the model suite and verify the new test fails**

Run:

```powershell
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_model_tests.gd
```

Expected: failure because `ItemType.MATERIAL`, stack fields, and `ItemStackModel` do not exist.

- [ ] **Step 3: Expand the immutable item schema**

Implement these fields and validation in `scripts/item_data.gd`:

```gdscript
enum ItemType { NONE, SWORD, POTION, MATERIAL, FOOD, CONTAINER, TOOL, AMMO, EQUIPMENT }

@export_range(1, 999, 1) var max_stack: int = 1
@export_range(0.0, 999.0, 0.01) var unit_weight: float = 0.0
@export_range(0, 9999, 1) var max_durability: int = 0
@export var tags: PackedStringArray = PackedStringArray()

func is_valid() -> bool:
	return not id.is_empty() \
		and not display_name.is_empty() \
		and max_stack >= 1 \
		and is_finite(unit_weight) \
		and unit_weight >= 0.0 \
		and max_durability >= 0
```

- [ ] **Step 4: Implement `ItemStackModel`**

The model stores an `ItemData`, positive quantity no greater than `max_stack`, and `-1` durability for non-durable items. It exposes definition, quantity, available capacity, total weight, quantity mutation, duplication, and versioned snapshot methods. Snapshot output is exactly:

```gdscript
{
	"format_version": 1,
	"item_id": String(_item.id),
	"quantity": _quantity,
	"durability": _durability,
}
```

Restore resolves `item_id` through `catalog.get_item(StringName(item_id))`; it rejects missing IDs, non-integral quantity, non-finite values, incompatible durability, and any unknown field type before changing current state.

- [ ] **Step 5: Run the model suite and verify it passes**

Expected: `Model tests passed`.

- [ ] **Step 6: Commit the item contract increment**

```powershell
git add scripts/item_data.gd scripts/items/item_stack_model.gd tests/run_model_tests.gd
git commit -m "feat: add typed item stack runtime model"
```

### Task 2: Item Catalog and First Resource Content

**Files:**
- Create: `scripts/items/item_catalog.gd`
- Create: `assets/items/wood.tres`
- Create: `assets/items/stone.tres`
- Create: `assets/items/wild_food.tres`
- Create: `assets/items/scrap_parts.tres`
- Modify: `assets/items/stone_sword.tres`
- Modify: `scripts/data/content_validation_model.gd`
- Modify: `tests/run_framework_validation.gd`
- Modify: `tests/run_model_tests.gd`

**Interfaces:**
- Produces: `ItemCatalog.get_item(item_id: StringName) -> ItemData`
- Produces: `ItemCatalog.get_all_items() -> Array[ItemData]`
- Produces: `ContentValidationModel.validate_item(definition: Resource) -> PackedStringArray`

- [ ] **Step 1: Add failing catalog and validation tests**

Test all five item IDs, duplicate rejection, unknown ID returning `null`, and validation errors for empty ID, duplicate tags, non-positive stack limit, negative/non-finite weight, and stackable durable items.

- [ ] **Step 2: Run model and framework tests to confirm failure**

Expected: missing catalog, resources, and `validate_item`.

- [ ] **Step 3: Create the explicit catalog**

Use a stable path list and reject invalid or duplicate IDs during initialization:

```gdscript
const ITEM_PATHS: PackedStringArray = [
	"res://assets/items/stone_sword.tres",
	"res://assets/items/wood.tres",
	"res://assets/items/stone.tres",
	"res://assets/items/wild_food.tres",
	"res://assets/items/scrap_parts.tres",
]
```

No caller may construct a replacement `ItemData` during restore.

- [ ] **Step 4: Create the first item resources**

Use these exact first-version values:

| ID | Display | Type | Max stack | Unit weight | Tags |
|---|---|---|---:|---:|---|
| `wood` | 木材 | MATERIAL | 10 | 0.5 | `material, fuel` |
| `stone` | 石料 | MATERIAL | 10 | 0.8 | `material, mineral` |
| `wild_food` | 野生食材 | FOOD | 3 | 0.3 | `food, raw` |
| `scrap_parts` | 基础零件 | MATERIAL | 5 | 0.4 | `material, component` |
| `stone_sword` | existing name | SWORD | 1 | 2.0 | `weapon, melee` |

- [ ] **Step 5: Implement `validate_item` and register resources**

Validation must check the exact `ItemData` script identity, `is_valid()`, unique non-empty tags, and the rule `max_durability > 0 -> max_stack == 1`. Add all catalog paths to the framework validation list.

- [ ] **Step 6: Run model and framework tests**

Expected: `Model tests passed` and `Framework validation passed`.

- [ ] **Step 7: Commit item content**

```powershell
git add scripts/items/item_catalog.gd assets/items scripts/data/content_validation_model.gd tests/run_framework_validation.gd tests/run_model_tests.gd
git commit -m "feat: add initial survival item catalog"
```

### Task 3: Stacked Inventory, Weight, and Legacy Restore

**Files:**
- Modify: `scripts/items/inventory_model.gd`
- Modify: `tests/run_model_tests.gd`

**Interfaces:**
- Preserves: `add_item(item: ItemData) -> bool`
- Produces: `add_quantity(item: ItemData, quantity: int) -> bool`
- Produces: `can_add_quantity(item: ItemData, quantity: int) -> bool`
- Produces: `get_stacks() -> Array[RefCounted]`
- Preserves: `get_items() -> Array[ItemData]`
- Produces: `get_total_weight() -> float`
- Changes: `drop_selected() -> RefCounted` returns a full detached stack.

- [ ] **Step 1: Replace the two-slot legacy test with failing stack tests**

Cover merge-first behavior, overflow into a new slot, atomic failure, material stack limits, sword non-stacking, full-stack drop, total weight, eight slots, selection cycling, clear, current snapshot round-trip, schema-version-1 restore, and invalid snapshot rollback.

```gdscript
var model: RefCounted = INVENTORY_MODEL_SCRIPT.new(8, ITEM_CATALOG_SCRIPT.new())
var wood: ItemData = ITEM_CATALOG_SCRIPT.new().get_item(&"wood")
_assert_true(model.add_quantity(wood, 14), "fourteen wood fits as ten plus four")
_assert_equal(model.get_stacks()[0].get_quantity(), 10, "first stack fills first")
_assert_equal(model.get_stacks()[1].get_quantity(), 4, "overflow uses next slot")
_assert_true(not model.add_quantity(wood, 70), "insufficient space rejects the whole addition")
```

- [ ] **Step 2: Run model tests and verify failure**

Expected: current model stores one `ItemData` per slot and lacks quantity APIs.

- [ ] **Step 3: Implement quantity-aware atomic inventory rules**

Before mutation, calculate existing compatible capacity plus empty-slot capacity. Merge existing stacks in slot order, then create stacks in empty slots. `add_quantity` returns false without mutation when the entire quantity cannot fit.

`get_items()` returns each occupied stack's definition and `null` for empty slots, preserving existing combat/UI callers. `drop_selected()` removes and returns the complete stack. `drop_all()` returns all complete stacks.

- [ ] **Step 4: Version inventory snapshots**

Current snapshots use:

```gdscript
{
	"format_version": 2,
	"slot_count": _slot_count,
	"selected_slot": _selected_slot,
	"stacks": [stack_snapshot_or_empty_dictionary],
}
```

Legacy snapshots without `format_version` but with `items` are accepted as version 1. Each non-empty legacy item resolves by `id` through the catalog and restores as quantity 1. Restore validates into temporary arrays and commits only after the entire snapshot succeeds.

- [ ] **Step 5: Run model tests**

Expected: `Model tests passed`.

- [ ] **Step 6: Commit inventory rules**

```powershell
git add scripts/items/inventory_model.gd tests/run_model_tests.gd
git commit -m "feat: add stacked inventory and weight rules"
```

### Task 4: Inventory Autoload, Eight-Slot Input, and HUD

**Files:**
- Modify: `scripts/autoload/inventory.gd`
- Modify: `scripts/player/player_input_adapter.gd`
- Modify: `project.godot`
- Modify: `scenes/ui/inventory_bar/inventory_bar.gd`
- Modify: `scenes/ui/inventory_bar/inventory_bar.tscn`
- Modify: `tests/run_scene_tests.gd`

**Interfaces:**
- Produces: `Inventory.add_quantity(item: ItemData, quantity: int) -> bool`
- Produces: `Inventory.can_add_quantity(item: ItemData, quantity: int) -> bool`
- Produces: `Inventory.get_stacks() -> Array`
- Produces: `Inventory.get_slot_count() -> int`
- Produces: `Inventory.get_total_weight() -> float`
- Produces: `Inventory.reset_for_new_run() -> bool`

- [ ] **Step 1: Add failing scene assertions**

Assert base slot count 8, selection through slots 6-8, eight stable `64x64` slots, quantity labels, weight label, empty new run, no layout overflow at `1280x720`, and compatibility at the narrow `366x186` regression viewport.

- [ ] **Step 2: Run scene tests and verify failure**

Expected: current constant and input loop stop at 5; HUD has no quantity or weight labels.

- [ ] **Step 3: Update Autoload without exposing its model**

Set `SLOT_COUNT = 8`, initialize with `ItemCatalog`, add quantity/weight methods, and emit `inventory_changed(stacks: Array)` after any mutation. `reset_for_new_run()` creates a fresh eight-slot model and emits both inventory and selection signals.

- [ ] **Step 4: Add input actions 6 through 8**

Change `_get_selected_slot()` to iterate `Inventory.SLOT_COUNT`. Add `slot_6`, `slot_7`, and `slot_8` actions bound to physical number keys 6-8 in `project.godot`.

- [ ] **Step 5: Make HUD dimensions stable and quantity-aware**

Build exactly `Inventory.get_slot_count()` slots. Each slot owns an icon and bottom-right quantity label. Add a centered weight label below the row. The HUD reads definitions and quantities from `Inventory.get_stacks()` and never mutates inventory state.

- [ ] **Step 6: Run scene tests**

Expected: `Scene tests passed`; the existing ObjectDB warning may remain but exit code must be zero.

- [ ] **Step 7: Commit service and HUD**

```powershell
git add scripts/autoload/inventory.gd scripts/player/player_input_adapter.gd project.godot scenes/ui/inventory_bar tests/run_scene_tests.gd
git commit -m "feat: expand inventory HUD to eight stacked slots"
```

### Task 5: Finite Gatherable Resource Model and Scene

**Files:**
- Create: `scripts/data/world_resource_definition.gd`
- Create: `scripts/world/gatherable_resource_model.gd`
- Create: `scenes/objects/gatherable_resource/gatherable_resource.gd`
- Create: `scenes/objects/gatherable_resource/gatherable_resource.tscn`
- Create: `assets/world_resources/wood_resource.tres`
- Create: `assets/world_resources/stone_resource.tres`
- Create: `assets/world_resources/wild_food_resource.tres`
- Create: `assets/world_resources/scrap_resource.tres`
- Modify: `scripts/data/content_validation_model.gd`
- Modify: `tests/run_model_tests.gd`
- Modify: `tests/run_framework_validation.gd`

**Interfaces:**
- Produces: `WorldResourceDefinition.is_valid() -> bool`
- Produces: `GatherableResourceModel.gather_once() -> int`
- Produces: `GatherableResourceModel.create_snapshot() -> Dictionary`
- Produces scene methods: `create_snapshot() -> Dictionary`, `restore_snapshot(snapshot: Dictionary) -> bool`

- [ ] **Step 1: Add failing model and validation tests**

Cover positive base units, positive gather amount, output item validity, resource richness scaling, final partial gather, depletion, repeated gather rejection, round-trip, wrong entity ID, and malformed snapshots.

- [ ] **Step 2: Run model/framework tests and verify failure**

- [ ] **Step 3: Implement the typed definition**

Use these fields:

```gdscript
@export var id: StringName = &""
@export var display_name: String = ""
@export var output_item: ItemData
@export_range(1, 999, 1) var base_units: int = 1
@export_range(1, 999, 1) var gather_amount: int = 1
@export var display_color: Color = Color.WHITE
```

The model initializes remaining units as `maxi(roundi(base_units * difficulty_resource_richness), 1)`. `gather_once()` returns `mini(gather_amount, remaining_units)` and decrements only when positive.

- [ ] **Step 4: Implement the reusable scene adapter**

The `Area2D` exports `entity_id` and `resource_definition`, joins group `persistent_resource`, uses `InteractionInputAdapter`, checks `Inventory.can_add_quantity()` before consuming the model, then calls `Inventory.add_quantity()`. Depleted nodes hide their presenter and disable collision but remain in the tree for stable snapshot identity.

- [ ] **Step 5: Create four resource definitions**

Use base units/gather amount: wood `10/2`, stone `8/1`, wild food `6/1`, scrap `5/1`. Presentation colors are distinct muted green, gray, red-brown, and steel blue.

- [ ] **Step 6: Run model and framework tests**

Expected: both suites pass.

- [ ] **Step 7: Commit resource foundations**

```powershell
git add scripts/data/world_resource_definition.gd scripts/world/gatherable_resource_model.gd scenes/objects/gatherable_resource assets/world_resources scripts/data/content_validation_model.gd tests/run_model_tests.gd tests/run_framework_validation.gd
git commit -m "feat: add finite gatherable resource nodes"
```

### Task 6: World Placement and Resource Persistence

**Files:**
- Modify: `scenes/world/basement/basement.tscn`
- Modify: `scenes/world/cihang_outskirts/cihang_outskirts.tscn`
- Modify: `scripts/core/run_snapshot_data.gd`
- Modify: `scripts/core/run_save_model.gd`
- Modify: `scripts/autoload/game_manager.gd`
- Modify: `tests/run_scene_tests.gd`
- Modify: `tests/run_save_integration_test.gd`

**Interfaces:**
- Consumes: group `persistent_resource` and scene `create_snapshot()/restore_snapshot()`.
- Extends: `interaction_state.resource_nodes: Array[Dictionary]`.

- [ ] **Step 1: Add failing placement and persistence tests**

Assert unique stable IDs, resource counts, protected distance from spawn/exit, all four types across the first two maps, normal/hard/hell richness ordering, gather-and-deplete behavior, schema-version-1 migration, safe-exit restore, floor-boundary reset, and rejection of duplicate/unknown resource entity IDs.

- [ ] **Step 2: Run scene and save integration tests to verify failure**

- [ ] **Step 3: Place deterministic resource nodes**

Place basement nodes only on reachable interior floor and Cihang nodes across grassland, forest, and desert bands. Keep every node at least `160 px` from spawn, exits, escape materials, and fixed encounter spawns. Each instance receives a semantic ID such as `basement_wood_01` or `cihang_scrap_02`.

- [ ] **Step 4: Aggregate snapshots in `GameManager`**

Extend `_create_interaction_snapshot()` with sorted resource snapshots. Extend validation to require unique non-empty entity IDs and valid dictionaries. During `apply_pending_scene_state()`, map current resource nodes by ID, reject missing/duplicate expected entities, and restore each exact snapshot. Do not put gathering rules in `GameManager`.

- [ ] **Step 5: Migrate the top-level run schema to version 2**

Set `RunSnapshotData.CURRENT_SCHEMA_VERSION = 2` and add `SUPPORTED_SCHEMA_VERSIONS = [1, 2]`. `from_dictionary()` accepts either supported version, validates the unchanged top-level sections, and normalizes the loaded instance to version 2; inventory version-1 conversion remains owned by `InventoryModel`. `RunSaveModel` treats version-1 and version-2 invalidation markers as valid so an already settled old run cannot be resumed for duplicate rewards.

- [ ] **Step 6: Run scene and save integration tests**

Expected: `Scene tests passed` and `Run save integration test passed`.

- [ ] **Step 7: Commit world integration**

```powershell
git add scenes/world/basement/basement.tscn scenes/world/cihang_outskirts/cihang_outskirts.tscn scripts/core/run_snapshot_data.gd scripts/core/run_save_model.gd scripts/autoload/game_manager.gd tests/run_scene_tests.gd tests/run_save_integration_test.gd
git commit -m "feat: persist finite resources across safe exits"
```

### Task 7: World Item Stacks, Dropping, and Combat Compatibility

**Files:**
- Modify: `scripts/items/item_drop_service.gd`
- Modify: `scenes/objects/item_world/item_world.gd`
- Modify: `scenes/objects/item_world/item_world.tscn`
- Modify: `scenes/characters/player/player.gd`
- Modify: `tests/run_scene_tests.gd`

**Interfaces:**
- Produces: `ItemDropService.spawn_stack(parent: Node, stack: RefCounted, position: Vector2) -> ItemWorld`
- Preserves: `spawn_item(parent: Node, item: ItemData, position: Vector2) -> ItemWorld` as a quantity-one adapter.

- [ ] **Step 1: Add failing pickup/drop/death tests**

Cover picking a multi-quantity world stack, atomic failure when inventory lacks capacity, full-stack Q drop, re-pickup, sword attack through `get_selected_item()`, and death dropping every stack without quantity loss.

- [ ] **Step 2: Run scene tests to verify failure**

- [ ] **Step 3: Make `ItemWorld` quantity-aware**

Store one detached `ItemStackModel`; display its definition icon and quantity. Pickup first checks and performs complete `Inventory.add_quantity()`, then frees only on success. Its snapshot uses the stack snapshot plus position for later dynamic-drop persistence.

- [ ] **Step 4: Adapt player dropping and death**

`Inventory.drop_selected()` and `drop_all()` return stacks; player passes them to `spawn_stack()`. Attack still reads `Inventory.get_selected_item()` so stone-sword behavior remains unchanged.

- [ ] **Step 5: Run scene tests**

Expected: `Scene tests passed`.

- [ ] **Step 6: Commit world-stack compatibility**

```powershell
git add scripts/items/item_drop_service.gd scenes/objects/item_world scenes/characters/player/player.gd tests/run_scene_tests.gd
git commit -m "feat: preserve item quantities through world drops"
```

### Task 8: Full Verification, Documentation, and Plan Closure

**Files:**
- Modify: `docs/开发计划文档/计划034-物品库存与世界采集基础.md`
- Modify: `docs/开发计划文档目录.md`
- Modify: `docs/superpowers/specs/2026-08-27-survival-tuning-baseline-design.md`
- Create: `docs/任务报告/报告036-物品库存与世界采集基础.md`

**Interfaces:** None; this task closes documentation and verification.

- [ ] **Step 1: Run the complete standard validation matrix**

```powershell
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_model_tests.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/scene_test_runner.tscn
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . -s res://tests/run_framework_validation.gd
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . res://tests/run_save_integration_test.tscn
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --editor --path . --quit
& 'C:\work\project020-Afterglow\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 3
git diff --check
```

Expected: all named suites report passed, all commands exit `0`, and diff check has no output. Record the existing ObjectDB warning separately if it remains.

- [ ] **Step 2: Perform the real-play acceptance path**

Start a normal run, gather all four resources, fill and overflow stacks, verify full-inventory rejection, drop and re-pick a stack, change slots 1-8, save/quit/continue, confirm exact quantities and depleted nodes, leave and re-enter the next floor, and verify map-local resources reset only at the floor boundary.

- [ ] **Step 3: Update the tuning baseline and official plan**

Record exact stack limits, weights, eight-slot capacity, difficulty richness behavior, resource base units, snapshot version, actual validation results, and any measured interaction issues. Mark every acceptance checkbox only when verified.

- [ ] **Step 4: Write the standard task report**

Include task classification, plan paths, changed/added/deleted files, public interface changes, schema migration, all commands/results, Godot verification, diff check, risks, known ObjectDB warning, and final status.

- [ ] **Step 5: Mark plan034 complete and plan035 ready**

Update the plan index atomically: plan034 `已完成`, plan035 remains `未开始` until execution begins. Update plan033's child status table.

- [ ] **Step 6: Commit the completed first subplan**

```powershell
git add docs tests scripts scenes assets project.godot
git commit -m "feat: complete item inventory and gathering foundation"
```
