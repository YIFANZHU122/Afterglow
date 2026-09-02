# Plan 036 Implementation: Crafting, Campfires, Torches, and Basic Buildings

## Ordered increments

1. Add typed `RecipeIngredient`/`RecipeDefinition` resources and validate material, station, time, and intelligence constraints.
2. Add `CraftingModel` and inventory material APIs with lock-on-start, interruption refund, completion output, and failure-path tests.
3. Add fire source domain model: fuel, stability, light radius, ignition, extinguish, rain multipliers, respawn point, and snapshot.
4. Add torch runtime model and fire/torch scene interaction, including lighter and campfire ignition.
5. Add one-slot cooking and one-slot purification jobs using the crafting/workstation boundary.
6. Add minimal rain shelter and wooden wall placement with collision, health, and snapshot integration.
7. Run the complete verification matrix, record tuning values, and close plan036 only after the full采集 -> 制作 -> 点火 -> 加工 flow passes.

## Completion

- All seven increments are implemented and covered by model, scene, save, framework, editor, and launch verification.
- Processing workstations support concurrent cooking/purification with stable slot locking, interruption, and snapshot restore.
- Campfire and torch scene interactions are proximity-gated and expose runtime light, ignition, fuel, and processing state.
- Rain shelter and wooden wall provide collision, placement bounds, health, and JSON-safe snapshot restore.
- Formal Plan036 recipes and output item resources are registered in the item catalog and covered by content tests.
