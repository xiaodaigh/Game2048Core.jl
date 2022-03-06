# Game2048Core.jl

This is a minimalist implementation of the game 2048. The aim is to have a high-performance backbone. So there aren't any visual components to play the game.

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
 1  2  4  1
 4  5  1  3
 3  7  2  1
 1  3  4  2
```





## Performance

```julia
using BenchmarkTools

b = initbboard()

@benchmark move($b, $left)
```

```
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  3.400 ns … 46.900 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     3.400 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   3.480 ns ±  0.708 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █                           █                               
  █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▂ ▂
  3.4 ns         Histogram: frequency by time         3.6 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```



```julia
@benchmark move($b, $right)
```

```
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  2.700 ns … 29.200 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     2.800 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   2.796 ns ±  0.552 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▇                  █                                     ▁ ▁
  █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▇▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█ █
  2.7 ns       Histogram: log(frequency) by time        3 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```



```julia
@benchmark move($b, $up)
```

```
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  4.500 ns … 38.900 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     4.600 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   4.630 ns ±  0.833 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▅          █           ▁                                   ▁
  █▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▅▁▁▁▁▁▁▁▁▁▁▄ █
  4.5 ns       Histogram: log(frequency) by time        5 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```



```julia
@benchmark move($b, $down)
```

```
BenchmarkTools.Trial: 10000 samples with 1000 evaluations.
 Range (min … max):  4.800 ns … 38.800 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     4.800 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   4.872 ns ±  0.913 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █                  ▆                  ▁                    ▁
  █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁█▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▇ █
  4.8 ns       Histogram: log(frequency) by time      5.1 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.
```



```julia
@benchmark simulate_bb($board)
```

```
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):   2.800 μs …  3.577 ms  ┊ GC (min … max): 0.00% … 98.69
%
 Time  (median):     11.200 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   12.377 μs ± 36.046 μs  ┊ GC (mean ± σ):  2.85% ±  0.99
%

           ▂▃▇▄▃▆▄▅▅█▅▇▅▇▂▂▁                                   
  ▁▁▁▂▃▃▄▇██████████████████▇▆▇█▆▇▆█▅▅▅▃▃▂▃▂▂▂▂▂▂▂▂▁▁▂▁▁▁▁▁▁▁ ▄
  2.8 μs          Histogram: frequency by time          28 μs <

 Memory estimate: 2.58 KiB, allocs estimate: 33.
```



```julia
@benchmark simulate_bb()
```

```
BenchmarkTools.Trial: 10000 samples with 3 evaluations.
 Range (min … max):   4.900 μs …  1.096 ms  ┊ GC (min … max): 0.00% … 98.41
%
 Time  (median):     10.350 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   11.232 μs ± 21.695 μs  ┊ GC (mean ± σ):  3.80% ±  1.97
%

               ▂▄▄▄█▆█▆▇█▇▅▄▄▃▃▃                               
  ▁▁▁▁▁▂▃▃▄▅▆█████████████████████▇▇▆▇▅▅▄▄▃▄▃▃▃▂▂▂▂▂▂▂▂▂▁▁▂▁▁ ▄
  4.9 μs          Histogram: frequency by time          19 μs <

 Memory estimate: 4.53 KiB, allocs estimate: 58.
```



```julia
@benchmark randmove($board)
```

```
BenchmarkTools.Trial: 10000 samples with 990 evaluations.
 Range (min … max):  46.566 ns …   3.521 μs  ┊ GC (min … max): 0.00% … 97.9
2%
 Time  (median):     47.879 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   56.294 ns ± 116.969 ns  ┊ GC (mean ± σ):  7.40% ±  3.5
2%

  ▆█▄▂▃▂▂▂▁▁▁              ▂▂       ▁▂▁                        ▁
  █████████████▇▇▆▆▆▆▇▅▆▆▅▇██▇▇▆▆▆▆█████▇▆▄▄▅▄▅▅▃▄▅▅▄▃▃▃▄▄▃▃▃▄ █
  46.6 ns       Histogram: log(frequency) by time      96.8 ns <

 Memory estimate: 80 bytes, allocs estimate: 1.
```


