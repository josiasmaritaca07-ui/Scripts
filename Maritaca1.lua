-- ======================================================
-- MARITACA HUB | Native Black Edition (V28)
-- 100% NATIVO - Sem Fluent, sem link externo
-- By Maritaca
-- ======================================================

print("[Maritaca] Iniciando V28...")

-- SERVIÇOS
local CoreGui      = game:GetService("CoreGui")
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")
local UserInput    = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    task.wait(0.5)
    if State.SpeedEnabled then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = GetSpeedValue(State.SpeedLevel) end
    end
end)

print("[Maritaca] Serviços OK")

-- ======================================================
-- ESTADO
-- ======================================================
local State = {
    -- Reach
    ReachEnabled = false,
    ReachRange = 5,
    ReachColor = Color3.fromRGB(0, 170, 255),
    -- Auto Dive
    AutoDiveEnabled = false,
    AutoDiveRange = 30,
    AutoDiveCooldown = 0.35,
    AutoDiveMinSpeed = 6,
    UseResetWelds = true,
    UseGKButtons = true,
    ForceVelocity = true,
    DivePowerH = 60,
    DivePowerV = 30,
    -- Ball
    ShowBallMarker = true,
    TPEnabled = false,
    TPRange = 15,
    TPCooldown = 0.5,
    MagnetEnabled = false,
    MagnetRange = 20,
    MagnetForce = 100,
    -- Speed
    SpeedEnabled = false,
    SpeedLevel = 1,
}

-- ======================================================
-- RESETWELDS
-- ======================================================
local ResetWelds = ReplicatedStorage:FindFirstChild("ResetWelds")
if not ResetWelds then
    ResetWelds = ReplicatedStorage:FindFirstChild("ResetWelds", true)
end

local function FireResetWelds()
    if not ResetWelds or not ResetWelds:IsA("RemoteEvent") then return false end
    if not ResetWelds.OnClientEvent then return false end
    pcall(function()
        firesignal(ResetWelds.OnClientEvent, LocalPlayer)
    end)
    return true
end

-- ======================================================
-- SPEED
-- ======================================================
local SPEED_TABLE = {
    [1]=16,[2]=24,[3]=32,[4]=42,[5]=55,
    [6]=70,[7]=88,[8]=105,[9]=125,[10]=150,
}
local function GetSpeedValue(l) return SPEED_TABLE[l] or 16 end

-- ======================================================
-- DETECTOR DE BOLA
-- ======================================================
local BallCache = nil
local LastBallScan = 0

local function IsBall(obj)
    if not obj or not obj:IsA("BasePart") then return 0 end
    local n = obj.Name:lower()
    if n == "football" or n == "ball" or n == "bola" or n == "soccerball" then return 4 end
    if n:find("ball") or n:find("bola") then return 3 end
    if obj:IsA("Part") and obj.Shape == Enum.PartType.Ball and obj.Size.Magnitude < 8 then return 2 end
    return 0
end

local function GetBall()
    if BallCache and BallCache.Parent and IsBall(BallCache) > 0 then return BallCache end
    if tick() - LastBallScan < 0.3 then return BallCache end
    LastBallScan = tick()
    local best, bestScore = nil, 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local s = IsBall(obj)
        if s > bestScore then
            best = obj
            bestScore = s
            if s == 4 then break end
        end
    end
    BallCache = best
    return BallCache
end

-- ======================================================
-- GK BUTTONS
-- ======================================================
local function FireGKButton(key)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    local start = pg:FindFirstChild("Start", true)
    if not start then return false end
    local label = start:FindFirstChild("ImageLabel", true)
    if not label then return false end
    local btn = label:FindFirstChild("GK " .. key)
    if not btn then return false end

    if typeof(firesignal) == "function" then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.MouseButton1Down) end)
        pcall(function() firesignal(btn.Activated) end)
    end
    pcall(function()
        if btn.AbsolutePosition and btn.AbsoluteSize then
            local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
            VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.01)
            VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end)
    return true
end

local function ExecuteDive(isRight, isHigh)
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if State.ForceVelocity then
        local dirX = isRight and 1 or -1
        local dirY = isHigh and 1 or 0.3
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(dirX * State.DivePowerH, State.DivePowerV * dirY, 0)
        end)
    end

    if State.UseGKButtons then
        local key
        if isRight and isHigh then key = "E"
        elseif isRight and not isHigh then key = "C"
        elseif not isRight and isHigh then key = "Q"
        else key = "Z" end
        FireGKButton(key)
    end

    if State.UseResetWelds then FireResetWelds() end
end

-- ======================================================
-- CRIAR A GUI
-- ======================================================
if CoreGui:FindFirstChild("MaritacaNativeGui") then
    CoreGui.MaritacaNativeGui:Destroy()
end

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "MaritacaNativeGui"
MainGui.ResetOnSpawn = false
MainGui.IgnoreGuiInset = true
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ok, err = pcall(function() MainGui.Parent = CoreGui end)
if not ok then
    MainGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

print("[Maritaca] GUI criada")

-- ======================================================
-- JANELA PRINCIPAL
-- ======================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = MainGui
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -220)
MainFrame.Size = UDim2.new(0, 320, 0, 440)
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(35, 35, 35)
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

-- TOPBAR
local TopBar = Instance.new("Frame")
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.Position = UDim2.new(0, 0, 0, 0)

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 10)
TopBarCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "Maritaca Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left

local Subtitle = Instance.new("TextLabel")
Subtitle.Parent = TopBar
Subtitle.Size = UDim2.new(1, -80, 0, 14)
Subtitle.Position = UDim2.new(0, 12, 1, -16)
Subtitle.Text = "Black Edition"
Subtitle.TextColor3 = Color3.fromRGB(0, 170, 255)
Subtitle.TextSize = 10
Subtitle.Font = Enum.Font.Gotham
Subtitle.BackgroundTransparency = 1
Subtitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 22
CloseBtn.BorderSizePixel = 0

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = Color3.fromRGB(60, 60, 60)
CloseStroke.Thickness = 1
CloseStroke.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- DIVISÓRIA
local Divider = Instance.new("Frame")
Divider.Parent = MainFrame
Divider.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Divider.BorderSizePixel = 0
Divider.Size = UDim2.new(1, 0, 0, 1)
Divider.Position = UDim2.new(0, 0, 0, 42)

-- ======================================================
-- ABAS (BOTÕES NO TOPO)
-- ======================================================
local TabBar = Instance.new("Frame")
TabBar.Parent = MainFrame
TabBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TabBar.BorderSizePixel = 0
TabBar.Size = UDim2.new(1, 0, 0, 32)
TabBar.Position = UDim2.new(0, 0, 0, 43)

local TabBarList = Instance.new("UIListLayout")
TabBarList.FillDirection = Enum.FillDirection.Horizontal
TabBarList.SortOrder = Enum.SortOrder.LayoutOrder
TabBarList.Padding = UDim.new(0, 2)
TabBarList.Parent = TabBar

local TabBarPad = Instance.new("UIPadding")
TabBarPad.PaddingLeft = UDim.new(0, 6)
TabBarPad.PaddingTop = UDim.new(0, 4)
TabBarPad.Parent = TabBar

-- CONTAINER DOS CONTEÚDOS
local ContentFrame = Instance.new("Frame")
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ContentFrame.BorderSizePixel = 0
ContentFrame.Position = UDim2.new(0, 0, 0, 76)
ContentFrame.Size = UDim2.new(1, 0, 1, -76)

local Pages = {}
local TabButtons = {}

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Parent = ContentFrame
    page.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    page.Visible = false

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = page

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = page

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
    end)

    Pages[name] = page
    return page
end

local function CreateTabButton(name)
    local btn = Instance.new("TextButton")
    btn.Parent = TabBar
    btn.Size = UDim2.new(0, 65, 0, 24)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(40, 40, 40)
    s.Thickness = 1
    s.Parent = btn

    TabButtons[name] = { btn = btn, stroke = s }

    btn.MouseButton1Click:Connect(function()
        for n, page in pairs(Pages) do
            page.Visible = (n == name)
        end
        for n, data in pairs(TabButtons) do
            if n == name then
                data.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                data.stroke.Color = Color3.fromRGB(0, 170, 255)
            else
                data.btn.TextColor3 = Color3.fromRGB(150, 150, 150)
                data.stroke.Color = Color3.fromRGB(40, 40, 40)
            end
        end
    end)

    return btn
end

-- ======================================================
-- ELEMENTOS DE UI
-- ======================================================
local function CreateSection(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = parent
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(0, 170, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function CreateToggle(parent, text, default, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(35, 35, 35)
    s.Thickness = 1
    s.Parent = btn

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12)
    pad.Parent = btn

    local ind = Instance.new("Frame")
    ind.Parent = btn
    ind.Size = UDim2.new(0, 12, 0, 12)
    ind.Position = UDim2.new(1, -24, 0.5, -6)
    ind.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    ind.BorderSizePixel = 0

    local indC = Instance.new("UICorner")
    indC.CornerRadius = UDim.new(1, 0)
    indC.Parent = ind

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        ind.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
        callback(state)
    end)
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(35, 35, 35)
    s.Thickness = 1
    s.Parent = btn

    btn.MouseButton1Click:Connect(function()
        callback()
    end)
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = frame

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(35, 35, 35)
    s.Thickness = 1
    s.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Parent = frame
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local barBg = Instance.new("Frame")
    barBg.Parent = frame
    barBg.Size = UDim2.new(1, -24, 0, 6)
    barBg.Position = UDim2.new(0, 12, 0, 32)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    barBg.BorderSizePixel = 0

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = barBg

    local barFill = Instance.new("Frame")
    barFill.Parent = barBg
    barFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    barFill.BorderSizePixel = 0

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = barFill

    local clicker = Instance.new("TextButton")
    clicker.Parent = frame
    clicker.Size = UDim2.new(1, -24, 0, 30)
    clicker.Position = UDim2.new(0, 12, 0, 18)
    clicker.BackgroundTransparency = 1
    clicker.Text = ""

    local dragging = false

    local function update(x)
        local rel = math.clamp((x - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * rel)
        barFill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. ": " .. v
        callback(v)
    end

    clicker.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end)
    clicker.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    clicker.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                         or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
end

print("[Maritaca] Funções de UI OK")

-- ======================================================
-- CRIA AS PÁGINAS
-- ======================================================
CreatePage("Reach")
CreatePage("Auto Dive")
CreatePage("Speed")
CreatePage("Bola")
CreatePage("Config")

CreateTabButton("Reach")
CreateTabButton("Auto Dive")
CreateTabButton("Speed")
CreateTabButton("Bola")
CreateTabButton("Config")

-- ======================================================
-- POPULA REACH
-- ======================================================
CreateSection(Pages.Reach, "Reach Configuration")
CreateToggle(Pages.Reach, "Enable Reach", false, function(v) State.ReachEnabled = v end)
CreateSlider(Pages.Reach, "Reach Range", 1, 15, 5, function(v) State.ReachRange = v end)

-- ======================================================
-- POPULA AUTO DIVE
-- ======================================================
CreateSection(Pages["Auto Dive"], "Auto Dive")
CreateToggle(Pages["Auto Dive"], "Enable Auto Dive", false, function(v) State.AutoDiveEnabled = v end)
CreateSlider(Pages["Auto Dive"], "Distancia", 10, 80, 30, function(v) State.AutoDiveRange = v end)
CreateSlider(Pages["Auto Dive"], "Cooldown (x0.1)", 2, 20, 4, function(v) State.AutoDiveCooldown = v/10 end)
CreateToggle(Pages["Auto Dive"], "Usar ResetWelds", true, function(v) State.UseResetWelds = v end)
CreateToggle(Pages["Auto Dive"], "Usar botoes GK", true, function(v) State.UseGKButtons = v end)
CreateToggle(Pages["Auto Dive"], "Impulso fisico", true, function(v) State.ForceVelocity = v end)
CreateToggle(Pages["Auto Dive"], "Marcador na bola", true, function(v) State.ShowBallMarker = v end)

CreateSection(Pages["Auto Dive"], "Teste GK")
CreateButton(Pages["Auto Dive"], "Testar ResetWelds", function() FireResetWelds() end)
CreateButton(Pages["Auto Dive"], "GK Z (Esq Baixo)", function() ExecuteDive(false, false) end)
CreateButton(Pages["Auto Dive"], "GK C (Dir Baixo)", function() ExecuteDive(true, false) end)
CreateButton(Pages["Auto Dive"], "GK Q (Esq Alto)",  function() ExecuteDive(false, true) end)
CreateButton(Pages["Auto Dive"], "GK E (Dir Alto)",  function() ExecuteDive(true, true) end)

-- ======================================================
-- POPULA SPEED
-- ======================================================
CreateSection(Pages.Speed, "Sistema de Velocidade")
CreateToggle(Pages.Speed, "Enable Speed", false, function(v)
    State.SpeedEnabl
