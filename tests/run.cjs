const fs = require('fs');
const path = require('path');
const assert = require('assert');
const parser = require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring} = require('fengari');
const root = path.join(__dirname,'..');
const cases = require('./cases.json');
let count=0;
for(const [slug,test] of Object.entries(cases)) {
  const dir=path.join(root,slug);
  const installer=fs.readFileSync(path.join(dir,'Instalar.lua'),'utf8').replace(/\r\n/g,'\n');
  for(const file of ['Instalar.lua','src/Core.lua','src/Server.server.lua','src/Client.client.lua']) {
    const source=fs.readFileSync(path.join(dir,file),'utf8').replace(/\r\n/g,'\n');
    parser.parse(source,{luaVersion:'5.3'});
    assert(!source.includes('__NS__'), 'Unexpanded template');
    if(file.startsWith('src/')) assert(installer.includes(source),'Installer is out of date: '+slug+'/'+file);
    count++;
  }
  const L=lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
  const core=fs.readFileSync(path.join(dir,'src/Core.lua'),'utf8');
  const status=lauxlib.luaL_dostring(L,to_luastring('local M=(function()\n'+core+'\nend)()\n'+test));
  if(status!==lua.LUA_OK) throw Error(slug+': '+to_jsstring(lua.lua_tostring(L,-1)));
  lua.lua_close(L);
  console.log('PASS '+slug);
}
console.log(count+' Lua files parsed; five rule suites passed; installers match source.');
