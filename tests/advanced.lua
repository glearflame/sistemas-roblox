local tests=0
local function check(value,message) assert(value,message or ("Assertion "..(tests+1))); tests=tests+1 end
local E,C,F,W,B=modules.Economy,modules.Campaign,modules.Combat,modules.Waves,modules.Building
local wallet=E.New()
check(E.Buy(wallet,"blade") and wallet.Coins==130)
check(not E.Buy(wallet,"blade") and wallet.Coins==130,"Unique item must not charge twice")
check(not E.Buy(wallet,{}))
check(E.Buy(wallet,"armor") and wallet.Coins==30)
check(E.Buy(wallet,"potion") and wallet.Coins==5)
check(not E.Buy(wallet,"potion") and wallet.Coins==5)
check(E.UsePotion(wallet) and wallet.Items.potion==1)
check(E.UsePotion(wallet) and not E.UsePotion(wallet))
check(E.Reward(wallet,100,"one"))
check(not E.Reward(wallet,100,"one") and wallet.Coins==105)
check(not E.Reward(wallet,0/0,"nan"))
check(not E.Reward(wallet,math.huge,"infinite"))
check(not E.Reward(wallet,-10,"negative"))
local broken=E.New(); broken.Coins=-1; check(not pcall(E.Validate,broken))
local other=E.New(); check(other.Items.blade==0 and other.Coins==250,"Profiles must be isolated")
print('Economy: transactions, ownership caps, receipts, invalid amounts, profile isolation')

local quest=C.New(); wallet=E.New()
check(not C.Record(quest,"Kill") and quest.Progress==0)
check(not C.Claim(quest,wallet,E.Reward))
check(C.Record(quest,"Buy")); check(not C.Record(quest,"Buy"))
check(C.Claim(quest,wallet,E.Reward) and quest.Stage==2 and wallet.Coins==300)
check(not C.Claim(quest,wallet,E.Reward))
for stage=2,4 do
    local step=C.Steps[stage]
    for i=1,step.Goal do check(C.Record(quest,step.Event)) end
    check(C.Claim(quest,wallet,E.Reward))
end
check(C.View(quest).Done and wallet.Coins==800)
check(not C.Record(quest,"Wave") and not C.Claim(quest,wallet,E.Reward))
check(C.Validate(quest)==quest)
print('Campaign: ordering, progress caps, chained rewards, finished state')

local fighter=F.New()
check(F.Cast(fighter,"pulse",0) and fighter.Energy==65)
check(not F.Cast(fighter,"pulse",1) and fighter.Energy==65)
check(F.Cast(fighter,"guard",1) and fighter.Energy==40)
check(F.Incoming(fighter,100,2,false)==35)
check(F.Incoming(fighter,100,2,true)==28)
check(F.Incoming(fighter,100,4,true)==80)
check(F.Cast(fighter,"pulse",5) and fighter.Energy==5)
check(not F.Cast(fighter,"guard",10))
F.Tick(fighter,1); check(fighter.Energy==17)
F.Tick(fighter,math.huge); check(fighter.Energy==17)
for i=1,10 do F.Tick(fighter,1) end
check(fighter.Energy==100)
check(not F.Cast(fighter,{},20))
print('Combat: server cooldowns, energy, defense expiry, damage modifiers')

local wave=W.New()
check(W.Tick(wave,100)==nil)
check(W.Start(wave,0) and not W.Start(wave,1))
check(W.Tick(wave,2)==nil)
local spec=W.Tick(wave,3); check(spec.Count==4 and wave.Phase=="Combat")
for i=1,spec.Count-1 do check(not W.Kill(wave,4)) end
local complete,reward=W.Kill(wave,4); check(complete and reward==40 and wave.Phase=="Break")
check(not W.Kill(wave,5))
W.Fail(wave); check(wave.Phase=="Defeat" and wave.Alive==0)
check(W.Start(wave,5))
for round=1,10 do
    spec=W.Tick(wave,wave.NextAt)
    check(spec and spec.Count<=W.MaxActive)
    for i=1,spec.Count do W.Kill(wave,round*100) end
end
check(wave.Phase=="Victory" and wave.Wave==10)
print('Waves: transitions, duplicate death, bounded enemies, defeat and victory')

local build=B.New(); wallet=E.New()
check(B.Place(build,wallet,"wall",0,0,0) and wallet.Coins==230)
check(not B.Place(build,wallet,"pillar",0,0,0) and wallet.Coins==230)
check(not B.Place(build,wallet,"wall",5,0,0))
check(not B.Place(build,wallet,"wall",0/0,0,0))
check(not B.Place(build,wallet,"wall",1,0,4))
check(not B.Place(build,wallet,{},1,0,0))
check(B.Remove(build,wallet,0,0) and wallet.Coins==240 and build.Count==0)
check(not B.Remove(build,wallet,0,0) and wallet.Coins==240)
wallet.Coins=10000
for x=-4,4 do for z=-4,4 do if build.Count<30 then check(B.Place(build,wallet,"floor",x,z,0)) end end end
check(not B.Place(build,wallet,"floor",4,4,0) and build.Count==30)
check(B.Validate(build)==build)
build.Count=29; check(not pcall(B.Validate,build))
print('Building: grid, collision occupancy, rotation, cap, refunds, saved data validation')

-- Exercise the real persistence wrapper against an isolated fake DataStore.
local function clone(x) if type(x)~="table" then return x end local out={} for k,v in pairs(x) do out[k]=clone(v) end return out end
local database=nil; local down=false; local writes=0
local api={UpdateAsync=function(_,key,callback)
    check(type(key)=="string")
    if down then error('offline') end
    local value=callback(clone(database))
    if value then database=clone(value); writes=writes+1 end
    return clone(value)
end}
local services={DataStoreService={GetDataStore=function() return api end},RunService={IsStudio=function() return false end},HttpService={GenerateGUID=function() return 'test-session' end}}
game={GetService=function(_,name) return services[name] end}
task={wait=function() end}; warn=function() end
modules.Config={StudioPersistence=false,LeaseSeconds=180}
script={Parent=setmetatable({},{__index=function(_,key) return key end})}
require=function(name) return modules[name] end
local Store=loadStore()
local p={UserId=123,Kick=function(self) self.kicked=true end}
local profile=Store.Load(p); check(profile and profile.Economy.Coins==250)
check(E.Buy(profile.Economy,"potion")); C.Record(profile.Campaign,"Buy")
check(C.Claim(profile.Campaign,profile.Economy,E.Reward))
check(B.Place(profile.Build,profile.Economy,"wall",2,2,1))
check(Store.Save(p,profile,false) and database.Build.Count==1)
check(profile.Session==nil,"Persistence must not mutate live profile")
check(Store.Save(p,profile,true) and database.Session==nil)
local reloaded=Store.Load(p)
check(reloaded.Campaign.Stage==2 and reloaded.Economy.Coins==255 and reloaded.Build.Count==1)
database.Session.ID='other'; local before=writes
check(not Store.Save(p,reloaded,false) and writes==before and p.kicked)
check(Store.Load(p)==nil)
database.Session.Expires=0; check(Store.Load(p)~=nil)
down=true; check(Store.Load(p)==nil)
down=false; database.Version=99; check(Store.Load(p)==nil)
print('Persistence: load/save, integrated profile, session conflict, expired lease, network failure, schema refusal')
print(tests..' assertions passed.')
