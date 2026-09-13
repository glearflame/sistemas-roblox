const fs=require('fs'),path=require('path'),assert=require('assert'),parser=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.join(__dirname,'../principais');
const read=f=>fs.readFileSync(path.join(root,f),'utf8').replace(/\r\n/g,'\n');
const installer=read('InstalarKit.lua'); parser.parse(installer,{luaVersion:'5.3'});
const coreFiles={Economy:'economia-loja',Campaign:'campanha-missoes',Combat:'combate-habilidades',Waves:'ondas-sobrevivencia',Building:'construcao-grade'};
let code='local modules={}\n';
for(const [name,dir] of Object.entries(coreFiles)) {
    const source=read(dir+'/Core.lua'); parser.parse(source,{luaVersion:'5.3'}); assert(installer.includes(source));
    code+=`modules.${name}=(function()\n${source}\nend)()\n`;
}
for(const file of ['shared/Config.lua','shared/Store.lua','runtime/Server.server.lua','runtime/Client.client.lua']) {
    const source=read(file); parser.parse(source,{luaVersion:'5.3'}); assert(installer.includes(source),file);
}
code+='local function loadStore()\n'+read('shared/Store.lua')+'\nend\n';
code+=fs.readFileSync(path.join(__dirname,'advanced.lua'),'utf8');
const L=lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
if(lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK) throw Error(to_jsstring(lua.lua_tostring(L,-1)));
lua.lua_close(L);
console.log('Advanced installer and nine sources parsed; source matches installer.');
