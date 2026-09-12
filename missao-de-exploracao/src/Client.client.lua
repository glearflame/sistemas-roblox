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
