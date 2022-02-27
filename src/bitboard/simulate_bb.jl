export simulate_bb

"""
Makes a random move. It does NOT add a new tile
"""
function randmove(bitboard::Bitboard)::Bitboard
    dirs = collect(DIRS)

    for i in 4:-1:1
        j = rand(1:i)
        dir = dirs[j]
        new_bitboard = move(bitboard, dir)
        if new_bitboard != bitboard
            return new_bitboard
        end
        dirs[j] = dirs[i]
    end
    return bitboard
end

"""
Simulate a game given the bitboard state till the end
"""
function simulate_bb(bitboard::Bitboard=initbboard())
    while true
        new_bitboard = randmove(bitboard)
        if new_bitboard != bitboard
            bitboard = add_tile(new_bitboard)
            @assert bitboard != new_bitboard
        else
            # lost if no move can be made
            return bitboard
        end
    end
end




