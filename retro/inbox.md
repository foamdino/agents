# Retro inbox

Proposals from end-of-task retrospectives (`../retro.md`). Review in batches: action the
approved ones, delete the rest.

## 2026-10-29 — side/t2
- [tool] Give `src/arena.h` a high-water mark (`peak`, kept by `arena_push`, not cleared by `arena_reset`) so arena-sizing tests can print and assert the real peak of a worst unit of work — evidence: the configured `CONSUME_SCRATCH` figure ("about 4.7 MiB") had to be estimated by hand after an improvised sed+cc bisection over arena sizes was denied; the store scratch is opaque, so its reset test can only rely on an exit — effort: S

