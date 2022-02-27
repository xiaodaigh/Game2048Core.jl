export LEFT, RIGHT, move, add_tile, LEFT_REWARD, RIGHT_REWARD, show, initbboard, display
export move_and_reward

import Base.show, Base.display, Base.maximum

const ROWMASK=UInt16(2^16-1)
const CELLMASK=UInt16(2^4-1)

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

function move_updown(bitboard::Bitboard, LOOKUP::Vector{UInt16}, skip_col_to_row=false)::Bitboard
    # move(rotl90(bitboard), LOOKUP)
    cols = board2cols(bitboard)
    cols_moved = getindex.(Ref(LOOKUP), cols .+ 1)

    new_board = zero(UInt64)

    if !skip_col_to_row
        # construct the new board by putting the columns in to rows
        for rowid in 1:4
            for colid in 1:4
                new_board <<= 4
                @inbounds new_board |= (cols_moved[colid] >> 4(4-rowid)) & CELLMASK
            end
        end
    else
        # construct the new board by putting the columns in to rows
        for colid in 1:4
            new_board <<= 16
            @inbounds new_board |= cols_moved[colid]
        end

    end

    return Bitboard(new_board)
end

function move(bitboard::Bitboard, dir::Dirs, skip_col_to_row=false)::Bitboard
    if dir == left
        new_bitboard = move(bitboard, LEFT)
    elseif dir == right
        new_bitboard = move(bitboard, RIGHT)
    elseif dir == up
        new_bitboard = move_updown(bitboard, LEFT, skip_col_to_row)
    else
        new_bitboard = move_updown(bitboard, RIGHT, skip_col_to_row)
    end

    new_bitboard
end

function move_and_reward(bitboard::Bitboard, dir::Dirs)
    if dir == left
        new_bitboard = move_and_reward(bitboard, LEFT, LEFT_REWARD)
    elseif dir == right
        new_bitboard = move_and_reward(bitboard, RIGHT, RIGHT_REWARD)
    elseif dir == up
        new_bitboard = move_upad_and_reward(bitboard, LEFT, LEFT_REWARD, skip_col_to_row)
    else
        new_bitboard = move_upad_and_reward(bitboard, RIGHT, RIGHT_REWARD, skip_col_to_row)
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
function bitboard_to_array(bitboard::Bitboard)::Array{Int8, 2}
    board = bitboard.board

    outboard = Array{Int8, 2}(undef, 4, 4)

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

Base.maximum(bb::Bitboard) = maximum(bitboard_to_array(bb))

function value(state::Bitboard)
    ## comptue the value
    # maxtile = maximum(state)
    # val = maxtile <= 11 ? exp(maxtile - 11) : 2 << (maxtile - 12)
    # val = Int(maxtile >= 11)
    # return val

    sum(2 .<< bitboard_to_array(state)) / (2 << 31)
end