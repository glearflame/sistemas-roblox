local M = { Count = 4 }
function M.Advance(current, target)
    if type(target) ~= "number" or target % 1 ~= 0 or target < 1 or target > M.Count then return current, false end
    if target ~= current + 1 then return current, false end
    return target, true
end
return M
