local M = {MaxWave=10,Intermission=7,MaxActive=18}
function M.New() return {Phase="Idle",Wave=0,Alive=0,NextAt=0,Run=0} end
function M.Start(s,now)
    if s.Phase~="Idle" and s.Phase~="Defeat" and s.Phase~="Victory" then return false end
    s.Run=s.Run+1
    s.Phase="Break"; s.Wave=0; s.Alive=0; s.NextAt=now+3
    return true
end
function M.Tick(s,now)
    if s.Phase~="Break" or now<s.NextAt then return nil end
    s.Wave=s.Wave+1
    s.Phase="Combat"
    s.Alive=math.min(M.MaxActive,2+s.Wave*2)
    return {Count=s.Alive,Health=45+s.Wave*9,Speed=6+s.Wave*0.4,Damage=6+s.Wave}
end
function M.Kill(s,now)
    if s.Phase~="Combat" or s.Alive<=0 then return false,0 end
    s.Alive=s.Alive-1
    if s.Alive>0 then return false,0 end
    if s.Wave>=M.MaxWave then s.Phase="Victory" else s.Phase="Break"; s.NextAt=now+M.Intermission end
    return true,30+s.Wave*10
end
function M.Fail(s)
    if s.Phase=="Combat" or s.Phase=="Break" then s.Phase="Defeat"; s.Alive=0 end
end
return M
