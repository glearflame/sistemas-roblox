const fs=require('fs'),path=require('path');
const base=path.join(__dirname,'../principais');
const sources=[
 ['economia-loja/Core.lua','Economy','ModuleScript'],
 ['campanha-missoes/Core.lua','Campaign','ModuleScript'],
 ['combate-habilidades/Core.lua','Combat','ModuleScript'],
 ['ondas-sobrevivencia/Core.lua','Waves','ModuleScript'],
 ['construcao-grade/Core.lua','Building','ModuleScript'],
 ['shared/Config.lua','Config','ModuleScript'],['shared/Store.lua','Store','ModuleScript'],
 ['runtime/Server.server.lua','Server','Script'],['runtime/Client.client.lua','Client','LocalScript']
];
let out=`-- GLEAR ADVANCED: cole todo este arquivo na Command Bar, com o Play parado.
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
`;
for(const [file,name,kind] of sources) {
 const text=fs.readFileSync(path.join(base,file),'utf8').replace(/\r\n/g,'\n');
 if(text.includes(']==]')) throw Error('Delimiter in source '+file);
 out+=`\nsource("${kind}",${kind==='LocalScript'?'client':'server'},"${name}",[==[\n${text}\n]==])\n`;
}
out+=`shared.Parent=RS
world.Parent=workspace
client.Parent=SPS
server.Parent=SSS
print("Glear Advanced instalado. Salve, dê Play e abra KIT AVANÇADO.")
`;
fs.writeFileSync(path.join(base,'InstalarKit.lua'),out);
console.log('Advanced installer generated: '+sources.length+' sources.');
