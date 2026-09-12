-- Corrida com energia: execute na Command Bar do Studio com Play PARADO.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Execute na Command Bar, fora do Play")
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local NS="GlearSprint"
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

source("ModuleScript",server,"Core",[==[
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
]==])
source("Script",server,"Server",[==[
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
]==])
source("LocalScript",client,"Client",[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local NS="GlearSprint"
local remote=RS:WaitForChild(NS):WaitForChild("State")
local gui=Instance.new("ScreenGui")
gui.Name=NS .. "UI"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local tab=Instance.new("TextButton")
tab.Size=UDim2.new(0,94,0,36)
tab.Position=UDim2.new(0,8,0,216)
tab.Text="Corrida"
tab.TextColor3=Color3.new(1,1,1)
tab.BackgroundColor3=Color3.fromRGB(30,48,78)
tab.Parent=gui
local panel=Instance.new("Frame")
panel.Size=UDim2.new(0,200,0,150)
panel.Position=UDim2.new(0,110,0,216)
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
    return string.format("Energia: %d / %d\n%s",data.Energy,data.Max,data.Exhausted and "Recuperando energia..." or (data.Running and "Correndo" or "Shift ou botão Correr"))
end
remote.OnClientEvent:Connect(function(data)
    ready=true
    text.Text=render(data)
end)
local UIS=game:GetService("UserInputService")
local held,toggled=false,false
local function updateRun() remote:FireServer("Run",held or toggled) end
UIS.InputBegan:Connect(function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.LeftShift then held=true; updateRun() end
end)
UIS.InputEnded:Connect(function(input)
    if input.KeyCode==Enum.KeyCode.LeftShift then held=false; updateRun() end
end)
UIS.WindowFocusReleased:Connect(function() held=false; toggled=false; updateRun() end)
player.CharacterAdded:Connect(function() held=false; toggled=false; updateRun() end)
local run=Instance.new("TextButton")
run.Size=UDim2.new(1,-20,0,32)
run.Position=UDim2.new(0,10,1,-40)
run.Text="Correr / Parar"
run.TextColor3=Color3.new(1,1,1)
run.BackgroundColor3=Color3.fromRGB(25,130,105)
run.Parent=panel
run.Activated:Connect(function() toggled=not toggled; updateRun() end)

task.spawn(function()
    repeat remote:FireServer("Get"); task.wait(2) until ready
end)
]==])
shared.Parent=RS
world.Parent=workspace
client.Parent=SPS
server.Parent=SSS
print("Corrida com energia instalado. Salve o projeto e dê Play.")
