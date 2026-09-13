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
