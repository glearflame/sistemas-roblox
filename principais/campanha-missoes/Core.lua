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
