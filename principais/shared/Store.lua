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
