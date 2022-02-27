# Game2048Core.jl

This is meant to be a minimalist implementation of the game 2048 aimed at performance but without
any visual components. To play the game of

The original intention of the repos is to use it to develop Reinforcement Learning algorithms with
2048.

## The environment

The board is represented by a `UInt64` value.

I did not use any RL environment framework. But here's how you can play with it.

```julia
using Game2048Core: initbboard, add_tile, move, left, right, up, down, randmove, simulate_bb
import Game2048Core as g

# obtain a new board with 2 tiles populated
board = initbboard()

# you can move left right up or down
old_board = board
new_board = move(board, g.left)

if board != old_board
    # this will add a new tile on the board
    board = add_tile(new_board)
end

# make a random move
randmove(board)

# simulate the game til the end using purely random moves
simulate_bb(board)
```

```
4×4 Matrix{Int8}:
 1  4  2  5
 2  5  4  2
 4  3  6  3
 2  1  3  1
```





## Performance

```julia
using BenchmarkTools

b = initbboard()

@benchmark move($b, $left)
```

```
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  2.900 ns … 58.800 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     3.000 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   3.059 ns ±  1.156 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▅                  █                  ▂                    ▁
  █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▇ █
  2.9 ns       Histogram: log(frequency) by time      3.2 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```



```julia
@benchmark move($b, $right)
```

```
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  2.900 ns … 62.200 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     3.000 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   3.070 ns ±  1.197 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▄             █              ▂                             ▁
  █▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▄▁▁▁▁▁▁▁▁▁▁▁▁▁▅ █
  2.9 ns       Histogram: log(frequency) by time      3.3 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```



```julia
@benchmark move($b, $up)
```

```
BenchmarkTools.Trial: 10000 samples with 982 evaluations.
 Range (min … max):  68.126 ns …   3.635 μs  ┊ GC (min … max):  0.00% … 97.
46%
 Time  (median):     70.774 ns               ┊ GC (median):     0.00%
 Time  (mean ± σ):   83.005 ns ± 154.008 ns  ┊ GC (mean ± σ):  10.04% ±  5.
29%

  ▇▇█▅▄▃▄▃▂          ▁▁▃▁                                      ▂
  ████████████▆▇▇▇▇▆▇████▇▆▆▆▅▆▅▅▅▅▆▆▅▅▅▇█▇▆▆▆▆▆▅▅▄▅▅▄▂▄▅▄▄▃▅▃ █
  68.1 ns       Histogram: log(frequency) by time       136 ns <

 Memory estimate: 144 bytes, allocs estimate: 3.
```



```julia
@benchmark move($b, $down)
```

```
BenchmarkTools.Trial: 10000 samples with 978 evaluations.
 Range (min … max):  67.485 ns …   3.456 μs  ┊ GC (min … max):  0.00% … 96.
25%
 Time  (median):     69.018 ns               ┊ GC (median):     0.00%
 Time  (mean ± σ):   82.415 ns ± 156.594 ns  ┊ GC (mean ± σ):  10.27% ±  5.
29%

  █▆▄▄▄▂        ▂                                              ▁
  ███████▇▆▇▇▇▇███▇▇▇▅▆▅▆▆▆▆▆▆▇▇▇▇▇▆▅▅▄▅▅▅▅▅▅▃▅▅▄▄▄▂▄▃▄▄▂▄▃▃▄▄ █
  67.5 ns       Histogram: log(frequency) by time       160 ns <

 Memory estimate: 144 bytes, allocs estimate: 3.
```



```julia
@benchmark simulate_bb($board)
```

```
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):   4.500 μs …   5.648 ms  ┊ GC (min … max):  0.00% … 99.
31%
 Time  (median):     15.300 μs               ┊ GC (median):     0.00%
 Time  (mean ± σ):   18.033 μs ± 100.787 μs  ┊ GC (mean ± σ):  11.05% ±  1.
98%

            ▂▆▅██▆▄▆▅▆▄▅▅▆▇▆▆▅▄▁                                
  ▁▁▂▃▃▄▅▅▆███████████████████████▅▆▆▆▅▅▄▄▄▄▄▃▃▃▃▂▂▂▂▂▂▂▂▁▂▁▂▂ ▅
  4.5 μs          Histogram: frequency by time         34.2 μs <

 Memory estimate: 5.27 KiB, allocs estimate: 89.
```



```julia
@benchmark simulate_bb()
```

```
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):   4.400 μs …  5.255 ms  ┊ GC (min … max):  0.00% … 98.9
0%
 Time  (median):     15.600 μs              ┊ GC (median):     0.00%
 Time  (mean ± σ):   18.976 μs ± 96.245 μs  ┊ GC (mean ± σ):  10.02% ±  1.9
8%

        ▃▆▇▇▅▆▆▅█▇▆▂▁                                          
  ▁▂▃▄▆▇██████████████▅▅▅▄▅▄▃▃▃▂▂▂▂▂▂▂▂▂▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▃
  4.4 μs          Histogram: frequency by time        52.8 μs <

 Memory estimate: 5.16 KiB, allocs estimate: 84.
```



```julia
@benchmark randmove($board)
```

```
BenchmarkTools.Trial: 10000 samples with 957 evaluations.
 Range (min … max):   90.491 ns …   6.144 μs  ┊ GC (min … max):  0.00% … 97
.90%
 Time  (median):      97.074 ns               ┊ GC (median):     0.00%
 Time  (mean ± σ):   123.171 ns ± 301.141 ns  ┊ GC (mean ± σ):  14.07% ±  5
.75%

  ▂▇█▇▆▅▄▃▃▂▂▁▁▁▁ ▁▃▃▂▁                                         ▂
  ████████████████████████▇▇▇█▇█▇▇▆▇▆▆▅▆▆▅▆▅▅▅▅▅▆▅▅▅▄▆▆▄▅▅▅▄▁▅▆ █
  90.5 ns       Histogram: log(frequency) by time        228 ns <

 Memory estimate: 166 bytes, allocs estimate: 2.
```


