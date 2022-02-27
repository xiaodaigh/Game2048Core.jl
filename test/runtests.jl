using Game2048Core
using Test

@testset "Game2048Core.jl" begin
    bitboard = initbboard()

    move(bitboard, up)
    move(bitboard, down)
    move(bitboard, left)
    move(bitboard, down)

    simulate_bb(bitboard)

    simulate_bb()
end
