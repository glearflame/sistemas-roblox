const fs=require('fs');
const path=require('path');
const root=path.join(__dirname,'..');
const cases=require('../tests/cases.json');
for(const slug of Object.keys(cases)) {
  const base=path.join(root,slug);
  let installer=fs.readFileSync(path.join(base,'Instalar.lua'),'utf8').replace(/\r\n/g,'\n');
  for(const [kind,parent,name,file] of [
    ['ModuleScript','server','Core','Core.lua'],
    ['Script','server','Server','Server.server.lua'],
    ['LocalScript','client','Client','Client.client.lua']]) {
    const start=`source("${kind}",${parent},"${name}",[==[\n`;
    const left=installer.indexOf(start), right=installer.indexOf(']==])',left);
    if(left<0||right<0) throw Error('Installer marker missing: '+slug);
    const content=fs.readFileSync(path.join(base,'src',file),'utf8').replace(/\r\n/g,'\n');
    if(content.includes(']==]')) throw Error('Source contains installer delimiter');
    installer=installer.slice(0,left+start.length)+content+installer.slice(right);
  }
  fs.writeFileSync(path.join(base,'Instalar.lua'),installer);
  console.log('Updated '+slug);
}
