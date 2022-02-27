module Game2048Core

export Dirs, left, right, up, down, move!, move, Bitboard

@enum Dirs left up right down

const DIRS = (left, up, right, down)

# Vector{Dirs}(init_len) = [left for _ in 1:init_len]

# Do NOT delete; this is used to generate the LEFT RIGHT movement lookup tables
include("uint_board/move-up.jl")
include("uint_board/move-board.jl")
include("uint_board/sim-game.jl")

include("rotate-mirror.jl")

include("bitboard/make_lookups.jl")
include("bitboard/bitboard.jl")
include("bitboard/simulate_bb.jl")
# include("bitboard/playahead.jl")
# include("bitboard/fingerprint.jl")

end