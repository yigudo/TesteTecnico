-- after finish this i look to mirror and think "why i didn't use awk?"


local file = io.open("produtos.txt")
local fileSell = io.open("vendas.txt")


local product = {} -- will save the product file
local sales = {} -- save the vendas file
local stackControl = 1 -- care of the product stack index

for i = 1, 200 do -- initialize array with 200 spaces
  product[i] =  { prodcode = 0, -- product id
                  stockInit = 0, -- the stock on the first period
                  minQt = 0 } -- minimun quantity to maintain on stock
end


for i = 1, 1000 do -- initialise with 1000 spaces
  sales[i] = {  prodcode = 0, -- product id 
  soldQT = 0, -- sold quantity
  selSit = 0, -- selling situacion
  selCh = 0 } -- selling channel
end

local sm = 0
local stringHolder = "" -- hold the actual char of the archive iteration

function save()
  sm = 0
  stackControl = 1
end





local function loadProducts()
  for line in file:lines() do --iterate over the lines
    for chara in line:gmatch"." do -- iterate over the chars
      stringHolder = stringHolder .. chara

      if chara == ";" then
        sm = sm + 1
        stringHolder = ""
      end
      
      if sm == 0 then -- check the position of the value(if is the first, the second or the third)
        product[stackControl].prodcode = tonumber(stringHolder)
      else if sm == 1 then
        product[stackControl].stockInit = tonumber(stringHolder)
        else 
          product[stackControl].minQt = tonumber(stringHolder)
        end 
      end
    
    end
    sm = 0
    stackControl = stackControl + 1
    stringHolder = ""
    print(product[stackControl - 1].prodcode, product[stackControl - 1].stockInit, product[stackControl - 1].minQt)
  end
end








local function loadSales()
  for line in fileSell:lines() do --iterate over the lines
    for chara in line:gmatch"." do -- iterate over the chars
      stringHolder = stringHolder .. chara

      if chara == ";" then
        sm = sm + 1
        stringHolder = ""
      end

      if sm == 0 then -- check the position of the value(if is the first, the second...)
        sales[stackControl].prodcode = tonumber(stringHolder)
        else if sm == 1 then
          sales[stackControl].soldQT = tonumber(stringHolder)
          else if sm == 2 then
            sales[stackControl].selSit = tonumber(stringHolder)
          else
            sales[stackControl].selCh = tonumber(stringHolder)
          end
        end
      end
    end
    sm = 0
    stackControl = stackControl + 1
    stringHolder = ""
  end
end




local function erase_zero(a, b)
  for a_, code1 in ipairs(a) do
    if code1.prodcode == 0 then
      product[a_] = nil -- erase unused spaces
    end 
  end

  for a_, code2 in ipairs(b) do
    if code2.prodcode == 0 then -- to erase all dead spaces
      sales[a_] = nil
    end
  end

end





local found = {}
local notFound = {}
local foundError = {}
local notFinished = {}

local function divergence()  
    
  --for i in pairs(product) do
  for a_, cod in ipairs(sales) do -- iterate over sales    
    for b_, cod2 in ipairs(product) do
      
      if cod.prodcode == cod2.prodcode then -- now, we look for error codes.
        if cod.selSit == 999 then
          table.insert(foundError, {a_, "erro desconhecido"}) 
          goto endd
          
        elseif cod.selSit == 135 then
          table.insert(foundError, {a_, 135})
          goto endd
        
        elseif cod.selSit == 190 then
          table.insert(notFinished, {a_, "venda não finalizada"}) 

        else
          table.insert(found, cod)
          goto endd
        end
      end
    end
    table.insert(notFound, {a_, cod.prodcode})
    ::endd::

  end
end






local function selByCh() -- sellings by channels
  local channels = {
    ["representantes"] = 0,
    ["website"] = 0,
    ["mobileApp"] = 0,
    ["iosApp"] = 0
  }
  for _, hold in ipairs(found) do
    -- lua don't have a ternary operator, or a switch case statement

    if hold.selCh == 1 then
      channels["representantes"] = channels["representantes"] + hold.soldQT -- again, lua not have += function, we need to write like c noobs
    
      else if hold.selCh == 2 then
        channels["website"] = channels["website"] + hold.soldQT
    
        else if hold.selCh == 3 then
          channels["mobileApp"] = channels["mobileApp"] + hold.soldQT

          else if hold.selCh == 4 then -- i put this last as else to avoid errors
            channels["iosApp"] = channels["iosApp"] + hold.soldQT
          end
        end
      end
    end
  end


  return channels
end




local function apurate(...) -- 
  local generalInfo = {}
  for a_, cod in pairs(product) do
    generalInfo[a_] = {
      prodCode = cod.prodcode, 
      stockInit = cod.stockInit,
      minQt = cod.minQt,
      sales = 0}
  end


  for i, codes in ipairs(generalInfo) do
    for a_, cod in ipairs(found) do
      if codes.prodCode == cod.prodcode then
        generalInfo[i].sales = codes.sales + cod.soldQT
      end
    end
  end

  return generalInfo
end




local function writeToArchive(channels, trans)
  local transfer = io.open("transfere.txt", "w")
  local totcanais = io.open("totcanais.txt", "w")
  local div = io.open("divergencias.txt", "w")


  transfer:write("Produto\tQtCO\tQtMin\tQtVendas  Estq.após vendas\tNecess.\t  Transf. de Vendas Arm p/ CO\n")
  
  
  -- write to archive transfere.txt
  for i, cod in ipairs(trans) do
  -- i prefer use vars instead put the value directly, look clean to me
    local ProductCode = cod.prodCode-- product code 
    local InitialStock = cod.stockInit -- quantity in the CO
    local MinimunQt = cod.minQt -- the name speak by themselv
    local Sales = cod.sales -- QtVendas
    local StockAfterSales = cod.stockInit - cod.sales -- qnt apos vendas
    local transAfterSale = 0;
    local needed = 0


    transfer:write(ProductCode,"\t",InitialStock,"\t",MinimunQt,"\t",Sales,"\t  ",StockAfterSales,"\t\t\t")
    
    local x = cod.stockInit - cod.sales

    if  x < cod.minQt then
      needed = cod.minQt - (cod.stockInit - cod.sales)
      transAfterSale = needed
      if needed > 1 and needed < 10 then
        transAfterSale = 10
      end
      transfer:write(needed,"\t\t",transAfterSale, "\n")
    
    else
      transfer:write(needed,"\t\t",transAfterSale, "\n")

    end     
  end


  --Write all data on archive "totcanais.txt"
  totcanais:write("Quantidades de Vendas por canal\n",
                  "1 - Representantes   ", channels.representantes,
                  "\n2 - Website    ", channels.website,
                  "\n3 - App móvel Android    ", channels.mobileApp,
                  "\n4 - App móvel iPhone   ",channels.iosApp, "\n" )



  for i, cod in ipairs(notFinished) do
    div:write("Linha ",cod[1]," - ", cod[2], "\n")
  end

  for i, cod in ipairs(notFound) do
    div:write("Linha ",cod[1], " - código de produto não encontrado ", cod[2], "\n")
  end

  for i, cod in ipairs(foundError) do
    if cod[2] == 135 then
      div:write("Linha ",cod[1], " - venda cancelada", "\n")
    
    else
      div:write("Linha ",cod[1], " - Erro desconhecido, acionar equipe de TI", "\n")
    
    end
  end


end







-- first, process the files
loadProducts() -- load product files
save() -- i don`t know why i wrote this, lol
loadSales() -- load sales file
erase_zero(product, sales) -- erase tables without values, to increase performace in the next operations



-- now take the desrired data
divergence() -- look to errors in sales archive
local channels = selByCh() -- catch all sales by groups
local trans = apurate() -- save data that will be used in transfere archive 

writeToArchive(channels, trans)


file:close()
