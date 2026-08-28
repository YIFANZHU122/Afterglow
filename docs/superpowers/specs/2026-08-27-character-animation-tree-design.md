# Character AnimationTree Design

## Goal

Use Godot's `AnimationPlayer + AnimationTree` to present player animation while preserving the existing `ActorPresenter` semantic boundary and all gameplay behavior.

## Current State

The player scene owns an `AnimatedSprite2D` and injects `GrayboxActorPresenter`. Movement selects the four `SpriteFrames` animations directly through the Presenter, while attack and hit feedback use tweens. The player gameplay script still reaches into the visual node to hide and show it during death and revive.

## Selected Approach

Use the existing `Presenter` child as the replaceable presentation root. It owns:

- `AnimatedSprite2D` for the current four-direction sprite sheet.
- `AnimationPlayer` for authored idle, movement, attack, hit, and death clips.
- `AnimationTree` with an `AnimationNodeStateMachine` for semantic state selection.
- `AnimationTreeActorPresenter` for translating `set_movement`, `play_attack`, `play_hit`, and `set_dead` into state-machine playback.

The player gameplay script continues to call only the semantic Presenter methods. It will no longer reference `AnimatedSprite2D`, animation names, state-machine node names, or animation node paths.

## State Model

The semantic state machine contains `Idle`, `Move`, `Attack`, `Hit`, and `Dead`. The latest non-zero direction is retained as facing and mapped inside the Presenter to the existing `down`, `left`, `right`, and `up` SpriteFrames animations. Zero movement selects `Idle` without losing the retained facing direction.

`Attack` and `Hit` are transient states. When their non-looping clips finish, the Presenter returns to the current locomotion base state. `Dead` has priority over movement and transient feedback; while dead, movement, attack, and hit requests do not replace it. Revive restores visibility and the current idle state.

The first iteration intentionally reuses the available walk sheet. Idle uses its center frame, movement cycles the three frames, and attack/hit use short color feedback. Replacing these clips with formal art remains isolated inside the presentation scene.

## Compatibility

The public `ActorPresenter` methods remain unchanged. `GrayboxActorPresenter` remains available for enemies and fallback content. No gameplay state, resource schema, Autoload, input mapping, save data, or future-network command boundary changes.

## Validation

Scene tests verify the player owns `AnimationPlayer` and active `AnimationTree` nodes, starts idle, maps movement direction, returns to idle when input stops, handles transient attack/hit states, and enforces death priority. Standard model, scene, framework, editor-load, and main-scene headless checks remain required.
