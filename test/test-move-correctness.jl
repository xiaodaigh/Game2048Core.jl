# refer to benchmarks/array-board/run-benchmarks.jl
using Game2048Core
using Game2048Core: bitboard_to_array, move!

function ok()
    for _ in 1:1_000_000
        bboard = Bitboard(rand(UInt64))
        arr_board = bitboard_to_array(bboard)
        if any(arr_board .== 15)
            break
        end

        new_board = move(bboard, left)


        move!(arr_board, left)

        if  !(bitboard_to_array(new_board) == arr_board)
            return bboard
        end
    end
end

@time a = ok()

move(a, left)
b = bitboard_to_array(a)
move!(b, left)

b

