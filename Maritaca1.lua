-- ═══════════════════════════════════════════════════════════════════
-- 🦜 MARITACA HUB v17 - COMPLETO (REACH + GK + AUTO DIVE)
-- ═══════════════════════════════════════════════════════════════════

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterPack = game:GetService("StarterPack")
local Players = game:GetService("Players")

local config = {
    reachEnabled = false,
    autoDiveEnabled = false,
    reachSize = 20,
    showCircle = true,
    detectedBall = nil,
    scannerMode = false,
    autoDiveDelay = 0.25,
    diveRadar = 60
}

-- LIMPEZA
local pGui = player:WaitForChild("PlayerGui")
for _, v in pairs(pGui:GetChildren()) do
    if v.Name:find("Maritaca") or v.Name == "DebugBola" then v:Destroy() end
end

-- ═══════════════════════════════════════════════════════════════════
-- 🎨 UI PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name = "MaritacaHub"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = pGui

-- BOTÃO 🦜
local ballBtn = Instance.new("TextButton")
ballBtn.Size = UDim2.new(0, 55, 0, 55)
ballBtn.Position = UDim2.new(0, 15, 0.5, -27)
ballBtn.BackgroundColor3 = Color3.fromRGB(30, 180, 80)
ballBtn.Text = "🦜"
ballBtn.TextSize = 28
ballBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ballBtn.BorderSizePixel = 0
ballBtn.AutoButtonColor = false
ballBtn.Active = true
ballBtn.ZIndex = 100
ballBtn.Parent = sg

local bC = Instance.new("UICorner")
bC.CornerRadius = UDim.new(1, 0)
bC.Parent = ballBtn

local bS = Instance.new("UIStroke")
bS.Color = Color3.fromRGB(255, 220, 50)
bS.Thickness = 3
bS.Parent = ballBtn

-- JANELA
local win = Instance.new("Frame")
win.Size = UDim2.new(0, 500, 0, 340)
win.Position = UDim2.new(0.5, -250, 0.5, -170)
win.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
win.BorderSizePixel = 0
win.Visible = false
win.ZIndex = 100
win.Parent = sg

local winC = Instance.new("UICorner")
winC.CornerRadius = UDim.new(0, 12)
winC.Parent = win

local winS = Instance.new("UIStroke")
winS.Color = Color3.fromRGB(45, 45, 55)
winS.Thickness = 1
winS.Parent = win

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
header.BorderSizePixel = 0
header.ZIndex = 101
header.Parent = win

local hC = Instance.new("UICorner")
hC.CornerRadius = UDim.new(0, 12)
hC.Parent = header

local hFix = Instance.new("Frame")
hFix.Size = UDim2.new(1, 0, 0.5, 0)
hFix.Position = UDim2.new(0, 0, 0.5, 0)
hFix.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
hFix.BorderSizePixel = 0
hFix.ZIndex = 101
hFix.Parent = header

local headerIcon = Instance.new("TextLabel")
headerIcon.Size = UDim2.new(0, 32, 0, 32)
headerIcon.Position = UDim2.new(0, 10, 0, 6)
headerIcon.BackgroundColor3 = Color3.fromRGB(30, 180, 80)
headerIcon.Text = "🦜"
headerIcon.TextSize = 18
headerIcon.BorderSizePixel = 0
headerIcon.ZIndex = 102
headerIcon.Parent = header

local hiC = Instance.new("UICorner")
hiC.CornerRadius = UDim.new(0, 8)
hiC.Parent = headerIcon

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(0, 200, 0, 22)
headerTitle.Position = UDim2.new(0, 50, 0, 4)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "MARITACA HUB"
headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
headerTitle.TextSize = 15
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.ZIndex = 102
headerTitle.Parent = header

local headerSub = Instance.new("TextLabel")
headerSub.Size = UDim2.new(0, 200, 0, 15)
headerSub.Position = UDim2.new(0, 50, 0, 24)
headerSub.BackgroundTransparency = 1
headerSub.Text = "v17 • The Classic Soccer"
headerSub.TextColor3 = Color3.fromRGB(150, 150, 160)
headerSub.TextSize = 10
headerSub.Font = Enum.Font.Gotham
headerSub.TextXAlignment = Enum.TextXAlignment.Left
headerSub.ZIndex = 102
headerSub.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 9)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 102
closeBtn.Parent = header

local cC = Instance.new("UICorner")
cC.CornerRadius = UDim.new(0, 6)
cC.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)

-- SIDEBAR
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 135, 1, -45)
sidebar.Position = UDim2.new(0, 0, 0, 45)
sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 101
sidebar.Parent = win

local sbC = Instance.new("UICorner")
sbC.CornerRadius = UDim.new(0, 12)
sbC.Parent = sidebar

local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -12, 1, -12)
tabsFrame.Position = UDim2.new(0, 6, 0, 6)
tabsFrame.BackgroundTransparency = 1
tabsFrame.ZIndex = 102
tabsFrame.Parent = sidebar

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.Padding = UDim.new(0, 4)
tabsLayout.Parent = tabsFrame

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -145, 1, -53)
contentArea.Position = UDim2.new(0, 140, 0, 50)
contentArea.BackgroundTransparency = 1
contentArea.ZIndex = 101
contentArea.Parent = win

local pages = {}
local tabButtons = {}

local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 103
    btn.Parent = tabsFrame

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = btn

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ZIndex = 102
    page.Parent = contentArea

    local pl = Instance.new("UIListLayout")
    pl.Padding = UDim.new(0, 6)
    pl.Parent = page

    pages[name] = page
    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do
            p.Visible = (n == name)
            tabButtons[n].BackgroundColor3 = (n == name) and Color3.fromRGB(30, 180, 80) or Color3.fromRGB(28, 28, 36)
            tabButtons[n].TextColor3 = (n == name) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)
        end
    end)
    return page
end

local homePage = createTab("Início", "🏠")
local reachPage = createTab("Reach", "⚽")
local gkPage = createTab("Goleiro", "🥅")
local divePage = createTab("Auto Dive", "🏊")
local configPage = createTab("Config", "⚙️")

pages["Início"].Visible = true
tabButtons["Início"].BackgroundColor3 = Color3.fromRGB(30, 180, 80)
tabButtons["Início"].TextColor3 = Color3.fromRGB(255, 255, 255)

local function makeBtn(parent, text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color or Color3.fromRGB(38, 38, 48)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 103
    btn.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    return btn
end

local function makeLabel(parent, text, color, height)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, height or 26)
    lbl.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(200, 200, 210)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.BorderSizePixel = 0
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.ZIndex = 103
    lbl.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = lbl
    return lbl
end

-- ═══════════════════════════════════════════════════════════════════
-- 🥅 FUNÇÃO GK (CORRIGIDA) - AGORA COM ARGUMENTO
-- ═══════════════════════════════════════════════════════════════════
function fireGK(key)
    local char = player.Character
    local fired = false
    
    -- ⚡ Tenta FireServer SEM e COM argumento
    local function tryRemote(remote)
        if not remote then return false end
        local ok = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer()  -- sem args (padrão)
                return true
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer()
                return true
            elseif remote:IsA("BindableEvent") then
                remote:Fire()
                return true
            end
        end)
        return ok
    end
    
    -- 1️⃣ GK dentro do Character (equipado)
    if char then
        local gk = char:FindFirstChild("GK")
        if gk then
            local remote = gk:FindFirstChild(key)
            if tryRemote(remote) then
                print("[GK] " .. key .. " ✓ Character.GK")
                return true
            end
        end
    end
    
    -- 2️⃣ GK no Backpack
    local bp = player:FindFirstChild("Backpack")
    if bp then
        local gk = bp:FindFirstChild("GK")
        if gk then
            local remote = gk:FindFirstChild(key)
            if tryRemote(remote) then
                print("[GK] " .. key .. " ✓ Backpack.GK")
                return true
            end
        end
    end
    
    -- 3️⃣ GK no StarterPack
    local gk = StarterPack:FindFirstChild("GK")
    if gk then
        local remote = gk:FindFirstChild(key)
        if tryRemote(remote) then
            print("[GK] " .. key .. " ✓ StarterPack.GK")
            return true
        end
    end
    
    -- 4️⃣ Remote direto no Character (sem pasta GK)
    if char then
        local remote = char:FindFirstChild(key)
        if tryRemote(remote) then
            print("[GK] " .. key .. " ✓ Character." .. key)
            return true
        end
    end
    
    print("[GK] ✗ FALHOU: " .. key)
    return false
end

-- ═══ HOME ═══
local welcome = makeLabel(homePage, "  Bem-vindo ao Maritaca Hub!", Color3.fromRGB(255, 220, 50), 24)
local ballStatus = makeLabel(homePage, "  🔍 Procurando bola...", Color3.fromRGB(100, 255, 100), 32)
local diveStatus = makeLabel(homePage, "  🥅 Aguardando dive...", Color3.fromRGB(150, 150, 160), 32)

-- ═══ REACH ═══
local reachBtn = makeBtn(reachPage, "  Reach: DESLIGADO", Color3.fromRGB(200, 50, 50))
local sizeBtn = makeBtn(reachPage, "  Tamanho: " .. config.reachSize .. " studs")
local circleBtn = makeBtn(reachPage, "  Círculo: LIGADO", Color3.fromRGB(50, 150, 80))
local reachInfo = makeLabel(reachPage, "  Se a bola entrar no círculo, ela\n  é puxada automaticamente pro\n  seu pé.", Color3.fromRGB(150, 150, 160), 50)

sizeBtn.MouseButton1Click:Connect(function()
    config.reachSize = config.reachSize + 5
    if config.reachSize > 50 then config.reachSize = 5 end
    sizeBtn.Text = "  Tamanho: " .. config.reachSize .. " studs"
    if circle then circle.Size = Vector3.new(config.reachSize, config.reachSize, config.reachSize) end
end)

-- ═══ GK ═══
local gkInfo = makeLabel(gkPage, "  Clique para testar cada comando:", Color3.fromRGB(255, 220, 50), 22)

local gkGrid = Instance.new("Frame")
gkGrid.Size = UDim2.new(1, 0, 0, 145)
gkGrid.BackgroundTransparency = 1
gkGrid.ZIndex = 103
gkGrid.Parent = gkPage

local gkLayout = Instance.new("UIGridLayout")
gkLayout.CellSize = UDim2.new(0.5, -3, 0, 32)
gkLayout.CellPadding = UDim.new(0, 6, 0, 6)
gkLayout.Parent = gkGrid

local function makeGKBtn(label, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(45, 90, 160)
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 103
    btn.Parent = gkGrid

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        fireGK(key)
    end)
    return btn
end

makeGKBtn("↘ Direita Baixo", "C")
makeGKBtn("↙ Esquerda Baixo", "Z")
makeGKBtn("↗ Direita Alto", "E")
makeGKBtn("↖ Esquerda Alto", "Q")
makeGKBtn("🥅 Avança", "H")
makeGKBtn("🙌 Agarra Alto", "R")

-- ═══ DIVE ═══
local diveBtn = makeBtn(divePage, "  Auto Dive: DESLIGADO", Color3.fromRGB(200, 50, 50))
local diveDelayBtn = makeBtn(divePage, "  Delay: " .. config.autoDiveDelay .. "s")
local diveRadarBtn = makeBtn(divePage, "  Radar: " .. config.diveRadar .. "m")
local testBtn = makeBtn(divePage, "  🧪 Testar GK (Avança)", Color3.fromRGB(150, 80, 200))
local diveInfo = makeLabel(divePage, "  Detecta a bola, calcula a direção\n  e dispara o comando certo.", Color3.fromRGB(150, 150, 160), 40)

testBtn.MouseButton1Click:Connect(function() fireGK("H") end)

diveDelayBtn.MouseButton1Click:Connect(function()
    config.autoDiveDelay = config.autoDiveDelay + 0.05
    if config.autoDiveDelay > 0.6 then config.autoDiveDelay = 0.1 end
    diveDelayBtn.Text = "  Delay: " .. string.format("%.2f", config.autoDiveDelay) .. "s"
end)

diveRadarBtn.MouseButton1Click:Connect(function()
    config.diveRadar = config.diveRadar + 20
    if config.diveRadar > 150 then config.diveRadar = 40 end
    diveRadarBtn.Text = "  Radar: " .. config.diveRadar .. "m"
end)

-- ═══ CONFIG ═══
local scanBtn = makeBtn(configPage, "  Modo Scanner: DESLIGADO", Color3.fromRGB(80, 100, 200))
local infoConfig = makeLabel(configPage, "  Scanner mostra objetos próximos\n  para identificar a bola.", Color3.fromRGB(150, 150, 160), 40)

scanBtn.MouseButton1Click:Connect(function()
    config.scannerMode = not config.scannerMode
    if config.scannerMode then
        scanBtn.Text = "  Modo Scanner: LIGADO"
        scanBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
    else
        scanBtn.Text = "  Modo Scanner: DESLIGADO"
        scanBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 200)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- 🔍 DETECTOR DE BOLA (MULTI-MÉTODO)
-- ═══════════════════════════════════════════════════════════════════
local function findBall()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, 0, "", 0 end

    local candidates = {}
    
    -- 1. TPS.PB
    local tps = Workspace:FindFirstChild("TPS")
    if tps then
        for _, v in pairs(tps:GetDescendants()) do
            if v:IsA("BasePart") then
                table.insert(candidates, {part = v, source = "TPS." .. v.Name})
            end
        end
    end

    -- 2. lball, rball, ball, bola
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = string.lower(v.Name)
            if n == "lball" or n == "rball" or n:find("ball") or n:find("bola") or n:find("soccer") then
                local isMine = char and v:IsDescendantOf(char)
                if not isMine then
                    local jaTem = false
                    for _, c in ipairs(candidates) do
                        if c.part == v then jaTem = true break end
                    end
                    if not jaTem then
                        table.insert(candidates, {part = v, source = v.Name})
                    end
                end
            end
        end
    end

    -- 3. Se não achou nada, procura partes esféricas
    if #candidates == 0 then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local isMine = char and v:IsDescendantOf(char)
                if not isMine then
                    local sz = v.Size
                    local avg = (sz.X + sz.Y + sz.Z) / 3
                    local var = math.abs(sz.X - sz.Y) + math.abs(sz.Y - sz.Z)
                    if var < 1 and avg > 0.5 and avg < 5 then
                        table.insert(candidates, {part = v, source = "esfera: " .. v.Name})
                    end
                end
            end
        end
    end

    local closest, closestDist, closestSource = nil, math.huge, ""
    for _, c in ipairs(candidates) do
        if c.part and c.part.Parent then
            local d = (c.part.Position - hrp.Position).Magnitude
            if d < closestDist then
                closestDist = d
                closest = c.part
                closestSource = c.source
            end
        end
    end
    return closest, closestDist, closestSource, #candidates
end

-- Scanner
local function scanNearby()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "sem player" end
    local myPos = hrp.Position
    local list = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local isMine = v:IsDescendantOf(char)
            local isOther = false
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character and v:IsDescendantOf(plr.Character) then
                    isOther = true break
                end
            end
            if not isMine and not isOther then
                table.insert(list, {name = v.Name, dist = (v.Position - myPos).Magnitude})
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    local txt = "  TOP 5:\n"
    for i = 1, math.min(5, #list) do
        txt = txt .. "  " .. i .. ". " .. list[i].name .. " (" .. math.floor(list[i].dist) .. "m)\n"
    end
    return txt
end

task.spawn(function()
    while task.wait(0.3) do
        if config.scannerMode then
            ballStatus.Text = scanNearby()
            ballStatus.TextColor3 = Color3.fromRGB(255, 220, 50)
        else
            local ball, dist, source, total = findBall()
            config.detectedBall = ball
            if ball then
                ballStatus.Text = "  🔍 Bola: " .. ball.Name .. " | " .. math.floor(dist) .. "m"
                ballStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
            else
                ballStatus.Text = "  🔍 Bola: não encontrada (" .. total .. ")"
                ballStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end
    end
end)

-- ═══ CÍRCULO ═══
local circle = nil
local function createCircle()
    if circle then circle:Destroy() end
    circle = Instance.new("Part")
    circle.Name = "MaritacaCircle"
    circle.Shape = Enum.PartType.Ball
    circle.Size = Vector3.new(config.reachSize, config.reachSize, config.reachSize)
    circle.Anchored = true
    circle.CanCollide = false
    circle.Material = Enum.Material.ForceField
    circle.Color = Color3.fromRGB(0, 255, 100)
    circle.Transparency = 0.7
    circle.CastShadow = false
    circle.Parent = Workspace
end

-- ═══════════════════════════════════════════════════════════════════
-- ⚽ REACH (CORRIGIDO - usa BodyVelocity + CFrame)
-- ═══════════════════════════════════════════════════════════════════
local reachConn = nil
local function toggleReach()
    config.reachEnabled = not config.reachEnabled
    if config.reachEnabled then
        reachBtn.Text = "  Reach: LIGADO"
        reachBtn.BackgroundColor3 = Color3.fromRGB(30, 180, 80)
        createCircle()

        reachConn = RunService.Heartbeat:Connect(fun
