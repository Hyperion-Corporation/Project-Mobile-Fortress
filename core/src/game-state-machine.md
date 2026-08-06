# Shared game state machine (spec, not code)

Both clients implement this same state shape independently — see
[`core/README.md`](../README.md) for why there's no compiled shared module
yet. If you change one client's states/transitions, mirror it here and in
the other client.

## States

| State | Android (`GameEngine`/`GameState`) | iOS (`GameManager.GameStateKind`) |
| --- | --- | --- |
| Menu | *(implicit: no `GameView` attached)* | `.menu` |
| Playing | `GameView` attached, `GameLoop.running == true` | `.playing` |
| Paused | `GameLoop.running == false`, state retained | `.paused` |
| Game Over | *(not yet modeled — Android has no scoring-end condition today)* | `.gameOver(score:)` |

## Transitions

```
Menu    --startNewGame()--> Playing
Playing --pause()---------> Paused
Paused  --resume()--------> Playing
Playing --endGame()-------> GameOver
GameOver--returnToMenu()--> Menu
```

## Known asymmetry

Android's `GameEngine` currently only tracks a single bouncing `Ball` and has
no win/lose condition, so it has no real "Game Over" state yet — the table
above marks that explicitly rather than pretending parity that doesn't exist.
Bringing Android's state machine to full parity with iOS's is tracked in
[`moon/roadmaps/shared_core.md`](../../docs/moon/roadmaps/shared_core.md).
