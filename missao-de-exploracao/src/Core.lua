local M = { Goal = 3, Reward = 100 }
function M.New() return { Visited = {}, Count = 0, Claimed = false, Credits = 0 } end
function M.Visit(state, point)
    if type(point) ~= "number" or point % 1 ~= 0 or point < 1 or point > M.Goal then return false end
    if state.Visited[point] or state.Claimed then return false end
    state.Visited[point] = true
    state.Count = state.Count + 1
    return true
end
function M.Claim(state)
    if state.Count < M.Goal or state.Claimed then return false end
    state.Claimed = true
    state.Credits = state.Credits + M.Reward
    return true
end
return M
