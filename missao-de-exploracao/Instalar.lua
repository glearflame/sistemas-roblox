-- Missão de exploração: execute na Command Bar do Studio com Play PARADO.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Execute na Command Bar, fora do Play")
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local NS="GlearQuest"
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
for i = 1, 3 do
    local p = part("Point" .. i, Vector3.new(4,5,4), Vector3.new((i-1)*22, 2.5, -40), Color3.fromRGB(163,108,255))
    prompt(p, "Explorar", "Ponto " .. i)
    label(p, "Explore aqui: " .. i)
end
source("ModuleScript",server,"Core",[==[
local M = { Goal = 3, Reward = 100 }
function M.New() return { Visited = {}, Count = 0, Claimed = false, Credits = 0 } end
function M.Visit(state, point)
    if type(point) ~= "number" or point % 1 ~= 0 or point < 1 or point > M.Goal then return false end
    if state.Visited[point] or state.Claimed then return false end
    state.Visited[point] = true
    state.Count = state.Count + 1
    return true
end
function M.Claim(state)
    if state.Count < M.Goal or state.Claimed then return false end
    state.Claimed = true
    state.Credits = state.Credits + M.Reward
    return true
end
return M
]==])
source("Script",server,"Server",[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local NS="GlearQuest"
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
    local s = states[player]
    if s then remote:FireClient(player, { Count=s.Count, Goal=Core.Goal, Claimed=s.Claimed, Credits=s.Credits }) end
end
local function added(player)
    if not states[player] then states[player] = Core.New() end
end
for i = 1, Core.Goal do
    local point = world:WaitForChild("Point" .. i)
    point.ProximityPrompt.Triggered:Connect(function(player)
        if states[player] and point.ProximityPrompt.Enabled and nearby(player,point,10) and allowed(player) then
            Core.Visit(states[player],i)
            send(player)
        end
    end)
end
remote.OnServerEvent:Connect(function(player, action)
    if not allowed(player) or not states[player] then return end
    if action == "Claim" then Core.Claim(states[player]) end
    if action == "Get" or action == "Claim" then send(player) end
end)
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
for _, player in ipairs(Players:GetPlayers()) do added(player) end
]==])
source("LocalScript",client,"Client",[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local NS="GlearQuest"
local remote=RS:WaitForChild(NS):WaitForChild("State")
local gui=Instance.new("ScreenGui")
gui.Name=NS .. "UI"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local tab=Instance.new("TextButton")
tab.Size=UDim2.new(0,94,0,36)
tab.Position=UDim2.new(0,8,0,174)
tab.Text="Missão"
tab.TextColor3=Color3.new(1,1,1)
tab.BackgroundColor3=Color3.fromRGB(30,48,78)
tab.Parent=gui
local panel=Instance.new("Frame")
panel.Size=UDim2.new(0,200,0,150)
panel.Position=UDim2.new(0,110,0,174)
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
    return string.format("Pontos visitados: %d / %d\nCréditos: %d%s",data.Count,data.Goal,data.Credits,data.Claimed and " · Resgatado!" or "")
end
remote.OnClientEvent:Connect(function(data)
    ready=true
    text.Text=render(data)
end)
local claim = Instance.new("TextButton")
claim.Size = UDim2.new(1,-20,0,32)
claim.Position = UDim2.new(0,10,1,-40)
claim.Text = "Resgatar recompensa"
claim.TextColor3 = Color3.new(1,1,1)
claim.BackgroundColor3 = Color3.fromRGB(105,65,200)
claim.Parent = panel
claim.Activated:Connect(function() remote:FireServer("Claim") end)
remote.OnClientEvent:Connect(function(data)
    claim.Text = data.Claimed and "Recompensa resgatada" or (data.Count >= data.Goal and "Resgatar 100 créditos" or "Explore os 3 pontos")
    claim.Active = not data.Claimed and data.Count >= data.Goal
    claim.AutoButtonColor = claim.Active
end)

task.spawn(function()
    repeat remote:FireServer("Get"); task.wait(2) until ready
end)
]==])
shared.Parent=RS
world.Parent=workspace
client.Parent=SPS
server.Parent=SSS
print("Missão de exploração instalado. Salve o projeto e dê Play.")
