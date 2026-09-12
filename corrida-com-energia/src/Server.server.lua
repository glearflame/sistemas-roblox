local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local NS="GlearSprint"
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
local RunService = game:GetService("RunService")
local states, requests, networkTime = {}, {}, 0
local function send(player)
    local s=states[player]
    if s then remote:FireClient(player,{Energy=math.floor(s.Energy),Max=Core.Max,Running=s.Running,Exhausted=s.Exhausted}) end
end
local function added(player)
    if states[player] then return end
    states[player]=Core.New()
    player.CharacterAdded:Connect(function()
        states[player]=Core.New()
        requests[player]=false
    end)
end
remote.OnServerEvent:Connect(function(player,action,value)
    -- A stop request is harmless and must not be dropped by the rate limit.
    if action=="Run" and value==false then requests[player]=false; return end
    if not allowed(player) or not states[player] then return end
    if action=="Get" then send(player)
    elseif action=="Run" and type(value)=="boolean" then requests[player]=value end
end)
RunService.Heartbeat:Connect(function(dt)
    networkTime=networkTime+dt
    local publish=networkTime>=0.2
    if publish then networkTime=0 end
    for player,state in pairs(states) do
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local alive=humanoid and humanoid.Health>0 and root
        local moving=alive and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude>0.5
        Core.Step(state,alive and requests[player]==true,moving==true,dt)
        if humanoid then
            local speed=state.Running and Core.Run or Core.Walk
            if humanoid.WalkSpeed~=speed then humanoid.WalkSpeed=speed end
        end
        if publish then send(player) end
    end
end)
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) states[player]=nil; requests[player]=nil end)
for _,player in ipairs(Players:GetPlayers()) do added(player) end
