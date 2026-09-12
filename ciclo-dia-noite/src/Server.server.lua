local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local NS="GlearDayNight"
local remote=RS:WaitForChild(NS):WaitForChild("State")
local Core=require(script.Parent:WaitForChild("Core"))
local world=workspace:WaitForChild(NS .. "Demo")
local limits={}
local function allowed(player)
    local now=os.clock()
    local b=limits[player] or {Tokens=8,Time=now}
    limits[player]=b
    b.Tokens=math.min(8,b.Tokens+(now-b.Time)*4)
    b.Time=now
    if b.Tokens<1 then return false end
    b.Tokens=b.Tokens-1
    return true
end
local function nearby(player,part,distance)
    local c=player.Character
    local root=c and c:FindFirstChild("HumanoidRootPart")
    local h=c and c:FindFirstChildOfClass("Humanoid")
    return root~=nil and h~=nil and h.Health>0 and (root.Position-part.Position).Magnitude<=distance
end
Players.PlayerRemoving:Connect(function(player) limits[player]=nil end)
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local start=os.clock()
local networkTime=0
local function send(player)
    remote:FireClient(player,Core.Sample(os.clock()-start))
end
remote.OnServerEvent:Connect(function(player,action)
    if action=="Get" and allowed(player) then send(player) end
end)
RunService.Heartbeat:Connect(function(dt)
    local data=Core.Sample(os.clock()-start)
    Lighting.ClockTime=data.Hour
    Lighting.Brightness=data.Brightness
    networkTime=networkTime+dt
    if networkTime>=1 then networkTime=0; remote:FireAllClients(data) end
end)
