local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local NS="GlearCoins"
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
local states = {}
local function send(player)
    local state = states[player]
    if state then
        local remaining = {}
        for coin, nextClaim in pairs(state.NextClaim) do remaining[coin] = math.max(0, nextClaim-os.clock()) end
        remote:FireClient(player, { Balance = state.Balance, Remaining = remaining })
    end
end
local function added(player)
    if not states[player] then states[player] = Core.New() end
end
for i = 1, Core.Count do
    local coin = world:WaitForChild("Coin" .. i)
    local prompt = coin:WaitForChild("ProximityPrompt")
    prompt.Triggered:Connect(function(player)
        if not states[player] or not prompt.Enabled or not nearby(player, coin, 10) or not allowed(player) then return end
        Core.Claim(states[player], i, os.clock())
        send(player)
    end)
end
remote.OnServerEvent:Connect(function(player, action)
    if action == "Get" and allowed(player) then send(player) end
end)
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
for _, player in ipairs(Players:GetPlayers()) do added(player) end
