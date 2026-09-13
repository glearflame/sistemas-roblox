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
