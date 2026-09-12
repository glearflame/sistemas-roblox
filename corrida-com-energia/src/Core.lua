local M = { Max=100, Drain=24, Regen=18, Restart=25, Walk=16, Run=26 }
function M.New() return { Energy=M.Max, Exhausted=false, Running=false } end
function M.Step(state, wants, moving, dt)
    if type(dt) ~= "number" or dt ~= dt or dt < 0 or dt == math.huge then return state end
    dt = math.min(dt,0.25)
    state.Running = wants == true and moving == true and not state.Exhausted and state.Energy > 0
    if state.Running then
        state.Energy = math.max(0,state.Energy-M.Drain*dt)
        if state.Energy == 0 then state.Exhausted=true; state.Running=false end
    else
        state.Energy = math.min(M.Max,state.Energy+M.Regen*dt)
        if state.Energy >= M.Restart then state.Exhausted=false end
    end
    return state
end
return M
