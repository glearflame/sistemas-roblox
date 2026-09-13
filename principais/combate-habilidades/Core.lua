local M = {}
M.Skills = {
    slash={Name="Golpe",Cost=0,Cooldown=0.6,Damage=22,Range=10},
    pulse={Name="Pulso",Cost=35,Cooldown=5,Damage=35,Range=17},
    guard={Name="Defesa",Cost=25,Cooldown=8,Damage=0,Range=0},
}
function M.New() return {Energy=100,Ready={},GuardUntil=0} end
function M.Tick(s,dt)
    if type(dt)~="number" or dt~=dt or dt<0 or dt==math.huge then return end
    s.Energy=math.min(100,s.Energy+math.min(dt,1)*12)
end
function M.Cast(s,id,now)
    local skill=type(id)=="string" and M.Skills[id]
    if not skill then return false,"Habilidade desconhecida." end
    if now<(s.Ready[id] or 0) then return false,"Habilidade em recarga." end
    if s.Energy<skill.Cost then return false,"Energia insuficiente." end
    s.Energy=s.Energy-skill.Cost
    s.Ready[id]=now+skill.Cooldown
    if id=="guard" then s.GuardUntil=now+2 end
    return true,skill
end
function M.Incoming(s,damage,now,armor)
    local scale=armor and 0.8 or 1
    if now<s.GuardUntil then scale=scale*0.35 end
    return math.max(1,math.floor(damage*scale+0.5))
end
return M
