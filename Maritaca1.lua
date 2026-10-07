-- =======================================================
-- SCRIPT THE CLASSIC SOCCER - PAINEL FLUENT + REACH ESFERA
-- TP + REACH + FOLLOW + Esfera de Alcance
-- =======================================================

print("=== SCRIPT INICIANDO ===")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Estados
local seguindo = false
local reachAtivo = false
local circuloVisivel = true
local tamanhoReach = 8 -- Padrão (1 a 15)
local circulo = nil
local conexaoCirculo = nil

-- =======================================================
-- PEGAR A BOLA OFICIAL (SÓ RealMatch)
-- =======================================================
local function obterPosicaoBola()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local rm = obj:FindFirstChild("RealMatch")
        if rm and (rm.Value == true or rm.Value == 1) then
            if obj:IsA("BasePart") then
                return obj.Position
            elseif obj:IsA("Model") then
                if obj.PrimaryPart then
                    return obj.PrimaryPart.Position
                end
                local ok, pivot = pcall(function() return obj:GetPivot().Position end)
                if ok then return pivot end
            end
        end
    end
    return nil
end

-- =======================================================
-- ANIMAÇÃO
-- =======================================================
local function tocarAnimacaoAndar()
    local client = ReplicatedStorage:FindFirstChild("Client")
    if client then
        client:FireServer("NoobGlitch")
    end
end

-- =======================================================
-- ESFERA DE ALCANCE (VISUAL - ENVOLVE O CORPO)
-- =======================================================
local function criarCirculo()
    if circulo and circulo.Parent then
        circulo:Destroy()
    end
    
    -- Esfera ao redor do personagem
    circulo = Instance.new("Part")
    circulo.Name = "ReachSphere"
    circulo.Shape = Enum.PartType.Ball
    circulo.Size = Vector3.new(tamanhoReach * 2, tamanhoReach * 2, tamanhoReach * 2)
    circulo.Anchored = true
    circulo.CanCollide = false
    circulo.CanQuery = false
    circulo.CanTouch = false
    circulo.Material = Enum.Material.Neon
    circulo.Color = Color3.fromRGB(0, 255, 100) -- VERDE (igual ao print)
    circulo.Transparency = 0.85 -- Bem transparente pra não atrapalhar a visão
    circulo.Parent = workspace
    
    -- Inicia o loop que atualiza a posição da esfera
    if conexaoCirculo then
        conexaoCirculo:Disconnect()
    end
    
    conexaoCirculo = RunService.RenderStepped:Connect(function()
        if not circulo or not circulo.Parent then return end
        if not humanoidRootPart then return end
        
        -- Centraliza a esfera no HumanoidRootPart (meio do corpo)
        local posPlayer = humanoidRootPart.Position
        circulo.CFrame = CFrame.new(posPlayer)
        
        -- Visibilidade
        circulo.Transparency = circuloVisivel and 0.85 or 1
    end)
end

local function atualizarCirculo()
    if circulo then
        circulo.Size = Vector3.new(tamanhoReach * 2, tamanhoReach * 2, tamanhoReach * 2)
    end
end

local function removerCirculo()
    if conexaoCirculo then
        conexaoCirculo:Disconnect()
        conexaoCirculo = nil
    end
    if circulo then
        circulo:Destroy()
        circulo = nil
    end
end

-- =======================================================
-- FUNÇÕES DE AÇÃO
-- =======================================================
local function acaoTeleporte()
    local posBola = obterPosicaoBola()
    if posBola then
        humanoidRootPart.CFrame = CFrame.new(posBola + Vector3.new(0, 3, 0))
        print("⚡ Teleportado para a bola oficial!")
    else
        warn("❌ Bola oficial não encontrada (RealMatch != true)")
    end
end

local conexaoFollow = nil

local function ativarFollow(estado)
    seguindo = estado
    
    if seguindo then
        conexaoFollow = RunService.RenderStepped:Connect(function()
            if not seguindo then return end
            
            local posBola = obterPosicaoBola()
            if not posBola or not humanoidRootPart or not humanoid then return end
            
            local posPlayer = humanoidRootPart.Position
            local direcao = Vector3.new(
                posBola.X - posPlayer.X,
                0,
                posBola.Z - posPlayer.Z
            )
            
            local distancia = direcao.Magnitude
            if distancia < 1.5 then return end
            
            local dirNormalizada = direcao.Unit
            humanoid:Move(dirNormalizada, false)
            tocarAnimacaoAndar()
        end)
        print("=== FOLLOW ATIVADO ===")
    else
        if conexaoFollow then
            conexaoFollow:Disconnect()
            conexaoFollow = nil
        end
        if humanoid then
            humanoid:Move(Vector3.new(0, 0, 0), false)
        end
        print("=== FOLLOW DESATIVADO ===")
    end
end

local function ativarReach(estado)
    reachAtivo = estado
    if reachAtivo then
        -- Hitbox do reach (só chão)
        humanoidRootPart.Size = Vector3.new(tamanhoReach, 2, tamanhoReach)
        humanoidRootPart.Transparency = 0.5
        criarCirculo()
        print("🎯 Reach ativado! (" .. tamanhoReach .. ")")
    else
        humanoidRootPart.Size = Vector3.new(2, 2, 1)
        humanoidRootPart.Transparency = 1
        removerCirculo()
        print("🎯 Reach desativado")
    end
end

local function alterarTamanhoReach(novoTamanho)
    tamanhoReach = novoTamanho
    if reachAtivo then
        humanoidRootPart.Size = Vector3.new(tamanhoReach, 2, tamanhoReach)
        atualizarCirculo()
    end
    print("📏 Tamanho do reach: " .. tamanhoReach)
end

-- =======================================================
-- ScreenGui Principal
-- =======================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FluentStyleGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- =======================================================
-- BOTÃO FLUTUANTE (SATURNO)
-- =======================================================
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "MinimizeButton"
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
toggleBtn.Text = "🪐"
toggleBtn.TextSize = 26
toggleBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(1, 0)
btnCorner.Parent = toggleBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(0, 170, 255)
btnStroke.Thickness = 2
btnStroke.Parent = toggleBtn

-- =======================================================
-- JANELA PRINCIPAL
-- =======================================================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 480, 0, 360)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -180)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 55)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Arrastar
local function tornarArrastavel(frame)
    local dragging, dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

tornarArrastavel(toggleBtn)
tornarArrastavel(mainFrame)

-- =======================================================
-- BARRA LATERAL
-- =======================================================
local sideBar = Instance.new("Frame")
sideBar.Name = "SideBar"
sideBar.Size = UDim2.new(0, 130, 1, 0)
sideBar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
sideBar.BorderSizePixel = 0
sideBar.Parent = mainFrame

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 10)
sideCorner.Parent = sideBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "⚽ TPS SOCCER"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = sideBar

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -10, 1, -50)
tabContainer.Position = UDim2.new(0, 5, 0, 45)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = sideBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -140, 1, -20)
contentFrame.Position = UDim2.new(0, 135, 0, 10)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Sistema de Abas
local paginas = {}

local function criarAba(nome, id)
    local btnTab = Instance.new("TextButton")
    btnTab.Size = UDim2.new(1, 0, 0, 32)
    btnTab.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    btnTab.Text = "  " .. nome
    btnTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    btnTab.Font = Enum.Font.GothamMedium
    btnTab.TextSize = 12
    btnTab.TextXAlignment = Enum.TextXAlignment.Left
    btnTab.Parent = tabContainer

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = btnTab

    local page = Instance.new("ScrollingFrame")
    page.Name = id .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 2
    page.Parent = contentFrame

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.Parent = page

    paginas[id] = {btn = btnTab, frame = page}

    btnTab.MouseButton1Click:Connect(function()
        for _, v in pairs(paginas) do
            v.frame.Visible = false
            v.btn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
            v.btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        page.Visible = true
        btnTab.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
        btnTab.TextColor3 = Color3.new(1, 1, 1)
    end)

    return page
end

local abaGeral = criarAba("Geral", "Geral")
local abaReach = criarAba("Reach", "Reach")
local abaInfo = criarAba("Info", "Info")

paginas["Geral"].frame.Visible = true
paginas["Geral"].btn.BackgroundColor3 = Color3.fromRGB(45, 45, 58)

-- =======================================================
-- COMPONENTES
-- =======================================================
local function criarBotaoAcao(pagina, texto, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -5, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = texto
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Parent = pagina

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
end

local function criarToggle(pagina, texto, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -5, 0, 38)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    toggleFrame.Parent = pagina

    local tfCorner = Instance.new("UICorner")
    tfCorner.CornerRadius = UDim.new(0, 6)
    tfCorner.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = texto
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 36, 0, 18)
    switch.Position = UDim2.new(1, -45, 0.5, -9)
    switch.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    switch.Text = ""
    switch.Parent = toggleFrame

    local swCorner = Instance.new("UICorner")
    swCorner.CornerRadius = UDim.new(1, 0)
    swCorner.Parent = switch

    local ativado = false
    switch.MouseButton1Click:Connect(function()
        ativado = not ativado
        if ativado then
            switch.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        else
            switch.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        end
        if callback then callback(ativado) end
    end)
end

-- =======================================================
-- ABA GERAL
-- =======================================================
criarBotaoAcao(abaGeral, "⚡ TELEPORTE PARA A BOLA", function()
    acaoTeleporte()
end)

criarToggle(abaGeral, "🤖 FOLLOW BALL", function(estado)
    ativarFollow(estado)
end)

-- =======================================================
-- ABA REACH
-- =======================================================
criarToggle(abaReach, "🎯 REACH ATIVO", function(estado)
    ativarReach(estado)
end)

criarToggle(abaReach, "👁️ MOSTRAR ESFERA", function(estado)
    circuloVisivel = estado
    print("👁️ Esfera " .. (estado and "visível" or "oculta"))
end)

-- Slider título
local sliderTitle = Instance.new("TextLabel")
sliderTitle.Size = UDim2.new(1, -5, 0, 20)
sliderTitle.BackgroundTransparency = 1
sliderTitle.Text = "📏 TAMANHO DO REACH: " .. tamanhoReach
sliderTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
sliderTitle.Font = Enum.Font.GothamBold
sliderTitle.TextSize = 11
sliderTitle.TextXAlignment = Enum.TextXAlignment.Left
sliderTitle.Parent = abaReach

-- Frame do slider
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(1, -5, 0, 30)
sliderFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
sliderFrame.Parent = abaReach

local sfCorner = Instance.new("UICorner")
sfCorner.CornerRadius = UDim.new(0, 6)
sfCorner.Parent = sliderFrame

-- Barra fundo
local barraFundo = Instance.new("Frame")
barraFundo.Size = UDim2.new(1, -40, 0, 6)
barraFundo.Position = UDim2.new(0, 20, 0.5, -3)
barraFundo.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
barraFundo.BorderSizePixel = 0
barraFundo.Parent = sliderFrame

local bfCorner = Instance.new("UICorner")
bfCorner.CornerRadius = UDim.new(1, 0)
bfCorner.Parent = barraFundo

-- Barra preenchida
local barraFill = Instance.new("Frame")
barraFill.Size = UDim2.new(0.5, 0, 1, 0)
barraFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barraFill.BorderSizePixel = 0
barraFill.Parent = barraFundo

local bfillCorner = Instance.new("UICorner")
bfillCorner.CornerRadius = UDim.new(1, 0)
bfillCorner.Parent = barraFill

-- Botão do slider
local sliderBtn = Instance.new("TextButton")
sliderBtn.Size = UDim2.new(0, 20, 0, 20)
sliderBtn.Position = UDim2.new(0.5, -10, 0.5, -10)
sliderBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
sliderBtn.Text = ""
sliderBtn.Parent = barraFundo

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(1, 0)
sbCorner.Parent = sliderBtn

-- Lógica do slider (1 a 15)
local sliderDragging = false
local valorMin = 1
local valorMax = 15

local function atualizarSlider(porcentagem)
    porcentagem = math.clamp(porcentagem, 0, 1)
    barraFill.Size = UDim2.new(porcentagem, 0, 1, 0)
    sliderBtn.Position = UDim2.new(porcentagem, -10, 0.5, -10)
    
    local valor = math.floor(valorMin + (valorMax - valorMin) * porcentagem)
    sliderTitle.Text = "📏 TAMANHO DO REACH: " .. valor
    alterarTamanhoReach(valor)
end

sliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mouseX = input.Position.X
        local barraAbsoluta = barraFundo.AbsolutePosition.X
        local barraLargura = barraFundo.AbsoluteSize.X
        local porcentagem = (mouseX - barraAbsoluta) / barraLargura
        atualizarSlider(porcentagem)
    end
end)

-- =======================================================
-- ABA INFO (COM PING/LAG)
-- =======================================================
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -5, 0, 100)
infoLabel.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
infoLabel.Text = "⚽ TPS SOCCER HUB\n\nVersão: 1.0\nBola detectada via RealMatch\n\nUse as abas ao lado!"
infoLabel.TextColor3 = Color3.new(1, 1, 1)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.TextWrapped = true
infoLabel.Parent = abaInfo

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 6)
infoCorner.Parent = infoLabel

-- Mostrador de Ping (Lag)
local pingLabel = Instance.new("TextLabel")
pingLabel.Size = UDim2.new(1, -5, 0, 30)
pingLabel.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
pingLabel.Text = "📡 Ping: -- ms"
pingLabel.TextColor3 = Color3.new(1, 1, 1)
pingLabel.Font = Enum.Font.GothamBold
pingLabel.TextSize = 12
pingLabel.Parent = abaInfo

local pingCorner = Instance.new("UICorner")
pingCorner.CornerRadius = UDim.new(0, 6)
pingCorner.Parent = pingLabel

-- Loop que atualiza o ping (usando os Stats que você mandou)
task.spawn(function()
    while true do
        task.wait(1)
        
        -- Ping do servidor (ms)
        local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        local sentPackets = Stats.Network.ServerStatsItem["Sent Cluster Packets"].Size
        local touchPackets = Stats.Network.ServerStatsItem.SentTouchPackets.Size
        
        pingLabel.Text = string.format("📡 Ping: %.0f ms | 📦 Pacotes: %d", ping, sentPackets)
    end
end)

-- =======================================================
-- RESET AO MORRER
-- =======================================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChil
