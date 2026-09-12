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
