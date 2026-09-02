# Plan 035 Implementation: Food, Water, Containers, and Disease

## Goal

Turn the existing hunger/water timers into atomic, quantity-aware consumption and status effects while keeping all rules in typed domain models.

## Ordered increments

1. Add food, water, disease, and container item definitions plus failing model tests.
2. Implement `SurvivalConsumptionModel` for food/water use, overflow waste, disease rolls, and duration refresh.
3. Implement `WaterContainerModel` for 1/3/5-unit containers, source type, purity, mixing rejection, transfer, and snapshots.
4. Add inventory use commands and GameManager coordination; preserve existing survival tick and random-stream boundaries.
5. Add deterministic starting water/empty-container and food resource placements, then cover reachability and difficulty rates in scene tests.
6. Extend run snapshots with consumption/container/disease state and legacy defaults; cover safe-exit restore and invalid rollback.
7. Run full validation, update tuning/plan/report, and close plan035 only after all acceptance checks pass.

## Constraints

- No new Autoload; Inventory remains item ownership and GameManager remains cross-scene coordinator.
- Consumption is atomic: state changes and stack removal commit together or neither changes.
- Water containers are runtime stacks with explicit source/purity state; raw and purified water cannot mix.
- Disease never stacks; a new infection refreshes duration and uses the run random stream.
- Static `.tres` resources never hold current quantity or disease state.
