export GameRecorder, push!, trim!, setfinalstate!

# used to record what happened in one full game
mutable struct GameRecorder
    states::Vector{Bitboard}
    moves::Vector{Dirs}
    counter::Int
    final_state::Bitboard
    GameRecorder(init_len) = begin
        dummy_boards = Vector{Bitboard}(undef, init_len)
        new(dummy_boards, Vector{Dirs}(init_len), 0, dummy_boards[1])
    end
    GameRecorder() = GameRecorder(2888)
end

import Base

function Base.push!(gr::GameRecorder, board, move)
    # increase the size by 20% if already at limit
    if gr.counter == length(gr.states)
        resize!(gr.states, round(Int, gr.counter*1.2))
        resize!(gr.moves, round(Int, gr.counter*1.2))
    end

    gr.counter += 1
    gr.states[gr.counter] = board
    gr.moves[gr.counter] = move

    gr
end

function trim!(gr::GameRecorder)
    resize!(gr.states, gr.counter)
    resize!(gr.moves, gr.counter)
    gr
end

function setfinalstate!(gr::GameRecorder, board)
    gr.final_state = board
end

Base.length(gr::GameRecorder) = gr.counter

