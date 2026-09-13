# GRIM Questions

Add new problems below using `## Title` as the delimiter.
Each `## Title` starts a new question. Everything until the next `##` belongs to that question.
Edit this file without touching application code.

---

## XOR-AND Inversions

You are given an array `A` of `N` non-negative integers.

Count the number of pairs `(i, j)` such that `i < j` and

```
(A[i] XOR A[j]) < (A[i] AND A[j])
```

**Input format**

- First line: integer `N` — size of the array (`1 <= N <= 2*10^5`)
- Second line: `N` space-separated integers `A[i]` (`0 <= A[i] <= 10^9`)

**Output format**

- Single integer: the number of valid pairs. The answer may exceed 32-bit; use 64-bit.

**Constraints**

- `N` up to `2*10^5`, so `O(N^2)` is too slow.
- `A[i]` up to `10^9` (up to 30 bits).

**Examples**

```
Input:
5
4 8 2 6 1

Output:
2
```

Explanation: valid pairs are (4,6) and (2,6) under the given condition (verify by computing XOR and AND).

```
Input:
3
0 0 0

Output:
0
```

```
Input:
4
7 7 7 7

Output:
0
```

**Notes**

- XOR is bitwise exclusive-or, AND is bitwise and.
- Think about the most significant bit where two numbers differ. How do XOR and AND behave at that bit?
- Expected complexity: `O(N log MAX)` or `O(N * B)` where `B <= 30`.

---

## Token Bucket Rate Limiter

Design and implement a token-bucket rate limiter for an API gateway.

There is a bucket with capacity `C` tokens. It starts full. Tokens refill at rate `R` tokens per second (continuous, not discrete ticks). Each incoming request at timestamp `t` (seconds, floating point) consumes 1 token if available; otherwise it is rejected.

You are given:

- `C` (integer, 1 <= C <= 10^6)
- `R` (float, 0.1 <= R <= 10^4)
- `N` requests with strictly increasing timestamps `t[0..N-1]` (0 <= t[i] <= 10^9, N up to 10^6)

For each request in order, output `1` if allowed, `0` if rejected.

**Input format**

```
C R
N
t1
t2
...
tN
```

Or: first line `C R`, second line `N`, then `N` lines each with a timestamp. Timestamps are given with up to 3 decimal places.

**Output format**

- Single line with `N` characters (`0`/`1`) or `N` space-separated values — either is accepted.

**Examples**

```
Input:
2 1
5
0.0
0.1
0.6
1.1
1.2

Output:
1 1 0 1 0
```

**Constraints / Hints**

- Do not simulate per-millisecond. Compute refill as `elapsed * R`.
- Watch floating-point accumulation; prefer integer microsecond arithmetic or careful epsilon handling.
- Cap tokens at `C`.

---

## Log Compaction — Eventual Consistency

A distributed log receives writes of the form `(key, value, timestamp)`. Writes may arrive out of order. Compaction keeps only the latest write per key (largest timestamp; if tied, latest arrival wins — but you process in given order, so last occurrence of max timestamp wins).

You are given `N` writes in arrival order. After processing all `N`, output the compacted state sorted by key lexicographically.

**Input format**

- First line: `N` (1 <= N <= 5*10^5)
- Next `N` lines: `key value timestamp` where `key` is alphanumeric ` [a-z0-9_]` length 1..32, `value` is string without spaces length 1..64, `timestamp` is integer `0 <= ts <= 10^12`

**Output format**

- For each distinct key, one line: `key value timestamp` — sorted by key ascending (lexicographic, ASCII).

**Examples**

```
Input:
6
user:1 alice 100
user:2 bob 90
user:1 carol 120
user:2 dave 95
user:1 eve 120
user:3 frank 10

Output:
user:1 eve 120
user:2 dave 95
user:3 frank 10
```

**Constraints**

- Keys up to 5*10^5 distinct.
- Expected `O(N log N)` or `O(N)` with hash map + sort.

---

## Dependency Build Order

A build system has `N` modules `0..N-1` and `M` directed dependencies `u -> v` meaning `u` must be built before `v`. Determine a valid build order or report that none exists.

If multiple valid orders exist, return the lexicographically smallest (compare as sequence; smallest at first differing position).

**Input format**

- First line: `N M` (1 <= N <= 10^5, 0 <= M <= 2*10^5)
- Next `M` lines: `u v` (0 <= u,v < N, u != v). Graph may contain duplicates — treat as single edge.

**Output format**

- If acyclic: single line with `N` space-separated module ids in build order.
- If cyclic: single line `IMPOSSIBLE`

**Examples**

```
Input:
4 3
0 1
0 2
1 3

Output:
0 1 2 3
```

```
Input:
3 3
0 1
1 2
2 0

Output:
IMPOSSIBLE
```

```
Input:
4 2
1 0
2 0

Output:
1 2 0 3
```

Explanation last case: valid orders include `[1,2,0,3]`, `[1,2,3,0]`, `[2,1,0,3]` ... lexicographically smallest is `[1,2,0,3]`.

**Constraints**

- Need `O((N+M) log N)` with min-heap Kahn's algorithm. Plain queue is not sufficient for lexicographically smallest.

---

## Sliding Window Aggregator

Given an array `A` of `N` integers and window size `K`, for each window `A[i .. i+K-1]` (0 <= i <= N-K) output two values:

1. The `minimum` of the window
2. The `maximum` of the window

Additionally, the assessment expects you to discuss handling of:

- `K == 1` and `K == N`
- Duplicate values
- Streaming / online version where you cannot revisit old elements

**Input format**

- First line: `N K` (1 <= K <= N <= 10^6,  -10^9 <= A[i] <= 10^9)
- Second line: `N` integers

**Output format**

- `N-K+1` lines, each: `min max`

**Examples**

```
Input:
8 3
1 3 -1 -3 5 3 6 7

Output:
-1 3
-3 3
-3 5
-3 5
3 6
3 7
```

**Constraints**

- `O(N log K)` with heap is borderline. Expected `O(N)` with monotone deques.
- Memory `O(K)`.

---

## Concurrent Counter — Lost Updates

You are given a log of `N` operations on a shared counter that is incremented by multiple threads without synchronization. Each operation is recorded as `(thread_id, read_value, write_value)` in global time order.

A correct synchronized increment would be `write_value == read_value + 1` and strictly increasing globally. A lost update occurs when two threads read the same value and both write `value+1`, so one increment is lost.

Formally, define the counter's true linearizable history: start at `0`. Each operation `op_i` is *valid* if `read_value == current_true_value` at that point; then `current_true_value = write_value`. If `read_value != current_true_value`, the operation is a *lost-update* anomaly — it overwrites a concurrent increment.

Count how many operations are anomalies. Also output the final true counter value if all valid increments had been serialized correctly (i.e., count of valid ops).

**Input format**

- First line: `N` (1 <= N <= 10^6)
- Next `N` lines: `thread_id read_value write_value` (thread_id string without spaces, values `0 <= v <= 10^9`)

**Examples**

```
Input:
5
t1 0 1
t2 0 1
t1 1 2
t2 1 2
t1 2 3

Output:
anomalies: 2
final: 3
```

Explanation: operations 2 and 4 are anomalies (read stale 0 and 1 respectively).

**Constraints**

- Must process in given order; do not reorder.
- `O(N)` time, `O(1)` extra.

