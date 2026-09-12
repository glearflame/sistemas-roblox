-- Ciclo de dia e noite: execute na Command Bar do Studio com Play PARADO.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Execute na Command Bar, fora do Play")
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local NS="GlearDayNight"
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
local M = { StartHour=8, CycleSeconds=600 }
function M.Sample(elapsed)
    assert(type(elapsed)=="number" and elapsed==elapsed and elapsed>=0 and elapsed<math.huge,"Tempo inválido")
    assert(M.CycleSeconds>0,"CycleSeconds deve ser positivo")
    local hour=(M.StartHour+elapsed*24/M.CycleSeconds)%24
    local daylight=math.max(0,math.sin((hour-6)/12*math.pi))
    local minutes=math.floor(hour*60)
    return {Hour=hour,Day=hour>=6 and hour<18,Brightness=0.8+daylight*1.7,Rate=24/M.CycleSeconds,CycleMinutes=M.CycleSeconds/60,
            Label=string.format("%02d:%02d",math.floor(minutes/60),minutes%60)}
end
return M
]==])
source("Script",server,"Server",[==[
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
]==])
source("LocalScript",client,"Client",[==[
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local NS="GlearDayNight"
local remote=RS:WaitForChild(NS):WaitForChild("State")
local gui=Instance.new("ScreenGui")
gui.Name=NS .. "UI"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local tab=Instance.new("TextButton")
tab.Size=UDim2.new(0,94,0,36)
tab.Position=UDim2.new(0,8,0,258)
tab.Text="Relógio"
tab.TextColor3=Color3.new(1,1,1)
tab.BackgroundColor3=Color3.fromRGB(30,48,78)
tab.Parent=gui
local panel=Instance.new("Frame")
panel.Size=UDim2.new(0,200,0,150)
panel.Position=UDim2.new(0,110,0,258)
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
    return string.format("%s · %s\nUm dia completo a cada %g minutos.",data.Label,data.Day and "Dia" or "Noite",data.CycleMinutes)
end
remote.OnClientEvent:Connect(function(data)
    ready=true
    text.Text=render(data)
end)

-- Apply the synchronized clock locally, including properties that do not replicate.
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local sample,received=nil,0
remote.OnClientEvent:Connect(function(data) sample=data; received=os.clock() end)
RunService.RenderStepped:Connect(function()
    if not sample then return end
    local hour=(sample.Hour+(os.clock()-received)*sample.Rate)%24
    Lighting.ClockTime=hour
    Lighting.Brightness=0.8+math.max(0,math.sin((hour-6)/12*math.pi))*1.7
end)
task.spawn(function()
    repeat remote:FireServer("Get"); task.wait(2) until ready
end)
]==])
shared.Parent=RS
world.Parent=workspace
client.Parent=SPS
server.Parent=SSS
print("Ciclo de dia e noite instalado. Salve o projeto e dê Play.")
