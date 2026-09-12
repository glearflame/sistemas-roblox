-- Checkpoints de obby: execute na Command Bar do Studio com Play PARADO.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Execute na Command Bar, fora do Play")
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local NS="GlearCheckpoints"
for _,entry in ipairs({{SSS,NS},{RS,NS},{SPS,NS},{workspace,NS.."Demo"}}) do
    assert(not entry[1]:FindFirstChild(entry[2]),"Já existe "..entry[2]..". Instalação cancelada.")
end
local function folder(name)
    local f=Instance.new("Folder"); f.Name=name; return f
end
local server,shared,client,world=folder(NS),folder(NS),folder(NS),folder(NS.."Demo")
local function source(class,parent,name,content)
    local s=Instance.new(class); s.Name=name; s.Source=content; s.Parent=parent
end
local remote=Instance.new("RemoteEvent")
remote.Name="State"; remote.Parent=shared
local function part(name,size,position,color)
    local p=Instance.new("Part")
    p.Name=name; p.Size=size; p.Position=position; p.Color=color
    p.Anchored=true; p.Parent=world; return p
end
local function prompt(p,action,object)
    local q=Instance.new("ProximityPrompt")
    q.ActionText=action; q.ObjectText=object; q.MaxActivationDistance=8
    q.HoldDuration=0; q.RequiresLineOfSight=false; q.Parent=p
end
local function label(p,text)
    local b=Instance.new("BillboardGui")
    b.Size=UDim2.new(0,160,0,40); b.StudsOffset=Vector3.new(0,4,0); b.Parent=p
    local t=Instance.new("TextLabel")
    t.Size=UDim2.fromScale(1,1); t.Text=text; t.BackgroundTransparency=1
    t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=0.3; t.TextSize=18; t.Parent=b
end
for i = 1, 4 do
    local p = part("Checkpoint" .. i, Vector3.new(12, 1, 12), Vector3.new((i-1)*18, 1, 25), Color3.fromRGB(70,130,255))
    label(p, "Checkpoint " .. i)
end
source("ModuleScript",server,"Core",[==[
local M = { Count = 4 }
function M.Advance(current, target)
    if type(target) ~= "number" or target % 1 ~= 0 or target < 1 or target > M.Count then return current, false end
    if target ~= current + 1 then return current, false end
    return target, true
end
return M
]==])
source("Script",server,"Server",[==[
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
]==])
source("LocalScript",client,"Client",[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local NS="GlearCheckpoints"
local remote=RS:WaitForChild(NS):WaitForChild("State")
local gui=Instance.new("ScreenGui")
gui.Name=NS .. "UI"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local tab=Instance.new("TextButton")
tab.Size=UDim2.new(0,94,0,36)
tab.Position=UDim2.new(0,8,0,90)
tab.Text="Obby"
tab.TextColor3=Color3.new(1,1,1)
tab.BackgroundColor3=Color3.fromRGB(30,48,78)
tab.Parent=gui
local panel=Instance.new("Frame")
panel.Size=UDim2.new(0,200,0,150)
panel.Position=UDim2.new(0,110,0,90)
panel.BackgroundColor3=Color3.fromRGB(16,24,38)
panel.Visible=false
panel.Parent=gui
local text=Instance.new("TextLabel")
text.Size=UDim2.new(1,-20,0,95)
text.Position=UDim2.new(0,10,0,6)
text.BackgroundTransparency=1
text.TextColor3=Color3.new(1,1,1)
text.TextSize=15
text.TextWrapped=true
text.Text="Carregando..."
text.Parent=panel
tab.Activated:Connect(function() panel.Visible=not panel.Visible end)
local ready=false
local function render(data)
    return string.format("Etapa %d / %d\nPasse pelas plataformas em ordem.", data.Stage, data.Total)
end
remote.OnClientEvent:Connect(function(data)
    ready=true
    text.Text=render(data)
end)

task.spawn(function()
    repeat remote:FireServer("Get"); task.wait(2) until ready
end)
]==])
shared.Parent=RS
world.Parent=workspace
client.Parent=SPS
server.Parent=SSS
print("Checkpoints de obby instalado. Salve o projeto e dê Play.")
