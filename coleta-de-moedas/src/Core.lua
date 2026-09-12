local M = { Reward = 10, Cooldown = 20, Count = 5 }
function M.New() return { Balance = 0, NextClaim = {} } end
function M.Claim(state, coin, now)
    if type(coin) ~= "number" or coin % 1 ~= 0 or coin < 1 or coin > M.Count then return false end
    if now < (state.NextClaim[coin] or 0) then return false end
    state.NextClaim[coin] = now + M.Cooldown
    state.Balance = state.Balance + M.Reward
    return true
end
return M
