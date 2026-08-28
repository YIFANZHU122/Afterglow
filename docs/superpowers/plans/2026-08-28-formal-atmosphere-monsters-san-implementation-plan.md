# Formal Atmosphere, Rift Animals, Pollution and SAN Implementation Plan

## Task 1: Plan and test seams

- [x] Add focused assertions for sky, weather effect nodes, anomaly and SAN query methods.
- [x] Add a dedicated presenter test scene and verify RED before production changes.

## Task 2: Formal sky and weather presentation

- [x] Extend `WorldEnvironmentPresenter` with sky, horizon, audio, post-process and deterministic anomaly/SAN methods.
- [x] Keep existing weather queries and disaster mappings backward compatible.
- [x] Verify focused test and all three world scenes.

## Task 3: Rift animal presentation

- [x] Add project-owned SVG silhouette asset and `RiftAnimalPresenter`.
- [x] Replace chaser presenter script while preserving `ActorPresenter` contract.
- [x] Add scene assertions for the new presenter and animation nodes.

## Task 4: Parasitic flower variants

- [x] Add one reusable flower scene with three exported visual variants.
- [x] Place a small number of decorative instances in Cihang outskirts.
- [x] Verify they are not encounter members and animate without gameplay coupling.

## Task 5: Final anomaly and SAN pass

- [x] Add abnormal moon/polluted sky overlays and SAN vignette/chromatic feedback.
- [x] Cover intensity clamping and invalid anomaly fallback.
- [x] Run the complete validation matrix and write report 024.
