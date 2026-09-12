-- Coleta de moedas: execute na Command Bar do Studio com Play PARADO.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Execute na Command Bar, fora do Play")
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local NS="GlearCoins"
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
for i = 1, 5 do
    local p = part("Coin" .. i, Vector3.new(2,2,2), Vector3.new((i-1)*9, 3, -15), Color3.fromRGB(255,205,65))
    p.Shape = Enum.PartType.Ball
    p.CanCollide = false
    prompt(p, "Coletar", "+10 moedas")
end
source("ModuleScript",server,"Core",[==[
local M = { Reward = 10, Cooldown = 20, Count = 5 }
function M.New() return { Balance = 0, NextClaim = {} } end
function M.Claim(state, coin, now)
    if type(coin) ~= "number" or coin % 1 ~= 0 or coin < 1 or coin > M.Count then return false end
    if now < (state.NextClaim[coin] or 0) then return false end
    state.NextClaim[coin] = now + M.Cooldown
    state.Balance = state.Balance + M.Reward
    return true
end
return M
]==])
source("Script",server,"Server",[==[
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
]==])
source("LocalScript",client,"Client",[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local NS="GlearCoins"
local remote=RS:WaitForChild(NS):WaitForChild("State")
local gui=Instance.new("ScreenGui")
gui.Name=NS .. "UI"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local tab=Instance.new("TextButton")
tab.Size=UDim2.new(0,94,0,36)
tab.Position=UDim2.new(0,8,0,132)
tab.Text="Moedas"
tab.TextColor3=Color3.new(1,1,1)
tab.BackgroundColor3=Color3.fromRGB(30,48,78)
tab.Parent=gui
local panel=Instance.new("Frame")
panel.Size=UDim2.new(0,200,0,150)
panel.Position=UDim2.new(0,110,0,132)
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
    return string.format("Saldo: %d moedas\nUse E ou toque nas moedas para coletar.", data.Balance)
end
remote.OnClientEvent:Connect(function(data)
    ready=true
    text.Text=render(data)
end)
local cooldowns = {}
local coinWorld = workspace:WaitForChild(NS .. "Demo")
local function updateCoins(data)
    for i, seconds in pairs(data.Remaining) do cooldowns[i] = os.clock() + seconds end
end
remote.OnClientEvent:Connect(updateCoins)
task.spawn(function()
    while gui.Parent do
        for i = 1, 5 do
            local p = coinWorld:FindFirstChild("Coin" .. i)
            if p then
                local left = math.max(0, math.ceil((cooldowns[i] or 0) - os.clock()))
                p.LocalTransparencyModifier = left > 0 and 0.7 or 0
                local prompt = p:FindFirstChildOfClass("ProximityPrompt")
                if prompt then prompt.ActionText = left > 0 and ("Volta em " .. left .. "s") or "Coletar" end
            end
        end
        task.wait(0.25)
    end
end)

task.spawn(function()
    repeat remote:FireServer("Get"); task.wait(2) until ready
end)
]==])
shared.Parent=RS
world.Parent=workspace
client.Parent=SPS
server.Parent=SSS
print("Coleta de moedas instalado. Salve o projeto e dê Play.")
