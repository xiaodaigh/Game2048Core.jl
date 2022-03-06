export move, add_tile, show, initbboard, move_and_reward, score

import Base.show, Base.display, Base.maximum

const ROWMASK = UInt16(2^16 - 1)
const CELLMASK = UInt16(2^4 - 1)
const MASK = UInt8(15)

"""
Bsed on the benchmarks I have done. It's quicker to precompute the results for all rows and make a
set of lookup table that looks up the result of moving left or right.

One of the Rust repositories have taken this approach.
"""
const LEFT, LEFT_REWARD, RIGHT, RIGHT_REWARD = make_row_lookup()

"""
A gameboard is stored on a UInt (64bit)
where each row (TODO shall I make it column major) is stored using 16 bits. So 4 bits for each cell.
So each cell can contain values form 0-15. 2^15 = 32678 and 2^11 is 2048. So it's there's plenty of
room
"""
struct Bitboard
    board::UInt64
end


"""
initialise a bitboard
"""
function initbboard()
    zero(UInt64) |> Bitboard |> add_tile |> add_tile
end

"""
    board2cols(board::UInt64)::Vector{Vector{UInt16}}


Return the columns from a board
"""
function board2cols(bitboard::Bitboard)::Vector{UInt16}
    board = bitboard.board
    # initialise the columns
    cols = zeros(UInt16, 4)

    # take one row at a time
    for row_shift in 48:-16:0
        row = (board >> row_shift) & ROWMASK

        # populate the right cell for each column
        @inbounds for i in 4:-1:1
            cols[i] <<= 4 # doing this here effectively means each col only gets shifted 3 times
            cols[i] |= row & CELLMASK
            row >>= 4
        end
    end
    cols
end


function Base.rotl90(b::Bitboard)
    board = b.board
    # initialise the columns
    # cols = zeros(UInt16, 4)
    # cols = zeros(SVector{4, UInt16})
    col1 = zero(UInt16)
    col2 = zero(UInt16)
    col3 = zero(UInt16)
    col4 = zero(UInt16)

    # take one row at a time
    for row_shift in 48:-16:0
        row = (board >> row_shift) & ROWMASK

        # populate the right cell for each column
        col4 <<= 4 # doing this here effectively means each col only gets shifted 3 times
        col4 |= row & CELLMASK
        row >>= 4

        col3 <<= 4 # doing this here effectively means each col only gets shifted 3 times
        col3 |= row & CELLMASK
        row >>= 4

        col2 <<= 4 # doing this here effectively means each col only gets shifted 3 times
        col2 |= row & CELLMASK
        row >>= 4

        col1 <<= 4 # doing this here effectively means each col only gets shifted 3 times
        col1 |= row & CELLMASK
        row >>= 4
    end

    newboard = zero(UInt64)
    # construct the new board by putting the columns in to rows
    newboard |= col4
    newboard <<= 16
    newboard |= col3
    newboard <<= 16
    newboard |= col2
    newboard <<= 16
    newboard |= col1

    Bitboard(newboard)
end


"""
    move(board::UInt64, dir::Dirs)::UInt64
    move(board::UInt64, LOOKUP::Vector{UInt16}::UInt64

Bitboard game
"""
function move(bitboard::Bitboard, LOOKUP::Vector{UInt16})::Bitboard
    board = bitboard.board

    idx = board >> 48
    new_board = zero(UInt64)
    @inbounds new_board |= LOOKUP[idx+1]

    for i in 32:-16:0
        new_board <<= 16
        idx = (board >> i) & ROWMASK
        @inbounds new_board |= LOOKUP[idx+1]
    end
    Bitboard(new_board)
end

function move_and_reward(bitboard::Bitboard, LOOKUP::Vector{UInt16}, REWARDS)::Bitboard
    board = bitboard.board

    idx = board >> 48
    new_board = zero(UInt64)
    @inbounds new_board |= LOOKUP[idx+1]

    rewards = 0
    rewards += REWARDS[idx+1]

    for i in 32:-16:0
        new_board <<= 16
        idx = (board >> i) & ROWMASK
        @inbounds new_board |= LOOKUP[idx+1]
        rewards += REWARDS[idx+1]
    end
    Bitboard(new_board), rewards
end

function make_column_lookup_up()
    lookup_up = zeros(UInt64, 2^16)
    for u in 1:2^16
        u_moved_up = zero(UInt64)
        u_moved_left = LEFT[u]
        for i in 1:4
            tmp = UInt64((u_moved_left << 4(i - 1)) >> 12)
            u_moved_up |= (tmp << (60 - 16(i - 1)))
        end
        lookup_up[u] = u_moved_up
    end
    lookup_up
end

function make_column_lookup_down()
    lookup_up = zeros(UInt64, 2^16)
    for u in 1:2^16
        u_moved_down = zero(UInt64)
        u_moved_right = RIGHT[u]
        for i in 1:4
            tmp = UInt64((u_moved_right << 4(i - 1)) >> 12)
            u_moved_down |= (tmp << (60 - 16(i - 1)))
        end
        lookup_up[u] = u_moved_down
    end
    lookup_up
end

const UP = make_column_lookup_up()
const DOWN = make_column_lookup_down()

# Credit to Nneonneo
# equivalent to rotate left 90
function transpose(bb::Bitboard)
    x = bb.board
    a1 = x & 0xF0F00F0FF0F00F0F
    a2 = x & 0x0000F0F00000F0F0
    a3 = x & 0x0F0F00000F0F0000
    a = a1 | (a2 << 12) | (a3 >> 12)
    b1 = a & 0xFF00FF0000FF00FF
    b2 = a & 0x00FF00FF00000000
    b3 = a & 0x00000000FF00FF00
    return Bitboard(b1 | (b2 >> 24) | (b3 << 24))
end


function move_updown(bitboard::Bitboard, up_or_down)
    tbb = transpose(bitboard)
    moved = zero(UInt64)
    for i in 1:4
        c = (tbb.board << 16(i - 1)) >> 48
        moved |= (up_or_down[c+1] >> 4(i - 1))
    end
    Bitboard(moved)
end

function move(bitboard::Bitboard, dir::Dirs, skip_col_to_row = false)::Bitboard
    if dir == left
        new_bitboard = move(bitboard, LEFT)
    elseif dir == right
        new_bitboard = move(bitboard, RIGHT)
    elseif dir == up
        new_bitboard = move_updown(bitboard, UP)
    else
        new_bitboard = move_updown(bitboard, DOWN)
    end

    new_bitboard
end

function move_and_reward(bitboard::Bitboard, dir::Dirs)
    if dir == left
        new_bitboard = move_and_reward(bitboard, LEFT, LEFT_REWARD)
    elseif dir == right
        new_bitboard = move_and_reward(bitboard, RIGHT, RIGHT_REWARD)
    elseif dir == up
        new_bitboard = move_and_reward(transpose(bitboard), LEFT, LEFT_REWARD)
    else
        new_bitboard = move_and_reward(transpose(bitboard), RIGHT, RIGHT_REWARD)
    end

    new_bitboard
end

"""
Makes moves until not possible
"""
function move(bitboard::Bitboard, dirs::Vector{Dirs})::Bitboard
    for dir in dirs
        new_bitbaord = move(bitboard, dir)
        if new_bitbaord != bitboard
            return new_bitbaord
        end
    end
    return bitboard
end

"""counts how many empty spots there are in the bitboard"""
function count0(bitboard::Bitboard)
    board = bitboard.board
    # firstly count how many empty spots there are
    cnt_empty = 0

    for shift in 0:4:60
        cnt_empty += ((board >> shift) & CELLMASK) == 0
    end

    cnt_empty
end

"""Randomly add a 1-tile or a 2-tile"""
function add_tile(bitboard::Bitboard)::Bitboard
    cnt_empty = count0(bitboard)
    if cnt_empty == 0
        return bitboard
    end

    selected_empty_cell_num = rand(1:cnt_empty)

    add_tile(bitboard, selected_empty_cell_num, rand() < 0.1 ? 2 : 1)
end

"""Add a specified 1-tile or a 2-tile to selected'th empty cell"""
function add_tile(bitboard::Bitboard, selected::Integer, two_or_four)
    board = bitboard.board
    i = 0
    for shift in 0:4:60
        if ((board >> shift) & CELLMASK) == 0
            i += 1
            if i == selected
                board += two_or_four << shift
                return Bitboard(board)
            end
        end
    end
    Bitboard(board)
end

"""Convert a bitboard_to_array"""
function bitboard_to_array(bitboard::Bitboard)::Array{Int8,2}
    board = bitboard.board

    outboard = Array{Int8,2}(undef, 4, 4)

    rowid = 1
    # take one row at a time
    for row_shift in 48:-16:0
        row = (board >> row_shift) & ROWMASK

        # populate the right cell for each column
        for colid in 4:-1:1
            outboard[rowid, colid] = row & CELLMASK
            row >>= 4
        end
        rowid += 1
    end
    outboard
end

function Base.show(io::IO, bitboard::Bitboard)
    show(io, bitboard_to_array(bitboard))
end

function Base.display(bitboard::Bitboard)
    display(bitboard_to_array(bitboard))
end

function Base.maximum(bb::Bitboard)
    maximum(0:4:60) do s
        (bb.board >> s) & MASK
    end
end

function score(bb::Bitboard)
    mapreduce(+, 0:4:60) do s
        1 << ((bb.board >> s) & MASK)
    end
end


function value(state::Bitboard)
    ## comptue the value
    # maxtile = maximum(state)
    # val = maxtile <= 11 ? exp(maxtile - 11) : 2 << (maxtile - 12)
    # val = Int(maxtile >= 11)
    # return val

    sum(2 .<< bitboard_to_array(state)) / (2 << 31)
end