local M = { StartHour=8, CycleSeconds=600 }
function M.Sample(elapsed)
    assert(type(elapsed)=="number" and elapsed==elapsed and elapsed>=0 and elapsed<math.huge,"Tempo inválido")
    assert(M.CycleSeconds>0,"CycleSeconds deve ser positivo")
    local hour=(M.StartHour+elapsed*24/M.CycleSeconds)%24
    local daylight=math.max(0,math.sin((hour-6)/12*math.pi))
    local minutes=math.floor(hour*60)
    return {Hour=hour,Day=hour>=6 and hour<18,Brightness=0.8+daylight*1.7,Rate=24/M.CycleSeconds,CycleMinutes=M.CycleSeconds/60,
            Label=string.format("%02d:%02d",math.floor(minutes/60),minutes%60)}
end
return M
