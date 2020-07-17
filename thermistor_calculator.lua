--Rio, 17/07/2020 - 6h46

--https://en.wikipedia.org/wiki/Steinhart%E2%80%93Hart_equation#Inverse_of_the_equation
--descobrindo A, B e C, pela equacao de steinhart-Hart podemos fazer a tabela
--do termistor utilizado na impressora


local file = io.open("thermistor_xx.txt", "w")


    --queremos entao achar o valor do adc para temperaturas especificas
-- a funcao inversa de steinhard entao:
--local A = 0.0008636800722776907
--print(A)
--local B = 0.00023408344711963055
--print(B)
--local C = -1.0855056219950787e-7
--print(C)


local function celsiusToKelvin(Ctemp)
    local Ktemp = Ctemp + 273.15
    --print(Ktemp, "C->K")
    return Ktemp
end

local function kelvinToCelsius(Ktemp)
    local Ctemp = Ktemp - 273.15
    --print(Ctemp, "K->C")
    return Ctemp
end

local function calculaABC(Ctemp1, r1, Ctemp2, r2, Ctemp3, r3)

    local Ktemp1 = celsiusToKelvin(Ctemp1)
    local Ktemp2 = celsiusToKelvin(Ctemp2)
    local Ktemp3 = celsiusToKelvin(Ctemp3)

    local L1, L2, L3    = math.log(r1), math.log(r2), math.log(r3)
    local Y1, Y2, Y3    = (1/Ktemp1), (1/Ktemp2), (1/Ktemp3)
    local g2, g3        = (Y2-Y1)/(L2-L1), (Y3-Y1)/(L3-L1)

    C = ((g3-g2)/(L3-L2))/(L1+L2+L3)

    B = g2 - C*(L1^2 + L1*L2 + L2^2)

    A = Y1 - (B+(L1^2)*C)*L1

    print(A, B, C)
end

calculaABC(50, 21456.522, 80, 6091.031, 190, 292.531)




local tCalc = function(r)
    local Ktemp = 1/(A + B*math.log(r) + C*math.log(r)^3)
    local Ctemp = kelvinToCelsius(Ktemp)

    return Ctemp
end

local function calcRdeTemp(tempAlvo, rinit, passo, erro)

    
    local tempAtual = tCalc(rinit)
    --print(rinit, tempAtual)

    if math.abs(tempAtual - tempAlvo) <= erro then
        return rinit
    end

  

    if tempAtual > tempAlvo and passo > 0 then
        --print("Inversao 1")
        passo = -(passo/10)

    elseif tempAtual < tempAlvo and passo < 0 then
        --print("Inversao 2")
        passo = -(passo/10)
    end
    
     rinit = rinit - passo
    
     if rinit <= 0 then
        passo = -(passo/10)
    end

   -- io.read()

    return calcRdeTemp(tempAlvo, rinit, passo, erro)
end

--calcRdeTemp(30, 20000, 10000, 0.0001)
--calcRdeTemp(170, 100000, 10000, 0.0001)

local function RparaADC(Rtherm, Vs, Rpullup, ADCbits)
    local Vadc = (Vs * Rtherm)/(Rpullup + Rtherm)
    

    local adcRead = (Vadc*(2^12))/Vs

    local adcReadNorm = adcRead/2^(ADCbits-10)

    --print(adcReadNorm)
    return adcReadNorm
end

--RparaADC(425.5, 3.3, 4700, 12)

local function constroiLinha(Ctemp)
    --talvez fazer um cache da resistencia atual. Isso 
    --aceleraria a recursao

    local R = calcRdeTemp(Ctemp, 100000, 10000, 0.0001)

    local adc = RparaADC(R, 3.3, 4700, 12)

    adc = math.floor(adc+0.5)
    print(adc, Ctemp)
    local linha = "{ OV( ".. adc .."), ".. Ctemp .." },\n"
    
    file:write(linha)
end

--define intervalos e passos
local tint = {} --tabela de intervalos e passos

local function setInterval(intervalo)

    table.insert(tint, intervalo)
end

local function constroiTabela()

    print("Iniciou contrucao da tabela")    
    for i = #tint, 1, -1 do
        intervalo = tint[i]
    
        limite   = intervalo[1]
        print(limite)
        atual  = intervalo[2]
        print(atual)
        passo   = intervalo[3]
        print(passo)

        while atual >= limite do
            print(atual, limite)
            constroiLinha(atual)
            atual = atual - passo
        end
    end
end

setInterval({10, 60, 10})
setInterval({65, 130, 5})
setInterval({140, 180, 10})
setInterval({185, 300, 5})

print(#tint, "intervalos definidos")





constroiTabela()
file:close()

