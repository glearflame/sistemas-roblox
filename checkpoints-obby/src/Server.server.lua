local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local NS="GlearCheckpoints"
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
local stages = {}
local function send(player)
    remote:FireClient(player, { Stage = stages[player] or 0, Total = Core.Count })
end
local function characterAdded(player, character)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not root or player.Character ~= character or not player.Parent then return end
    local stage = stages[player] or 0
    local checkpoint = world:FindFirstChild("Checkpoint" .. stage)
    if checkpoint then character:PivotTo(checkpoint.CFrame + Vector3.new(0, 5, 0)) end
end
local function added(player)
    if stages[player] ~= nil then return end
    stages[player] = 0
    player.CharacterAdded:Connect(function(character) characterAdded(player, character) end)
    if player.Character then task.spawn(characterAdded, player, player.Character) end
end
for index = 1, Core.Count do
    local part = world:WaitForChild("Checkpoint" .. index)
    part.Touched:Connect(function(hit)
        local character = hit:FindFirstAncestorOfClass("Model")
        local player = character and Players:GetPlayerFromCharacter(character)
        if not player or stages[player] == nil or not nearby(player, part, 12) then return end
        local nextStage, changed = Core.Advance(stages[player], index)
        if changed then stages[player] = nextStage; send(player) end
    end)
end
remote.OnServerEvent:Connect(function(player, action)
    if action == "Get" and allowed(player) then send(player) end
end)
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) stages[player] = nil end)
for _, player in ipairs(Players:GetPlayers()) do added(player) end
