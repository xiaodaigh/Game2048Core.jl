export randompolicy, leftdownpolicy

"""
    Chooses a direction randomly
"""
function randompolicy(_)
    Float32[0.25, 0.25, 0.25, 0.25]
end

"""
    Chooses left or down, and the other direction rarely.
    Intended for use with the Greedy player
"""
function leftdownpolicy(_)
    Float32[0.99-2eps(Float32), eps(Float32), eps(Float32), 0.01]
end
