# Retro inbox

Proposals from end-of-task retrospectives (`../retro.md`). Review in batches: action the
approved ones, delete the rest.

## 2026-10-29 — side/t2
- [tool] Give `src/arena.h` a high-water mark (`peak`, kept by `arena_push`, not cleared by `arena_reset`) so arena-sizing tests can print and assert the real peak of a worst unit of work — evidence: the configured `CONSUME_SCRATCH` figure ("about 4.7 MiB") had to be estimated by hand after an improvised sed+cc bisection over arena sizes was denied; the store scratch is opaque, so its reset test can only rely on an exit — effort: S

## 2026-10-29 — side/t2 (Valkey client)
- [rule] Run container image pulls quietly (`colima nerdctl -- pull -q …`, or tail the output) — evidence: one `nerdctl pull` printed ~30 redrawn progress frames into the transcript, several thousand tokens for one digest line — effort: S

## 2026-10-30 — side/t2 (Valkey bench)
- [doc] For any network benchmark against a service under colima, note that client-side timings go through the VM's port forward and must not be the reported figure: run the client in a container on the compose network, or use the server's own counters — evidence: bench_valkey's PING ranged 666–1865 µs across three runs, each run's 99% CI within ±2%, so the first results table had to be rebuilt on `INFO commandstats` — effort: S


## 2026-11-02 — side/t2 (docs: write/read path)
- [rule] When the code contradicts what the user or the docs say about a component, report the contradiction and ask before editing docs to match either side — evidence: the docs and the user both called cbr Camel, cbr's source is plain JMS; I began rewriting core-flow §11.6 to describe the code without flagging it, and the edit was rejected mid-batch — effort: S
