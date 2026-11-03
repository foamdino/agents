---
name: benchmark-checklist
description: Vet a performance number before reporting or acting on it. Use when you run a benchmark, or report a speedup or regression you measured.
---

# Benchmark checklist

Answer each question with evidence from a run, not a guess from reading the code.
For a quick ballpark I asked for, one run is enough: still check 4 and 7, and say it is one
run. A choice between options is never a ballpark.

## Before running

- Write the claim you expect to make, in the words you would report it
  ("p50 round 41 → 33 µs, 32 facts of 64 KiB"). The questions test that sentence.
- Read the measurement code: what it times, counts, and ignores.
- Check load (`uptime`) and cores (`nproc` / `sysctl -n hw.ncpu`). If the machine is busy
  and you can't stop it, interleave the sides and say so.

## Questions

1. **Why not double?** Name the limiter (a core, a lock, the disk, the network, a VM port
   forward, the load generator itself) from a profile or system counters, mapped to source.
   Profile in a run you don't report. Linux: `perf`, `pidstat`, `strace -c`.
   macOS: `sample`, Instruments, `top`. If you can't name it, you don't know what you measured.
2. **Was it tuned?** Every side as production runs it: release build, same flags, batching,
   pools, warm/cold caches, versions, data. One side on defaults compares configurations,
   not implementations; don't pick a winner from that run.
3. **Did it break limits?** Do the arithmetic: bytes/s vs disk and network bandwidth, ops/s ×
   cost/op vs cores, time saved vs the time the changed piece took. Removing 10% of a run
   makes it at most ~11% faster. Past a limit, you measured a cache, a no-op, or a bug.
4. **Did it error?** Count failures and non-success replies; check outputs are correct, not
   just present. Rejections are fast, timeouts slow. If the harness doesn't count errors, add it.
5. **Does it reproduce?** At least 5 runs per side, alternating A B A B. Report median and
   range. A gap smaller than run-to-run spread is no measurable difference.
6. **Does it matter?** Next to a micro result, measure the end-to-end path at realistic size
   and concurrency, and give the micro result as a share of it.
7. **Did it happen?** Confirm the work ran inside the timed region: the request reached the
   server, the rows were written, the result was used.

## Report

- Lead with the verdict: faster, slower, no measurable difference, or inconclusive.
- Number with unit, run count, range, limiter: "p50 41 → 33 µs, median of 7 per side,
  range 32–35 µs, bound by JSON parsing on one core".
- Inconclusive when you can't name the limiter, a side ran untuned, or 4 and 7 are unchecked.
  Name the gap.

---
Adapted from pstack's `benchmark-checklist` (Lauren Tan, MIT,
github.com/backnotprop/pstack). Method follows Brendan Gregg's active benchmarking
and USE method (brendangregg.com).
