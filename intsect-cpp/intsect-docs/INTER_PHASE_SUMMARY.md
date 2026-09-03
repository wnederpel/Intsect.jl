# Inter-phase summary - perft, move generation, and engine integration

This document records the work between the completed board-state phase and the next major
engine phase. The edits began as a perft cleanup, but expanded into the first usable slice of
legal-action generation and the supporting CLI/test infrastructure.

## Scope delivered

- Added legal action generation for the current game state:
  - queen-enforcement placement
  - first and second placement turns
  - normal placements
  - queen, ant, spider, grasshopper, beetle, ladybug, pillbug, and mosquito movement
  - pillbug and mosquito throws
  - pass when no other action is available
- Preserved the Julia move-ordering conventions used by the C++ parity tests.
- Added a fixed-size `ActionArraySink` backed by `std::array<Action, VALID_BUFFER_SIZE>`.
  The hot-path `get_valid_actions_into()` API writes actions directly into the caller's buffer
  without a temporary vector or per-call heap allocation.
- Returned `get_valid_actions()` to a convenience API: it uses the same fixed buffer internally
  and returns a vector containing only the generated prefix.
- Kept action-buffer indexing zero-based in C++, with `Board::action_index` representing the
  next write position and, after generation, the action count.
- Added move-generation workspace storage and caches to the existing board path where needed by
  ant reachability and pinned-piece detection.

## Perft and build architecture

- Changed recursive `perft()` to take `Board&` and explore actions through do/undo instead of
  copying the board at every recursive call.
- Fixed `perft_with_output()` to report each requested depth rather than recomputing the final
  depth repeatedly.
- Moved recursive perft implementations from the public include directory into
  `intsect-engine/src/perft.cpp` and added that source file to the engine target. The header now
  contains declarations only.
- Added a CLI `perft` command for running perft from the current loaded game.
- Extended game-string parsing so a full GameString can be loaded by replaying its actions.

## Tests and verification

The C++ debug configuration uses Clang with warnings-as-errors, AddressSanitizer, and
UndefinedBehaviorSanitizer. The move-generation test suite now covers ordering, placement rules,
piece-specific movement, special moves, edge wrapping, pinned pieces, pass-only positions, and
stacked-piece behavior.

Latest verification:

```
77 test cases passed
1736 assertions passed
```

## Remaining boundaries

- Search, evaluation, and the UHP `bestmove` command remain future work.
- The CLI `validmoves` command is still not implemented; the underlying generation API now exists.
- The fixed action buffer assumes the configured `VALID_BUFFER_SIZE` is sufficient for every legal
  position. This should remain an explicit invariant or gain a checked failure path before the
  engine is exposed to arbitrary positions.

## Next phase direction

Use the validated action-generation API as the foundation for search/perft optimization, then
connect it to evaluation, move ordering, and the remaining CLI commands. Keep recursive or
translation-unit-sized implementations in `.cpp` files and reserve fixed buffers for hot paths.
