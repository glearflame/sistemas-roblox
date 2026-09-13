-- GLEAR ADVANCED: cole todo este arquivo na Command Bar, com o Play parado.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Use a Command Bar fora do Play")
local SSS=game:GetService("ServerScriptService")
local RS=game:GetService("ReplicatedStorage")
local SPS=game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
for _,entry in ipairs({{SSS,"GlearAdvanced"},{RS,"GlearAdvanced"},{SPS,"GlearAdvanced"},{workspace,"GlearAdvancedDemo"}}) do
    assert(not entry[1]:FindFirstChild(entry[2]),"Já existe "..entry[2].."; instalação cancelada")
end
local function folder(name) local f=Instance.new("Folder"); f.Name=name; return f end
local server,shared,client,world=folder("GlearAdvanced"),folder("GlearAdvanced"),folder("GlearAdvanced"),folder("GlearAdvancedDemo")
for _,name in ipairs({"Command","State"}) do local r=Instance.new("RemoteEvent"); r.Name=name; r.Parent=shared end
local function source(class,parent,name,content)
    local s=Instance.new(class); s.Name=name; s.Source=content; s.Parent=parent
end

source("ModuleScript",server,"Economy",[==[
local M = {}
M.Catalog = {
    potion = {Name="Poção de cura", Price=25, Max=10},
    blade = {Name="Lâmina aprimorada", Price=120, Max=1},
    armor = {Name="Armadura leve", Price=100, Max=1},
}
function M.Integer(n, low, high)
    return type(n)=="number" and n==n and n>=low and n<=high and n%1==0
end
function M.New() return {Coins=250,Items={potion=1,blade=0,armor=0},Receipts={}} end
function M.Validate(s)
    assert(type(s)=="table" and M.Integer(s.Coins,0,100000000),"Saldo inválido")
    assert(type(s.Items)=="table" and type(s.Receipts)=="table","Inventário inválido")
    for id,item in pairs(M.Catalog) do assert(M.Integer(s.Items[id],0,item.Max),"Quantidade inválida") end
    assert(#s.Receipts<=64,"Histórico inválido")
    for _,id in ipairs(s.Receipts) do assert(type(id)=="string" and #id<=100,"Recibo inválido") end
    return s
end
function M.Buy(s,id)
    local item=type(id)=="string" and M.Catalog[id]
    if not item then return false,"Item desconhecido." end
    if s.Items[id]>=item.Max then return false,"Limite desse item atingido." end
    if s.Coins<item.Price then return false,"Moedas insuficientes." end
    s.Coins=s.Coins-item.Price
    s.Items[id]=s.Items[id]+1
    return true,"Compra concluída."
end
function M.UsePotion(s)
    if s.Items.potion<1 then return false,"Você não tem poções." end
    s.Items.potion=s.Items.potion-1
    return true
end
function M.Reward(s,amount,receipt)
    if not M.Integer(amount,1,100000) or type(receipt)~="string" or #receipt>100 then return false end
    for _,id in ipairs(s.Receipts) do if id==receipt then return false end end
    if s.Coins+amount>100000000 then return false end
    s.Coins=s.Coins+amount
    table.insert(s.Receipts,receipt)
    if #s.Receipts>64 then table.remove(s.Receipts,1) end
    return true
end
return M

]==])

source("ModuleScript",server,"Campaign",[==[
local M = {}
M.Steps = {
    {Name="Prepare a mochila",Event="Buy",Goal=1,Reward=50,Hint="Compre qualquer item na loja."},
    {Name="Primeiro confronto",Event="Kill",Goal=3,Reward=100,Hint="Derrote 3 inimigos nas ondas."},
    {Name="Seu primeiro abrigo",Event="Build",Goal=2,Reward=150,Hint="Coloque 2 peças na área de construção."},
    {Name="Segure a posição",Event="Wave",Goal=2,Reward=250,Hint="Conclua mais 2 ondas depois de liberar esta etapa."},
}
function M.New() return {Stage=1,Progress=0} end
function M.Validate(s)
    assert(type(s)=="table" and type(s.Stage)=="number" and s.Stage%1==0 and s.Stage>=1 and s.Stage<=#M.Steps+1,"Etapa inválida")
    local goal=M.Steps[s.Stage] and M.Steps[s.Stage].Goal or 0
    assert(type(s.Progress)=="number" and s.Progress%1==0 and s.Progress>=0 and s.Progress<=goal,"Progresso inválido")
    return s
end
function M.Record(s,event)
    local step=M.Steps[s.Stage]
    if not step or step.Event~=event or s.Progress>=step.Goal then return false end
    s.Progress=s.Progress+1
    return true
end
function M.Claim(s,wallet,reward)
    local step=M.Steps[s.Stage]
    if not step or s.Progress<step.Goal then return false,"Objetivo ainda incompleto." end
    if not reward(wallet,step.Reward,"campaign:"..s.Stage) then return false,"Recompensa indisponível." end
    s.Stage=s.Stage+1
    s.Progress=0
    return true,"Etapa concluída!"
end
function M.View(s)
    local step=M.Steps[s.Stage]
    return {Stage=s.Stage,Progress=s.Progress,Goal=step and step.Goal or 0,
        Name=step and step.Name or "Campanha concluída!",Hint=step and step.Hint or "Você concluiu as quatro etapas.",
        Reward=step and step.Reward or 0,Done=step==nil}
end
return M

]==])

source("ModuleScript",server,"Combat",[==[
local M = {}
M.Skills = {
    slash={Name="Golpe",Cost=0,Cooldown=0.6,Damage=22,Range=10},
    pulse={Name="Pulso",Cost=35,Cooldown=5,Damage=35,Range=17},
    guard={Name="Defesa",Cost=25,Cooldown=8,Damage=0,Range=0},
}
function M.New() return {Energy=100,Ready={},GuardUntil=0} end
function M.Tick(s,dt)
    if type(dt)~="number" or dt~=dt or dt<0 or dt==math.huge then return end
    s.Energy=math.min(100,s.Energy+math.min(dt,1)*12)
end
function M.Cast(s,id,now)
    local skill=type(id)=="string" and M.Skills[id]
    if not skill then return false,"Habilidade desconhecida." end
    if now<(s.Ready[id] or 0) then return false,"Habilidade em recarga." end
    if s.Energy<skill.Cost then return false,"Energia insuficiente." end
    s.Energy=s.Energy-skill.Cost
    s.Ready[id]=now+skill.Cooldown
    if id=="guard" then s.GuardUntil=now+2 end
    return true,skill
end
function M.Incoming(s,damage,now,armor)
    local scale=armor and 0.8 or 1
    if now<s.GuardUntil then scale=scale*0.35 end
    return math.max(1,math.floor(damage*scale+0.5))
end
return M

]==])

source("ModuleScript",server,"Waves",[==[
local M = {MaxWave=10,Intermission=7,MaxActive=18}
function M.New() return {Phase="Idle",Wave=0,Alive=0,NextAt=0,Run=0} end
function M.Start(s,now)
    if s.Phase~="Idle" and s.Phase~="Defeat" and s.Phase~="Victory" then return false end
    s.Run=s.Run+1
    s.Phase="Break"; s.Wave=0; s.Alive=0; s.NextAt=now+3
    return true
end
function M.Tick(s,now)
    if s.Phase~="Break" or now<s.NextAt then return nil end
    s.Wave=s.Wave+1
    s.Phase="Combat"
    s.Alive=math.min(M.MaxActive,2+s.Wave*2)
    return {Count=s.Alive,Health=45+s.Wave*9,Speed=6+s.Wave*0.4,Damage=6+s.Wave}
end
function M.Kill(s,now)
    if s.Phase~="Combat" or s.Alive<=0 then return false,0 end
    s.Alive=s.Alive-1
    if s.Alive>0 then return false,0 end
    if s.Wave>=M.MaxWave then s.Phase="Victory" else s.Phase="Break"; s.NextAt=now+M.Intermission end
    return true,30+s.Wave*10
end
function M.Fail(s)
    if s.Phase=="Combat" or s.Phase=="Break" then s.Phase="Defeat"; s.Alive=0 end
end
return M

]==])

source("ModuleScript",server,"Building",[==[
local M = {Size=4,Limit=30,MaxCell=4}
M.Pieces={wall={Name="Parede",Cost=20},pillar={Name="Pilar",Cost=15},floor={Name="Piso",Cost=10}}
local function integer(n,lo,hi) return type(n)=="number" and n==n and n%1==0 and n>=lo and n<=hi end
function M.New() return {Cells={},Count=0} end
function M.Key(x,z) return x..":"..z end
function M.Place(s,wallet,kind,x,z,rotation)
    local piece=type(kind)=="string" and M.Pieces[kind]
    if not piece or not integer(x,-M.MaxCell,M.MaxCell) or not integer(z,-M.MaxCell,M.MaxCell) or not integer(rotation,0,3) then return false,"Posição ou peça inválida." end
    local key=M.Key(x,z)
    if s.Cells[key] then return false,"Célula ocupada." end
    if s.Count>=M.Limit then return false,"Limite de 30 peças." end
    if wallet.Coins<piece.Cost then return false,"Moedas insuficientes." end
    wallet.Coins=wallet.Coins-piece.Cost
    s.Cells[key]={Kind=kind,X=x,Z=z,Rotation=rotation}
    s.Count=s.Count+1
    return true,key
end
function M.Remove(s,wallet,x,z)
    if not integer(x,-M.MaxCell,M.MaxCell) or not integer(z,-M.MaxCell,M.MaxCell) then return false,"Célula inválida." end
    local key=M.Key(x,z)
    local cell=s.Cells[key]
    if not cell then return false,"Nenhuma peça nesta célula." end
    local refund=math.floor(M.Pieces[cell.Kind].Cost/2)
    if wallet.Coins+refund>100000000 then return false,"Saldo máximo atingido." end
    s.Cells[key]=nil; s.Count=s.Count-1; wallet.Coins=wallet.Coins+refund
    return true,key
end
function M.Validate(s)
    assert(type(s)=="table" and type(s.Cells)=="table","Construção inválida")
    local count=0
    for key,c in pairs(s.Cells) do
        assert(type(c)=="table" and M.Pieces[c.Kind] and integer(c.X,-4,4) and integer(c.Z,-4,4) and integer(c.Rotation,0,3),"Peça inválida")
        assert(key==M.Key(c.X,c.Z),"Célula inconsistente")
        count=count+1
    end
    assert(count<=M.Limit and s.Count==count,"Contagem de peças inválida")
    return s
end
return M

]==])

source("ModuleScript",server,"Config",[==[
return {
    StudioPersistence=false,
    SaveInterval=60,
    LeaseSeconds=180,
    MaxArenas=8,
    ArenaSpacing=150,
    ArenaOrigin=Vector3.new(0,80,300),
}

]==])

source("ModuleScript",server,"Store",[==[
local DSS=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Config=require(script.Parent.Config)
local Economy=require(script.Parent.Economy)
local Campaign=require(script.Parent.Campaign)
local Building=require(script.Parent.Building)
local M={}
local temporary=RunService:IsStudio() and not Config.StudioPersistence
local store=not temporary and DSS:GetDataStore(RunService:IsStudio() and "GlearAdvanced_Test_v1" or "GlearAdvanced_v1")
local session=game:GetService("HttpService"):GenerateGUID(false)
local held,busy={},{}
local function clone(value)
    if type(value)~="table" then return value end
    local out={}; for k,v in pairs(value) do out[k]=clone(v) end; return out
end
function M.NewProfile()
    return {Version=1,Economy=Economy.New(),Campaign=Campaign.New(),Build=Building.New()}
end
function M.Validate(data)
    assert(type(data)=="table" and data.Version==1,"Versão de dados desconhecida")
    Economy.Validate(data.Economy); Campaign.Validate(data.Campaign); Building.Validate(data.Build)
    return data
end
local function retry(action)
    for attempt=1,3 do
        local ok,value=pcall(action)
        if ok then return true,value end
        warn("[GlearAdvanced] DataStore tentativa "..attempt..": "..tostring(value))
        if attempt<3 then task.wait(attempt) end
    end
    return false
end
function M.Load(player)
    if temporary then return M.NewProfile() end
    local ok,data=retry(function()
        return store:UpdateAsync(tostring(player.UserId),function(old)
            old=old or M.NewProfile()
            M.Validate(old)
            local lock=old.Session
            if lock then
                assert(type(lock)=="table" and type(lock.ID)=="string" and type(lock.Expires)=="number","Trava inválida")
                if lock.ID~=session and lock.Expires>os.time() then return nil end
            end
            old.Session={ID=session,Expires=os.time()+Config.LeaseSeconds}
            return old
        end)
    end)
    if not ok or not data then return nil end
    held[player]=true
    data.Session=nil
    return data
end
function M.Save(player,data,release)
    if temporary then return true end
    while busy[player] do task.wait(.1) end
    if not held[player] then return false end
    M.Validate(data)
    local snapshot=clone(data)
    busy[player]=true
    local ok,result=retry(function()
        return store:UpdateAsync(tostring(player.UserId),function(old)
            if type(old)~="table" or type(old.Session)~="table" or old.Session.ID~=session then return nil end
            snapshot.Session=nil
            snapshot.SavedAt=os.time()
            if not release then snapshot.Session={ID=session,Expires=os.time()+Config.LeaseSeconds} end
            return snapshot
        end)
    end)
    busy[player]=nil
    if ok and not result then
        held[player]=nil
        player:Kick("Sua sessão mudou. Entre novamente para carregar o progresso.")
    elseif ok and release then held[player]=nil end
    return ok and result~=nil
end
return M

]==])

source("Script",server,"Server",[==[
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

]==])

source("LocalScript",client,"Client",[==[
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

]==])
shared.Parent=RS
world.Parent=workspace
client.Parent=SPS
server.Parent=SSS
print("Glear Advanced instalado. Salve, dê Play e abra KIT AVANÇADO.")
