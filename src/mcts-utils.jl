using Game2048
using Game2048Core
using Game2048Core: value, count0
using Dates

mutable struct MctsTreeNode
    parent::Union{Nothing,MctsTreeNode}
    nvisit::Int32
    totreward::Float32
    state::Bitboard
    children_prior::Vector{Float32} # probability of children
    children::Vector{MctsTreeNode}
    children_are_moves::Bool # Its children are moves instead of add tile
    policy::Function

    function MctsTreeNode(; state, policy, children_are_moves, parent)
        new(parent, 0, 0, state, [], [], children_are_moves, policy)
    end
end

function Base.show(io::IO, tree::MctsTreeNode)
    show(io, tree.nvisit)
end

function _display(tree::MctsTreeNode, indent)
    if length(indent) >= 4
        return
    end
    display(tree.state)
    for (prior, child) in zip(tree.children_prior, tree.children)
        status = string((totreward = child.totreward, prior = prior, nvisit = child.nvisit))
        display(indent * status)
        _display(child, indent * "    ")
    end
end

function Base.display(tree::MctsTreeNode)
    _display(tree, "")
end

# do I need to bubble up the reward? Since we can choose the action with the most visits.
# propate the reward (bubble up)
function bubble_up_reward!(child_node::MctsTreeNode)
    if isnothing(child_node.parent) || child_node.parent.children_are_moves
        if all(child_node.children_prior .== 0)
            # if no more moves
            child_node.nvisit += 1
            child_node.totreward = value(child_node.state)
        else
            # did not receive a value so I am updating it
            # it's children are all addtiles, so you don't get to choose but can only average them
            maxreward = mapreduce(node -> node.totreward, max, child_node.children)
            totvisits = mapreduce(node -> node.nvisit, +, child_node.children)

            # this function should update the reward and visit count
            child_node.totreward = maxreward
            child_node.nvisit = totvisits
        end

        if isnothing(child_node.parent)
            return
        else
            bubble_up_reward!(child_node.parent)
        end
    else
        # did not receive a value so I am updating it
        # its children are all `add_tile`s, so you don't get to choose but can only average them
        rewards = map(node -> node.totreward, child_node.children)
        visits = map(node -> node.nvisit, child_node.children)

        # this function should update the reward and visit count
        child_node.totreward = sum(rewards .* visits) / sum(visits)
        child_node.nvisit = sum(visits)

        # upto here
        bubble_up_reward!(child_node.parent)
    end
end


"""
Select a move randomly according to policy distribution

Return:

    the same board and left move if no move is possible
"""
function select_move(bboard::Bitboard, probs::Vector{Float32})
    # mostly copied from play_one_move_with_policy
    # select a direction to play
    tot_prob = sum(probs)
    while !(tot_prob ≈ 0.0)
        for i in 1:4
            if rand() < probs[i] / tot_prob
                # select this move
                newboard = move(bboard, DIRS[i])
                if newboard == bboard # if nothing changed then the move is not possible
                    # this move will never be selected again
                    probs[i] = zero(Float32)
                else
                    return newboard, DIRS[i]
                end
            end
            tot_prob -= probs[i]
        end

        # if no move got selected. this could just be unlucky; just keep going
        tot_prob = sum(probs)
    end
    return bboard, left
end

const C = 2 # exploration constant


"""
    Internal function do a single simulation given a bitboard
"""
function _rollout(state::Bitboard, policy)
    # a rollout will just play the game at random
    # select a children to do rollout
    end_state = play_game_with_policy(policy, state)

    return value(end_state)
end

"""
    rollout(tree::MctsTreeNode)

Do one rolll out of the game using the policy
"""
function rollout(tree::MctsTreeNode)
    if !tree.children_are_moves
        tmp_state = add_tile(tree.state)
    end
    _rollout(tree.state, tree.policy)
end

# use this to decide which child node to do a rollout
function select_child_node(tree::MctsTreeNode)
    if tree.children_are_moves
        if all(tree.children_prior .== 0)
            # if no move is posible return itself as it's not possible go any further
            return tree
        end
        best_child_val = 0.0
        best_child = tree.children[1]
        for (prior_prob, child) in zip(tree.children_prior, tree.children)
            # Note: due to expand_node!, each child must have had a visit and rollout already
            child_val = tree.totreward + prior_prob / child.nvisit
            if best_child_val < child_val
                best_child_val = child_val
                best_child = child
            end
        end
        return best_child
    else
        best_child_val = 0.0
        if length(tree.children) == 0
            println("meh")
        end
        best_child = tree.children[1]

        for (prior_prob, child) in zip(tree.children_prior, tree.children)
            # Note: due to expand_node!, each child must have had a visit and rollout already

            # for notes that's all about add tile; we can't choose by the reward hence the exploration
            # is purely guide by probabilities
            child_val = prior_prob / child.nvisit
            if best_child_val < child_val
                best_child_val = child_val
                best_child = child
            end
        end
        return best_child
    end
end

function expand_node!(tree::MctsTreeNode)
    @assert length(tree.children) == 0
    if tree.children_are_moves
        tree.children = Vector{MctsTreeNode}(undef, 4)
        tree.children_prior = tree.policy(tree.state)

        rescale_prior = false

        # expand the node
        for (i, dir) in enumerate(DIRS)
            tmp_state = move(tree.state, dir)
            # if the move has no effect, skip it
            if tmp_state == tree.state
                # set it's prior to 0
                tree.children_prior[i] = 0

                rescale_prior = true # rescale the priors so they sum to 1
            end

            tmp_child = MctsTreeNode(;
                state = tmp_state,
                policy = tree.policy,
                children_are_moves = false,
                parent = tree)

            tree.children[Int(dir)+1] = tmp_child
            tmp_child.totreward += rollout(tmp_child)
            # could've set1 it to 1 as there is not reason why the child just created would be anything
            # other than 0
            tmp_child.nvisit += 1
        end

        if rescale_prior
            if all(tree.children_prior .== 0)
                # this means the game has ended as no move is possible
                return tree
            end
            tree.children_prior .= tree.children_prior ./ sum(tree.children_prior)
        end

        return tree
    else
        # find all the empty spots
        num_of_possible_pos = count0(tree.state)

        tree.children_prior = vcat(
            fill(1 / num_of_possible_pos * 0.9, num_of_possible_pos),
            fill(1 / num_of_possible_pos * 0.1, num_of_possible_pos),
        )

        # make sure it sums to 1
        tree.children_prior .= tree.children_prior ./ sum(tree.children_prior)

        resize!(tree.children, num_of_possible_pos * 2)


        for i in 1:num_of_possible_pos
            # add the possible of a 2-tile being generated
            tmp_state = add_tile(tree.state, i, 1)
            tmp_child = MctsTreeNode(;
                state = tmp_state,
                policy = tree.policy,
                children_are_moves = true,
                parent = tree)

            tree.children[i] = tmp_child

            tmp_child.nvisit += 1
            tmp_child.totreward += rollout(tmp_child)

            # add the possible of a 4-tile being generated
            tmp_state = add_tile(tree.state, i, 2)

            tmp_child = MctsTreeNode(;
                state = tmp_state,
                policy = tree.policy,
                children_are_moves = true,
                parent = tree)

            tree.children[i+num_of_possible_pos] = tmp_child

            tmp_child.nvisit += 1
            tmp_child.totreward += rollout(tree.children[i])
        end
        return tree
    end
end

# every `expand_node!` does one roll out of its children
# so every node has had at least one visit
function select_node_to_expand(tree)
    # traverse the tree and find a node to expand
    selected_child = select_child_node(tree)
    # println("this is the next child:")
    # display(selected_child.state)

    # if it does not have children then visit is just 1
    if (selected_child.nvisit == 1) || all(==(0), selected_child.children_prior)
        # println("got here")
        # display(selected_child)
        return selected_child
    else
        # if the child node has been visited do it recursively
        select_node_to_expand(selected_child)
    end
end


function inittree(policy::Function)
    state = initbboard()
    # function monte_carlo_tree_search(bboard, policy)
    # probs = policy(state)

    # create the base node
    tree = MctsTreeNode(; state, policy, children_are_moves = true, parent = nothing)

    # always expand the base node
    # when you expand, the children is populated
    # and one rollout for each child is done
    # when I expand a node should I add to its visit count?
    expand_node!(tree)
end

function displaytop(tree)
    for (prior, child) in zip(tree.children_prior, tree.children)
        status = string((totreward = child.totreward, prior = prior, nvisit = child.nvisit))
        display(status)
    end
end


function mcts!(tree)
    ## now select a child node
    child_node = select_node_to_expand(tree)
    # expand it; all its children have now done a roll out
    if length(child_node.children) == 0
        expand_node!(child_node)
    end
    bubble_up_reward!(child_node)
    tree
end

function mcts!(tree, n)
    for _ in 1:n
        mcts!(tree)
    end
    tree
end

function maxdepth(tree, atdepth = 0)
    if length(tree.children) == 0
        return atdepth
    else
        return atdepth + 1 + maximum(maxdepth, tree.children)
    end
end


function play_game_via_mcts_w_timer(policy; ms = 10, verbose = false)
    tree = inittree(policy)

    while true
        # select a move by playing mcts
        t = Dates.now()
        while (Dates.now() - t).value < ms # within one second
            mcts!(tree)
        end

        # select the best move
        children_and_priors = zip(tree.children, tree.children_prior)
        best_child_idx = argmax(map(((c, prior),) -> c.totreward * (prior != 0), children_and_priors))

        dir = DIRS[best_child_idx]

        pre_add_tile_state = move(tree.state, dir)
        if count0(pre_add_tile_state) == 0
            if verbose
                println("game ended")
                display(pre_add_tile_state)
            end
            return pre_add_tile_state
        end
        grand_child_state = add_tile(pre_add_tile_state)

        grand_children = tree.children[best_child_idx].children

        gc_idx = findfirst(child -> child.state == grand_child_state, grand_children)

        # if isnothing(gc_idx)
        #     @infiltrate
        # end

        # look the grandchild
        tree = tree.children[best_child_idx].children[gc_idx]
        tree.parent = nothing

        if verbose
            display(grand_child_state)
            println("the maxdepth is now $(maxdepth(tree))")
        end
    end
end

function play_game_via_mcts_w_tries(policy; n = 10, verbose = false)
    tree = inittree(policy)

    while true
        # select a move by playing mcts
        mcts!(tree, n)

        # select the best move
        children_and_priors = zip(tree.children, tree.children_prior)
        best_child_idx = argmax(map(((c, prior),) -> c.totreward * (prior != 0), children_and_priors))

        dir = DIRS[best_child_idx]

        pre_add_tile_state = move(tree.state, dir)
        if count0(pre_add_tile_state) == 0
            if verbose
                println("game ended")
                display(pre_add_tile_state)
            end
            return pre_add_tile_state
        end
        grand_child_state = add_tile(pre_add_tile_state)

        grand_children = tree.children[best_child_idx].children

        gc_idx = findfirst(child -> child.state == grand_child_state, grand_children)

        # if isnothing(gc_idx)
        #     @infiltrate
        # end

        # look the grandchild
        tree = tree.children[best_child_idx].children[gc_idx]
        tree.parent = nothing

        if verbose
            display(grand_child_state)
            println("the maxdepth is now $(maxdepth(tree))")
        end
    end
end