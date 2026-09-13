local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local modules=script.Parent
local Economy=require(modules.Economy)
local Campaign=require(modules.Campaign)
local Combat=require(modules.Combat)
local Waves=require(modules.Waves)
local Building=require(modules.Building)
local Config=require(modules.Config)
local Store=require(modules.Store)
local shared=RS:WaitForChild("GlearAdvanced")
local command,stateRemote=shared.Command,shared.State
local world=workspace:WaitForChild("GlearAdvancedDemo")
local sessions,loading,closing,slots,limits={},{},{},{},{}
local shuttingDown=false
local departures=0

local function part(parent,name,size,cf,color)
    local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf
    p.Anchored=true; p.Color=color; p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent; return p
end
local function billboard(p,text)
    local b=Instance.new("BillboardGui"); b.Size=UDim2.new(0,190,0,45)
    b.StudsOffset=Vector3.new(0,4,0); b.Parent=p
    local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1; label.TextColor3=Color3.new(1,1,1)
    label.TextStrokeTransparency=.25; label.TextSize=15; label.Text=text; label.Parent=b
    return label
end
local function character(player)
    local c=player.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    local root=c and c:FindFirstChild("HumanoidRootPart")
    if not h or h.Health<=0 or not root then return nil end
    return c,h,root
end
local function inArena(player,s)
    local c,h,r=character(player)
    if not c then return nil end
    local d=r.Position-s.Origin
    if math.abs(d.X)>54 or math.abs(d.Z)>54 or math.abs(d.Y)>30 then return nil end
    return c,h,r
end
local function allowed(player)
    local now=os.clock(); local b=limits[player] or {Tokens=16,Time=now}; limits[player]=b
    b.Tokens=math.min(16,b.Tokens+(now-b.Time)*8); b.Time=now
    if b.Tokens<1 then return false end
    b.Tokens=b.Tokens-1; return true
end
local function send(player,message)
    local s=sessions[player]
    if not s or closing[player] or not player.Parent then return end
    local _,h=inArena(player,s)
    local cooldowns={}
    for id,t in pairs(s.Combat.Ready) do cooldowns[id]=math.max(0,t-os.clock()) end
    stateRemote:FireClient(player,{
        Ready=true,Message=message,Coins=s.Profile.Economy.Coins,Items=s.Profile.Economy.Items,
        Catalog=Economy.Catalog,Quest=Campaign.View(s.Profile.Campaign),Energy=math.floor(s.Combat.Energy),
        Health=h and math.ceil(h.Health) or 0,InArena=h~=nil,Cooldowns=cooldowns,
        Wave=s.Waves.Wave,Phase=s.Waves.Phase,Enemies=s.Waves.Alive,
        BreakLeft=math.max(0,math.ceil(s.Waves.NextAt-os.clock())),
        Origin=s.BuildOrigin,Cells=s.Profile.Build.Cells,PieceCount=s.Profile.Build.Count,
        Pieces=Building.Pieces,Guard=math.max(0,s.Combat.GuardUntil-os.clock()),
    })
end
local function createPiece(s,key,cell)
    local size=cell.Kind=="wall" and Vector3.new(4,7,1) or (cell.Kind=="pillar" and Vector3.new(2,9,2) or Vector3.new(4,.5,4))
    local position=s.BuildOrigin+Vector3.new(cell.X*4,size.Y/2,cell.Z*4)
    local p=part(s.Pieces,key,size,CFrame.new(position)*CFrame.Angles(0,cell.Rotation*math.pi/2,0),Color3.fromRGB(70,135,175))
    p:SetAttribute("GlearPiece",true)
end
local function clearEnemies(s)
    for _,enemy in pairs(s.Enemies) do enemy.Part:Destroy() end
    s.Enemies={}
end
local function fail(s)
    Waves.Fail(s.Waves); clearEnemies(s)
end
local function createArena(player,profile,slot)
    local folder=Instance.new("Folder"); folder.Name=tostring(player.UserId); folder.Parent=world
    local origin=Config.ArenaOrigin+Vector3.new((slot-1)*Config.ArenaSpacing,0,0)
    part(folder,"Arena",Vector3.new(110,1,110),CFrame.new(origin-Vector3.new(0,.5,0)),Color3.fromRGB(25,32,49))
    local buildOrigin=origin+Vector3.new(0,.1,27)
    local grid=part(folder,"BuildGrid",Vector3.new(36,.15,36),CFrame.new(buildOrigin-Vector3.new(0,.075,0)),Color3.fromRGB(35,72,80))
    grid:SetAttribute("BuildOwner",player.UserId)
    billboard(grid,"CONSTRUÇÃO · "..player.DisplayName)
    local pieces=Instance.new("Folder"); pieces.Name="Pieces"; pieces.Parent=folder
    -- Thin grid lines are cosmetic; authoritative occupancy lives in the profile.
    for index=-4,5 do
        local offset=index*4-2
        for _,axis in ipairs({"X","Z"}) do
            local size=axis=="X" and Vector3.new(.04,.02,36) or Vector3.new(36,.02,.04)
            local delta=axis=="X" and Vector3.new(offset,0,0) or Vector3.new(0,0,offset)
            local line=part(folder,"GridLine",size,CFrame.new(buildOrigin+delta),Color3.fromRGB(75,122,130))
            line.CanCollide=false; line.CanQuery=false
        end
    end
    local s={Profile=profile,Slot=slot,Folder=folder,Origin=origin,BuildOrigin=buildOrigin,Pieces=pieces,
        Combat=Combat.New(),Waves=Waves.New(),Enemies={},EnemyID=0,Token=HttpService:GenerateGUID(false),PotionAt=0}
    for key,cell in pairs(profile.Build.Cells) do createPiece(s,key,cell) end
    return s
end
local function loaded(player)
    if sessions[player] or loading[player] or closing[player] or shuttingDown then return end
    loading[player]=true
    local slot
    for i=1,Config.MaxArenas do if not slots[i] then slot=i; slots[i]=player; break end end
    if not slot then loading[player]=nil; player:Kick("Esta demonstração suporta até "..Config.MaxArenas.." arenas. Tente outro servidor."); return end
    local profile=Store.Load(player)
    if not profile then slots[slot]=nil; loading[player]=nil; player:Kick("Não foi possível carregar o progresso. Nenhum dado foi substituído. Tente novamente."); return end
    if not player.Parent or closing[player] or shuttingDown then
        Store.Save(player,profile,true); slots[slot]=nil; loading[player]=nil; return
    end
    sessions[player]=createArena(player,profile,slot)
    player.CharacterAdded:Connect(function()
        local s=sessions[player]
        if s then s.Combat=Combat.New(); fail(s) end
    end)
    loading[player]=nil
    send(player,"Kit pronto. Abra o painel e entre na sua arena.")
end
local function removed(player)
    departures=departures+1
    if closing[player] then
        while closing[player] do task.wait(.1) end
        departures=departures-1; return
    end
    closing[player]=true
    while loading[player] do task.wait(.1) end
    local s=sessions[player]
    if s then
        clearEnemies(s)
        if not Store.Save(player,s.Profile,true) then warn("[GlearAdvanced] Salvamento final falhou: "..player.UserId) end
        s.Folder:Destroy(); slots[s.Slot]=nil
    end
    sessions[player]=nil; closing[player]=nil; limits[player]=nil
    departures=departures-1
end
local function spawnWave(s,spec)
    for i=1,spec.Count do
        s.EnemyID=s.EnemyID+1
        local angle=(i/spec.Count)*math.pi*2
        local pos=s.Origin+Vector3.new(math.cos(angle)*25,2.5,-22+math.sin(angle)*14)
        local p=part(s.Folder,"Enemy",Vector3.new(3,4,3),CFrame.new(pos),Color3.fromRGB(200,65,95))
        p.CanCollide=false
        local hp=billboard(p,tostring(spec.Health).." HP")
        s.Enemies[s.EnemyID]={Part=p,Health=spec.Health,Speed=spec.Speed,Damage=spec.Damage,AttackAt=0,Label=hp}
    end
end
local function lineOfSight(c,root,enemy)
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={c}
    local hit=workspace:Raycast(root.Position,enemy.Part.Position-root.Position,params)
    return not hit or hit.Instance==enemy.Part
end
local function useSkill(player,s,id)
    local c,_,root=inArena(player,s)
    if not c then return false,"Entre na arena primeiro." end
    local ok,skill=Combat.Cast(s.Combat,id,os.clock())
    if not ok then return false,skill end
    if id=="guard" then return true,"Defesa ativa por 2 segundos." end
    local targets={}
    for key,enemy in pairs(s.Enemies) do
        local delta=enemy.Part.Position-root.Position
        local facing=delta.Magnitude<.1 or root.CFrame.LookVector:Dot(delta.Unit)>.05
        if delta.Magnitude<=skill.Range and (id=="pulse" or facing) and lineOfSight(c,root,enemy) then
            table.insert(targets,{ID=key,Enemy=enemy,Distance=delta.Magnitude})
        end
    end
    table.sort(targets,function(a,b) return a.Distance<b.Distance end)
    local hit=0
    for index,target in ipairs(targets) do
        if id=="slash" and index>1 then break end
        local enemy=target.Enemy
        local damage=skill.Damage+(s.Profile.Economy.Items.blade>0 and 10 or 0)
        enemy.Health=enemy.Health-damage; hit=hit+1
        if enemy.Health<=0 then
            enemy.Part:Destroy(); s.Enemies[target.ID]=nil
            Campaign.Record(s.Profile.Campaign,"Kill")
            Economy.Reward(s.Profile.Economy,8,"kill:"..s.Token..":"..target.ID)
            local complete,reward=Waves.Kill(s.Waves,os.clock())
            if complete then
                Economy.Reward(s.Profile.Economy,reward,"wave:"..s.Token..":"..s.Waves.Run..":"..s.Waves.Wave)
                Campaign.Record(s.Profile.Campaign,"Wave")
            end
        else enemy.Label.Text=math.ceil(enemy.Health).." HP" end
    end
    return true,hit>0 and ("Acertou "..hit.." alvo(s).") or "Nenhum alvo no alcance."
end
local function build(player,s,action,payload)
    local c,_,root=inArena(player,s)
    if not c then return false,"Entre na arena primeiro." end
    if type(payload)~="table" then return false,"Posição inválida." end
    local x,z=payload.X,payload.Z
    if not Economy.Integer(x,-4,4) or not Economy.Integer(z,-4,4) then return false,"Fora da grade." end
    local target=s.BuildOrigin+Vector3.new(x*4,0,z*4)
    if (root.Position-target).Magnitude>32 then return false,"Chegue mais perto da grade." end
    if action=="Place" then
        -- Do not trap a character inside a newly created piece.
        for _,other in ipairs(Players:GetPlayers()) do
            local _,_,otherRoot=character(other)
            if otherRoot and math.abs(otherRoot.Position.X-target.X)<3 and math.abs(otherRoot.Position.Z-target.Z)<3 and math.abs(otherRoot.Position.Y-target.Y)<10 then
                return false,"Há um jogador nessa célula."
            end
        end
        local ok,key=Building.Place(s.Profile.Build,s.Profile.Economy,payload.Kind,x,z,payload.Rotation)
        if not ok then return false,key end
        createPiece(s,key,s.Profile.Build.Cells[key]); Campaign.Record(s.Profile.Campaign,"Build")
        return true,"Peça colocada."
    end
    local ok,key=Building.Remove(s.Profile.Build,s.Profile.Economy,x,z)
    if ok then local p=s.Pieces:FindFirstChild(key); if p then p:Destroy() end; return true,"Peça removida: devolução de 50%." end
    return false,key
end
command.OnServerEvent:Connect(function(player,action,payload)
    if shuttingDown or closing[player] or type(action)~="string" or #action>20 or not allowed(player) then return end
    local s=sessions[player]
    if not s then return end
    if action=="Get" then send(player); return end
    local ok,message=false,"Ação desconhecida."
    if action=="Enter" then
        local c,h=character(player)
        if c then fail(s); s.Combat=Combat.New(); c:PivotTo(CFrame.new(s.Origin+Vector3.new(0,5,0))); ok=true; message="Sua arena. A grade fica atrás; os inimigos aparecem à frente." end
    elseif action=="Buy" then
        ok,message=Economy.Buy(s.Profile.Economy,payload)
        if ok then Campaign.Record(s.Profile.Campaign,"Buy") end
    elseif action=="Potion" then
        local _,h=inArena(player,s)
        if not h then message="Entre na arena primeiro."
        elseif h.Health>=h.MaxHealth then message="Sua vida já está cheia."
        elseif os.clock()<s.PotionAt then message="Aguarde antes de usar outra poção."
        else ok,message=Economy.UsePotion(s.Profile.Economy); if ok then h.Health=math.min(h.MaxHealth,h.Health+50); s.PotionAt=os.clock()+2; message="50 de vida recuperados." end end
    elseif action=="Claim" then ok,message=Campaign.Claim(s.Profile.Campaign,s.Profile.Economy,Economy.Reward)
    elseif action=="Start" then
        if inArena(player,s) then ok=Waves.Start(s.Waves,os.clock()); message=ok and "Prepare-se: primeira onda em 3 segundos." or "A partida já está em andamento."
        else message="Entre na arena primeiro." end
    elseif action=="Skill" then ok,message=useSkill(player,s,payload)
    elseif action=="Place" or action=="Remove" then ok,message=build(player,s,action,payload) end
    send(player,message)
end)
local publishElapsed=0
RunService.Heartbeat:Connect(function(dt)
    publishElapsed=publishElapsed+dt
    local publish=publishElapsed>=.25; if publish then publishElapsed=0 end
    local now=os.clock()
    for player,s in pairs(sessions) do
        if not closing[player] then
            Combat.Tick(s.Combat,dt)
            local c,h,root=inArena(player,s)
            if not h then fail(s) else
                local spec=Waves.Tick(s.Waves,now); if spec then spawnWave(s,spec) end
                for _,enemy in pairs(s.Enemies) do
                    local pos=enemy.Part.Position
                    local delta=Vector3.new(root.Position.X-pos.X,0,root.Position.Z-pos.Z)
                    if delta.Magnitude>3 then
                        local stride=math.min(delta.Magnitude-3,enemy.Speed*math.min(dt,.2))
                        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
                        local ignored={c}
                        for _,other in pairs(s.Enemies) do table.insert(ignored,other.Part) end
                        params.FilterDescendantsInstances=ignored
                        -- Simple obstacle steering for a flat arena, not full pathfinding.
                        for _,angle in ipairs({0,45,-45,90,-90}) do
                            local direction=CFrame.Angles(0,math.rad(angle),0):VectorToWorldSpace(delta.Unit)
                            if not workspace:Raycast(pos,direction*(stride+2),params) then
                                local nextPosition=pos+direction*stride
                                enemy.Part.CFrame=CFrame.lookAt(nextPosition,Vector3.new(root.Position.X,pos.Y,root.Position.Z))
                                break
                            end
                        end
                    elseif now>=enemy.AttackAt and math.abs(root.Position.Y-pos.Y)<6 and lineOfSight(c,root,enemy) then
                        enemy.AttackAt=now+1.1
                        h:TakeDamage(Combat.Incoming(s.Combat,enemy.Damage,now,s.Profile.Economy.Items.armor>0))
                    end
                end
            end
            if publish then send(player) end
        end
    end
end)
Players.PlayerAdded:Connect(loaded)
Players.PlayerRemoving:Connect(removed)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(loaded,player) end
task.spawn(function()
    while not shuttingDown do
        task.wait(Config.SaveInterval)
        if shuttingDown then break end
        for player,s in pairs(sessions) do
            task.spawn(function()
                if not closing[player] and not Store.Save(player,s.Profile,false) then warn("[GlearAdvanced] Salvamento pendente: "..player.UserId) end
            end)
        end
    end
end)
game:BindToClose(function()
    shuttingDown=true
    local pending=0
    for _,player in ipairs(Players:GetPlayers()) do
        pending=pending+1
        task.spawn(function() removed(player); pending=pending-1 end)
    end
    local untilTime=os.clock()+25
    while (pending>0 or departures>0) and os.clock()<untilTime do task.wait(.1) end
end)
