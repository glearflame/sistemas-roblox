local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local player=Players.LocalPlayer
local shared=RS:WaitForChild("GlearAdvanced")
local command,stateRemote=shared.Command,shared.State
local gui=Instance.new("ScreenGui"); gui.Name="GlearAdvancedUI"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local function label(parent,text,height)
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-12,0,height or 38)
    l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(210,225,248)
    l.Font=Enum.Font.Gotham; l.TextSize=14; l.TextWrapped=true; l.TextXAlignment=Enum.TextXAlignment.Left
    l.Text=text; l.Parent=parent; return l
end
local function button(parent,text,callback)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-12,0,40)
    b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextWrapped=true
    b.TextColor3=Color3.new(1,1,1); b.BackgroundColor3=Color3.fromRGB(39,85,145)
    b.BorderSizePixel=0; b.Parent=parent; b.Activated:Connect(callback); return b
end
local open=button(gui,"KIT AVANÇADO",function() end)
open.Size=UDim2.new(0,150,0,40); open.Position=UDim2.new(1,-162,0,10)
local panel=Instance.new("Frame"); panel.Size=UDim2.new(.92,0,.78,0)
panel.AnchorPoint=Vector2.new(.5,.5); panel.Position=UDim2.fromScale(.5,.5)
panel.BackgroundColor3=Color3.fromRGB(13,22,36); panel.BorderSizePixel=0; panel.Visible=false; panel.Parent=gui
local constraint=Instance.new("UISizeConstraint"); constraint.MaxSize=Vector2.new(820,620); constraint.Parent=panel
local title=label(panel,"GLEAR / KIT DE SISTEMAS",38); title.Position=UDim2.new(0,14,0,6)
title.Size=UDim2.new(1,-64,0,38); title.Font=Enum.Font.GothamBold
local close=button(panel,"×",function() panel.Visible=false end)
close.Size=UDim2.new(0,36,0,34); close.Position=UDim2.new(1,-44,0,8)
open.Activated:Connect(function() panel.Visible=not panel.Visible end)
local stats=label(panel,"Carregando progresso...",44); stats.Position=UDim2.new(0,14,0,48)
local tabs=Instance.new("Frame"); tabs.Size=UDim2.new(1,-28,0,42); tabs.Position=UDim2.new(0,14,0,96); tabs.BackgroundTransparency=1; tabs.Parent=panel
local pages={}
for i,name in ipairs({"Loja","Missões","Combate","Ondas","Construir"}) do
    local page=Instance.new("ScrollingFrame"); page.Name=name
    page.Size=UDim2.new(1,-28,1,-214); page.Position=UDim2.new(0,14,0,150)
    page.BackgroundTransparency=1; page.BorderSizePixel=0; page.ScrollBarThickness=5
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.CanvasSize=UDim2.new(0,0,0,0)
    page.Visible=i==1; page.Parent=panel; pages[name]=page
    local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,10); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=page
    local tab=button(tabs,name,function()
        for key,value in pairs(pages) do value.Visible=key==name end
    end)
    tab.Size=UDim2.new(.2,-4,1,0); tab.Position=UDim2.new((i-1)*.2,0,0,0); tab.TextSize=12
end
local notice=label(panel,"Entre na arena pela aba Ondas para começar.",56)
notice.Position=UDim2.new(0,14,1,-60); notice.TextColor3=Color3.fromRGB(255,210,120)
local function send(action,payload) command:FireServer(action,payload) end
local shopInfo=label(pages.Loja,"Moedas, inventário e melhorias",50)
local shopButtons={}
for _,item in ipairs({{"potion","Comprar poção"},{"blade","Comprar lâmina"},{"armor","Comprar armadura"}}) do
    local id=item[1]
    shopButtons[id]=button(pages.Loja,item[2],function() send("Buy",id) end)
end
label(pages.Loja,"A lâmina adiciona 10 de dano. A armadura reduz o dano dos inimigos em 20%. A poção recupera 50 de vida e é consumida.",80)
button(pages.Loja,"Usar poção [H]",function() send("Potion") end)
local quest=label(pages["Missões"],"Sua campanha",150)
button(pages["Missões"],"Resgatar etapa concluída",function() send("Claim") end)
label(pages["Missões"],"Os objetivos contam apenas depois que a etapa está liberada. Resgate cada etapa para abrir a próxima.",70)
local combatInfo=label(pages.Combate,"Habilidades",50)
local skillButtons={}
for _,entry in ipairs({{"slash","Golpe [F]"},{"pulse","Pulso [Q]"},{"guard","Defesa [E]"}}) do
    local id=entry[1]
    skillButtons[id]=button(pages.Combate,entry[2],function() send("Skill",id) end)
end
label(pages.Combate,"Golpe: alvo mais próximo à frente. Pulso: área ao redor. Defesa: reduz o dano recebido por 2 segundos. Só atinge os inimigos da sua arena.",95)
local waveInfo=label(pages.Ondas,"Partida",90)
button(pages.Ondas,"Entrar / voltar à minha arena",function() send("Enter") end)
button(pages.Ondas,"Começar partida de 10 ondas",function() send("Start") end)
label(pages.Ondas,"Inimigos aparecem à frente. Morrer, sair da arena ou voltar pelo botão encerra a partida atual. Moedas e missões ficam preservadas.",100)
local buildInfo=label(pages.Construir,"Construção",55)
local kind,rotation,removing,buildMode="wall",0,false,false
local selection=label(pages.Construir,"Selecionado: Parede",40)
for _,entry in ipairs({{"wall","Parede · 20 moedas"},{"pillar","Pilar · 15 moedas"},{"floor","Piso · 10 moedas"}}) do
    local id=entry[1]
    button(pages.Construir,entry[2],function() kind=id; selection.Text="Selecionado: "..entry[2] end)
end
local toolbar=Instance.new("Frame"); toolbar.Size=UDim2.new(.92,0,100); toolbar.Position=UDim2.new(.5,0,1,-110)
toolbar.AnchorPoint=Vector2.new(.5,0); toolbar.BackgroundColor3=Color3.fromRGB(15,28,44); toolbar.Visible=false; toolbar.Parent=gui
local tbConstraint=Instance.new("UISizeConstraint"); tbConstraint.MaxSize=Vector2.new(600,100); tbConstraint.Parent=toolbar
local instruction=label(toolbar,"Clique ou toque na grade da sua arena.",38); instruction.Position=UDim2.new(0,10,0,0)
local rotate=button(toolbar,"Girar [R]",function() rotation=(rotation+1)%4 end)
rotate.Size=UDim2.new(.33,-10,0,42); rotate.Position=UDim2.new(0,8,0,48)
local remove=button(toolbar,"Remover: não",function() removing=not removing end)
remove.Size=UDim2.new(.34,-10,0,42); remove.Position=UDim2.new(.33,4,0,48)
local ghost=Instance.new("Part"); ghost.Name="BuildPreview"; ghost.Anchored=true
ghost.CanCollide=false; ghost.CanTouch=false; ghost.CanQuery=false; ghost.Transparency=1; ghost.Parent=workspace
local function stopBuild() buildMode=false; toolbar.Visible=false; ghost.Transparency=1 end
local exit=button(toolbar,"Sair",stopBuild); exit.Size=UDim2.new(.33,-10,0,42); exit.Position=UDim2.new(.67,2,0,48)
button(pages.Construir,"Selecionar posição no mapa",function() buildMode=true; toolbar.Visible=true; panel.Visible=false end)
label(pages.Construir,"Grade de 9×9 células, até 30 peças. Gire antes de colocar. Remover devolve metade do custo. Não é possível construir no terreno de outro jogador.",105)
local latest,cellX,cellZ=nil,nil,nil
local buildMessage,buildMessageUntil="",0
local phaseNames={Idle="Parada",Break="Intervalo",Combat="Em combate",Victory="Vitória",Defeat="Derrota"}
stateRemote.OnClientEvent:Connect(function(data)
    if not data.Ready then return end
    latest=data
    stats.Text=string.format("%d moedas  |  Vida: %d  |  Energia: %d",data.Coins,data.Health,data.Energy)
    shopInfo.Text=string.format("Poções: %d  ·  Lâmina: %s  ·  Armadura: %s",data.Items.potion,data.Items.blade>0 and "sim" or "não",data.Items.armor>0 and "sim" or "não")
    for id,b in pairs(shopButtons) do local item=data.Catalog[id]; b.Text=item.Name.." · "..item.Price.." moedas" end
    local q=data.Quest
    quest.Text=string.format("%s\n%s\nProgresso: %d / %d\nRecompensa: %d moedas",q.Name,q.Hint,q.Progress,q.Goal,q.Reward)
    combatInfo.Text=string.format("Energia: %d / 100 · Defesa: %.1fs",data.Energy,data.Guard)
    for id,b in pairs(skillButtons) do
        local left=data.Cooldowns[id] or 0
        local names={slash="Golpe [F]",pulse="Pulso [Q]",guard="Defesa [E]"}
        b.Text=names[id]..(left>0 and string.format(" · %.1fs",left) or " · pronto")
    end
    waveInfo.Text=string.format("Onda %d / 10 · %s\nInimigos: %d%s",data.Wave,phaseNames[data.Phase] or data.Phase,data.Enemies,data.Phase=="Break" and (" · Próxima em "..data.BreakLeft.."s") or "")
    buildInfo.Text=string.format("%d / 30 peças · %d moedas",data.PieceCount,data.Coins)
    if data.Message then
        notice.Text=data.Message
        if buildMode then buildMessage=data.Message; buildMessageUntil=os.clock()+3 end
    end
    if not data.InArena and buildMode then stopBuild() end
end)
local function aim(position)
    if not latest or not latest.InArena then return nil end
    local camera=workspace.CurrentCamera; if not camera then return nil end
    local inset=GuiService:GetGuiInset()
    local ray=camera:ViewportPointToRay(position.X-inset.X,position.Y-inset.Y)
    -- Intersect the placement plane. Server independently checks owner, bounds and distance.
    if math.abs(ray.Direction.Y)<.001 then return nil end
    local t=(latest.Origin.Y-ray.Origin.Y)/ray.Direction.Y
    if t<=0 or t>300 then return nil end
    local point=ray.Origin+ray.Direction*t
    local x=math.floor((point.X-latest.Origin.X)/4+.5)
    local z=math.floor((point.Z-latest.Origin.Z)/4+.5)
    if math.abs(x)>4 or math.abs(z)>4 then return nil end
    return x,z
end
local pointer=UIS:GetMouseLocation()
UIS.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement then pointer=Vector2.new(input.Position.X,input.Position.Y) end
end)
RunService.RenderStepped:Connect(function()
    if not buildMode or not latest then return end
    if not UIS.TouchEnabled then pointer=UIS:GetMouseLocation() end
    cellX,cellZ=aim(pointer)
    remove.Text=removing and "Remover: sim" or "Remover: não"
    if not cellX then ghost.Transparency=1; instruction.Text=os.clock()<buildMessageUntil and buildMessage or "Aponte para a grade da sua arena."; return end
    local occupied=latest.Cells[cellX..":"..cellZ]~=nil
    ghost.Size=kind=="wall" and Vector3.new(4,7,1) or (kind=="pillar" and Vector3.new(2,9,2) or Vector3.new(4,.5,4))
    ghost.CFrame=CFrame.new(latest.Origin+Vector3.new(cellX*4,ghost.Size.Y/2,cellZ*4))*CFrame.Angles(0,rotation*math.pi/2,0)
    ghost.Transparency=.55; ghost.Color=(removing or occupied) and Color3.fromRGB(235,85,95) or Color3.fromRGB(70,220,170)
    instruction.Text=os.clock()<buildMessageUntil and buildMessage or string.format("Célula %d, %d · rotação %d° · %s",cellX,cellZ,rotation*90,removing and "remover" or "colocar")
end)
local presses={}
UIS.InputBegan:Connect(function(input,processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if buildMode then
        if input.KeyCode==Enum.KeyCode.R then rotation=(rotation+1)%4 end
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            presses[input]=Vector2.new(input.Position.X,input.Position.Y)
        end
    else
        local shortcuts={[Enum.KeyCode.F]="slash",[Enum.KeyCode.Q]="pulse",[Enum.KeyCode.E]="guard"}
        if shortcuts[input.KeyCode] then send("Skill",shortcuts[input.KeyCode]) end
        if input.KeyCode==Enum.KeyCode.H then send("Potion") end
    end
end)
UIS.InputEnded:Connect(function(input)
    local began=presses[input]; presses[input]=nil
    if not began or not buildMode then return end
    local ended=Vector2.new(input.Position.X,input.Position.Y)
    if (ended-began).Magnitude>12 then return end
    local x,z=aim(ended)
    if x then send(removing and "Remove" or "Place",{X=x,Z=z,Kind=kind,Rotation=rotation}) end
end)
player.CharacterAdded:Connect(stopBuild)
UIS.WindowFocusReleased:Connect(function() presses={} end)
task.spawn(function()
    repeat send("Get"); task.wait(2) until latest
end)
