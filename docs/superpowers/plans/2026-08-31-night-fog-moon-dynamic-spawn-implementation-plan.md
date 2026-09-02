# Plan 037 Implementation: Night Fog, Moon Phases, and Dynamic Spawning

## Ordered increments

1. Add typed night fog phase, seven-night moon cycle, and darkness mark models.
2. Add dynamic spawn director with weighted candidates, protection checks, wave timing, and budget release.
3. Connect world scenes to fog/moon presentation and dynamic spawn points without affecting fixed objectives.
4. Persist fog, moon, mark, spawn timer, and dynamic enemy budget state through safe-exit snapshots.
5. Run a complete day/night regression and close plan037 only after all acceptance criteria pass.

## Current increment

- Plan037 has started after plan036 completion.
- Existing survival clock, spawn protection, threat budget, encounter controller, and deterministic enemy-spawn random stream are preserved as dependencies.
