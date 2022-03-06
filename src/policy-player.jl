# given a policy, these utils play out a game
export play_n_game, greedy_player, play_via_monte_carlo_w_recorder, play_via_monte_carlo_wo_recorder

using Base.Threads

function play_one_move_with_policy(bitboard, policy)
    probs = policy(bitboard)

    newboards = move.(Ref(bitboard), DIRS)

    for (i, newboard) in enumerate(newboards)
        if newboard == bitboard
            # it means the move was not possible
            # set the probability to 0
            probs[i] = 0
        end
    end

    tot_prob = sum(probs)

    while !(tot_prob ≈ 0.0)
        for i in 1:4
            if (probs[i] != 0) && (rand() < probs[i]/tot_prob)
                return newboards[i], DIRS[i]
            end
            tot_prob -= probs[i]
        end

        # if no move got selected. this could just be unlucky; just keep going
        tot_prob = sum(probs)
    end

    # nothing got played
    return bitboard, left
end

if false
    # @code_warntype play_one_move_with_policy(initbboard(), randompolicy)
    # @benchmark play_one_move_with_policy(initbboard(), randompolicy)
    # above is faster than below
    #@benchmark Game2048.randmove(initbboard())
end

"""
    play_game_with_policy(policy, bitboard)

Play the game with the given policy. The moves are chosen at random weighted by the policy weights.
There is NO search in this algorithm
"""
function play_game_with_policy(policy, bitboard)
    while true
        newboard, _ = play_one_move_with_policy(bitboard, policy)
        if newboard == bitboard
            return newboard
        end

        bitboard = newboard |> add_tile
    end
end

if false
    # @code_warntype play_game_with_policy(randompolicy, initbboard())
    # @time play_game_with_policy(randompolicy, initbboard())
    # @benchmark play_game_with_policy(randompolicy, initbboard())
end

"""
    play_game_with_policy(policy, bitboard) -> GameRecorder

Play the game with the given policy. The moves are recorded
"""
function play_game_with_policy_w_record(policy, bitboard)
    recorder = GameRecorder()
    while true
        newboard, move_made = play_one_move_with_policy(bitboard, policy)
        push!(recorder, deepcopy(newboard), move_made)

        if newboard == bitboard
            # lost
            setfinalstate!(recorder, bitboard)
            trim!(recorder)

            return recorder
        end

        bitboard = newboard |> add_tile
    end
end

"""
Return the best move

Argument:

board - the board
n - how many times to play

"""

function find_best_move(board, n, policy)
    # try to play in each of the 4 directions `n` times one move ahead
    # after that just play randomly and record the score
    # the direction with the highest average score becomes the best direction
    res = zeros(Int, 4)

    probs = policy(board)

    # distribute the search by probs
    tries = 4n .* probs

    for direction in DIRS
        dir_idx = Int(direction) + 1
        new_board = move(board, direction)
        if new_board == board # not a valid move
            res[dir_idx] = -1
            continue
        end

        res_dir_idx = 0.0
        for _ in 1:tries[dir_idx]
            # random add one tile
            tmp_board = add_tile(new_board)

            # simulate from this onward
            # the roll out should be random
            fnl_tmp_board = play_game_with_policy(randompolicy, tmp_board)
            res_dir_idx += sum(2 .<< (bitboard_to_array(fnl_tmp_board) .- 1))
        end
        res[dir_idx] = res_dir_idx
    end

    DIRS[argmax(res)]
end

if false
    # @code_warntype find_best_move(initbboard(), 10, randompolicy)
    # @time find_best_move(initbboard(), 10, randompolicy)
end

"""
Records all the moves

Arguments:

    policy - a function that takes a bitboard and returns a policy
    n - how many moves of each direction to check
    bitboard - the starting state of play; defaults to `initbboard()`
"""
function play_via_monte_carlo_w_recorder(policy; n, bitboard=initbboard())
    recorder = GameRecorder()
    while true
        best_move = find_best_move(bitboard, n, policy)
        push!(recorder, deepcopy(bitboard), best_move)
        new_bitboard = move(bitboard, best_move)

        if new_bitboard != bitboard
            bitboard = add_tile(new_bitboard)
        else
            # lost
            setfinalstate!(recorder, bitboard)
            trim!(recorder)
            return recorder
        end
    end
end

function play_via_monte_carlo_wo_recorder(policy; n, bitboard=initbboard())
    while true
        best_move = find_best_move(bitboard, n, policy)
        new_bitboard = move(bitboard, best_move)

        if new_bitboard != bitboard
            bitboard = add_tile(new_bitboard)
        else
            # lost
            return new_bitboard
        end
    end
end

if false
    # @time result = play_via_monte_carlo_w_recorder(randompolicy; n=10);
end

"""
Play the game with the given policy. The moves are chosen at random weighted by the policy weights.

There is search as defined by `ntries_per_turn`. Each direction is played `ntries_per_turn` times
and the best move is played.
"""
function play_n_game(policy; n=1, ntries_per_turn=10)
    results = Vector{GameRecorder}(undef, n)
    # policies = [deepcopy(policy) for _ in 1:nthreads()]
    @threads for i in 1:n
        results[i] = play_via_monte_carlo_w_recorder(policy; n=ntries_per_turn);
    end
    results
end


function make_one_greedy_move(state, policy)
    prob = policy(state)
    i = 0
    while i <=4
        idx = argmax(prob)
        dir = DIRS[idx]

        new_state = move(state, dir)
        if new_state == state
            prob[idx] = 0
            i += 1
        else
            return new_state
        end
    end
    return state
end

"""
    Greedy player plays the game by choosing the move with highest policy probability.
"""
function greedy_player(policy, state::Bitboard=initbboard())
    while true
        state_after_move = make_one_greedy_move(state, policy)

        if state_after_move == state
            return state
        end

        state = add_tile(state_after_move)

        if state == state_after_move
            return state_after_move
        end
    end
end

if false
    using StatsBase
    @time countmap([maximum(Game2048.play_game_with_policy(randompolicy, initbboard())) for i in 1:10_000]) # random policy
    @time countmap([maximum(greedy_player(leftdownpolicy, initbboard())) for i in 1:10_000]) # left down

    @time countmap([maximum(play_n_game(leftdownpolicy; n=1, ntries_per_turn=10)[1].final_state) for i in 1:100])
    @time countmap([maximum(play_n_game(randompolicy; n=1, ntries_per_turn=10)[1].final_state) for i in 1:100])
    @time countmap([maximum(play_n_game(randompolicy; n=1, ntries_per_turn=100)[1].final_state) for i in 1:100])

    @time countmap([maximum(play_game_via_mcts_w_tries(randompolicy; n = 10)) for _ in 1:100])
end