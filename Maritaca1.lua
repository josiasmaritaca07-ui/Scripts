-- ======================================================
-- MARITACA HUB | Futebol Clássico (V11 - DIVE NATIVO)
-- Usa o RemoteEvent real do jogo para mergulhar
-- ======================================================

local IMAGE_ASSET_ID = "rbxassetid://1000109123"

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Maritaca Hub | Futebol Clássico",
    SubTitle = "by Maritaca",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 440),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

task.spawn(function()
    task.wait(0.1)
    if Window.Frame then
        Window.Frame.BackgroundTransparency = 0
        Window.Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    end
end)

local Tabs = {
    Goleiro = Window:AddTab({ Title = "Goleiro / Dive", Icon = "shield" }),
    Reach   = Window:AddTab({ Title = "Reach & Hitbox", Icon = "target" }),
    FPS     = Window:AddTab({ Title = "FPS", Icon = "zap" }),
    Debug   = Window:AddTab({ Title = "Debug / Info", Icon = "terminal" })
}

-- ======================================================
-- SERVIÇOS
-- ======================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput      = game:GetService("VirtualInputManager")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    task.wait(0.3)
end)

-- ======================================================
-- ESTADO
-- ======================================================
local State = {
    AutoDiveEnabled   = false,
    ReachEnabled      = false,
    ReachSize         = 5,
    ShowReachCircle   = true,
    DebugMode         = false,
    DiveCooldown      = 0.35,
    AutoDiveRange     = 40,
    UseNativeDive     = true,   -- usa o remote nativo do jogo
    lastDiveTime      = 0,
}

-- ======================================================
-- DETECÇÃO DA BOLA
-- ======================================================
local BallCache    = nil
local LastBallScan = 0

local function LooksLikeBall(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    if n == "football" or n == "ball" or n == "bola" then return true end
    if n:find("ball") or n:find("bola") then return true end
    if obj.Shape == Enum.PartType.Ball and obj.Size.Magnitude < 10 then return true end
    return false
end

local function ScanForBall()
    -- Prioridade: nome exato "Football" (usado no The Classic Soccer)
    local direct = Workspace:FindFirstChild("Football")
    if direct and direct:IsA("BasePart") then return direct end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if LooksLikeBall(obj) then return obj end
    end
    for _, folder in ipairs(Workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            for _, obj in ipairs(folder:GetChildren()) do
                if LooksLikeBall(obj) then return obj end
            end
        end
    end
    return nil
end

local function GetBall()
    if BallCache and BallCache.Parent and LooksLikeBall(BallCache) then return BallCache end
    if tick() - LastBallScan < 0.4 then return BallCache end
    LastBallScan = tick()
    BallCache = ScanForBall()
    return BallCache
end

-- ======================================================
-- MERGULHO NATIVO (via RemoteEvent do jogo)
-- ======================================================
local NativeDiveRemote = nil

local function FindNativeDiveRemote()
    -- Caminho exato do The Classic Soccer: Packages.Knit.Services.BallService.RE.Dive
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if packages then
        local knit = packages:FindFirstChild("Knit")
        if knit then
            local services = knit:FindFirstChild("Services")
            if services then
                local ballService = services:FindFirstChild("BallService")
                if ballService then
                    local re = ballService:FindFirstChild("RE")
                    if re then
                        local dive = re:FindFirstChild("Dive")
                        if dive and dive:IsA("RemoteEvent") then
                            return dive
                        end
                    end
                end
            end
        end
    end

    -- Fallback: procura qualquer remote com "Dive" no nome
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find("dive") then
            return v
        end
    end
    return nil
end

-- Tenta encontrar o remote ao carregar e depois periodicamente
NativeDiveRemote = FindNativeDiveRemote()
task.spawn(function()
    while not NativeDiveRemote do
        task.wait(2)
        NativeDiveRemote = FindNativeDiveRemote()
        if NativeDiveRemote and State.DebugMode then
            print("[Maritaca] Remote Dive encontrado:", NativeDiveRemote:GetFullName())
        end
    end
end)

-- ======================================================
-- TECLAS DE MERGULHO DO JOGO
-- ======================================================
-- Baseado no script original: A+Q (esquerda), D+Q (direita), Space (alto)
local DIVE_KEYS = {
    LEFT_LOW  = {Enum.KeyCode.Q, Enum.KeyCode.A},
    RIGHT_LOW = {Enum.KeyCode.Q, Enum.KeyCode.D},
    LEFT_HIGH = {Enum.KeyCode.Space, Enum.KeyCode.Q, Enum.KeyCode.A},
    RIGHT_HIGH= {Enum.KeyCode.Space, Enum.KeyCode.Q, Enum.KeyCode.D},
    CENTER    = {Enum.KeyCode.Space},
}

local function PressKeys(keys, duration)
    for _, key in ipairs(keys) do
        VirtualInput:SendKeyEvent(true, key, false, game)
    end
    task.wait(duration or 0.15)
    for _, key in ipairs(keys) do
        VirtualInput:SendKeyEvent(false, key, false, game)
    end
end

-- ======================================================
-- EXECUTA O MERGULHO NATIVO
-- ======================================================
local isDiving = false

local function TriggerNativeDive(isRight, isHigh)
    if isDiving then return end
    isDiving = true

    -- 1) Dispara o RemoteEvent nativo (ativa o sistema do jogo)
    if State.UseNativeDive and NativeDiveRemote then
        pcall(function()
            NativeDiveRemote:FireServer()
        end)
    end

    -- 2) Pressiona as teclas correspondentes
    local keys
    if isHigh then
        keys = isRight and DIVE_KEYS.RIGHT_HIGH or DIVE_KEYS.LEFT_HIGH
    else
        keys = isRight and DIVE_KEYS.RIGHT_LOW or DIVE_KEYS.LEFT_LOW
    end

    task.spawn(function()
        PressKeys(keys, 0.15)
    end)

    task.delay(State.DiveCooldown, function()
        isDiving = false
    end)
end

-- ======================================================
-- BOTÃO FLUTUANTE
-- ======================================================
if CoreGui:FindFirstChild("MaritacaBtnGui") then
    CoreGui.MaritacaBtnGui:Destroy()
end

local BtnGui = Instance.new("ScreenGui")
BtnGui.Name = "MaritacaBtnGui"
BtnGui.Parent = CoreGui
BtnGui.ResetOnSpawn = false
BtnGui.IgnoreGuiInset = true

local FloatBall = Instance.new("ImageButton")
FloatBall.Name = "MaritacaBall"
FloatBall.Parent = BtnGui
FloatBall.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FloatBall.Position = UDim2.new(0.05, 0, 0.2, 0)
FloatBall.Size = UDim2.new(0, 58, 0, 58)
FloatBall.Image = IMAGE_ASSET_ID
FloatBall.Active = true
FloatBall.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FloatBall

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = FloatBall
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 2.5

FloatBall.MouseButton1Click:Connect(function()
    Window:Minimize()
end)

-- ======================================================
-- ESFERA VISUAL DO REACH
-- ======================================================
local SphereVisual = Instance.new("Part")
SphereVisual.Name = "MaritacaSphereVisual"
SphereVisual.Shape = Enum.PartType.Ball
SphereVisual.Material = Enum.Material.ForceField
SphereVisual.Color = Color3.fromRGB(0, 255, 120)
SphereVisual.Transparency = 0.5
SphereVisual.CanCollide = false
SphereVisual.CanQuery = false
SphereVisual.CanTouch = false
SphereVisual.Anchored = true
SphereVisual.Parent = nil

-- ======================================================
-- LOOP AUTO DIVE (COM PREVISÃO DE TRAJETÓRIA)
-- ======================================================
RunService.Heartbeat:Connect(function()
    if not State.AutoDiveEnabled then return end

    local ball = GetBall()
    local char = Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (ball and root and hum and hum.Health > 0) then return end

    local vel = ball.AssemblyLinearVelocity
    local speed = vel.Magnitude

    -- Previsão da posição da bola (como no script original)
    local predictScale = (speed > 10) and 0.25 or 0.05
    local targetPos = ball.Position + (vel * predictScale)

    local rel = root.CFrame:PointToObjectSpace(targetPos)
    local dist = (root.Position - ball.Position).Magnitude

    -- Verifica se a bola está na zona de defesa
    if math.abs(rel.Z) > 12 then return end  -- bola muito longe em profundidade

    local threshold = (speed > 25) and 2.5 or 1.5
    local isHigh = (targetPos.Y - root.Position.Y) > 3.5

    if dist <= State.AutoDiveRange and (tick() - State.lastDiveTime) > State.DiveCooldown then
        if rel.X < -threshold then
            State.lastDiveTime = tick()
            TriggerNativeDive(false, isHigh)  -- esquerda
            if State.DebugMode then print("[Maritaca] DIVE ESQUERDA alto=", isHigh) end
        elseif rel.X > threshold then
            State.lastDiveTime = tick()
            TriggerNativeDive(true, isHigh)   -- direita
            if State.DebugMode then print("[Maritaca] DIVE DIREITA alto=", isHigh) end
        elseif math.abs(rel.X) <= threshold and isHigh then
            State.lastDiveTime = tick()
            TriggerNativeDive(true, false)    -- centro (pulo)
            if State.DebugMode then print("[Maritaca] DIVE CENTRO") end
        end
    end
end)

-- ======================================================
-- LOOP REACH
-- ======================================================
RunService.Heartbeat:Connect(function()
    local ball = GetBall()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")

    if ball and root then
        local reachRadius = State.ReachSize * 2.5

        if State.ReachEnabled and State.ShowReachCircle then
            if SphereVisual.Parent ~= Workspace then SphereVisual.Parent = Workspace end
            local s = reachRadius * 2
            SphereVisual.Size = Vector3.new(s, s, s)
            SphereVisual.CFrame = ball.CFrame
        elseif SphereVisual.Parent then
            SphereVisual.Parent = nil
        end

        if State.ReachEnabled then
            local dist = (root.Position - ball.Position).Magnitude
            if dist <= reachRadius then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function()
                            firetouchinterest(part, ball, 0)
                            firetouchinterest(part, ball, 1)
                        end)
                    end
                end
            end
        end
    elseif SphereVisual.Parent then
        SphereVisual.Parent = nil
    end
end)

-- ======================================================
-- ANTI LAG
-- ======================================================
local AntiLagActive = false
local OriginalProps = {}
local AntiLagConn

local function ApplyAntiLag()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.TextureID and obj.TextureID ~= "" then
            OriginalProps[obj] = {key = "TextureID", value = obj.TextureID}
            pcall(function() obj.TextureID = "" end)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if obj.Texture and obj.Texture ~= "" then
                OriginalProps[obj] = {key = "Texture", value = obj.Texture}
                pcall(function() obj.Texture = "" end)
            end
        elseif obj:IsA("SurfaceAppearance") then
            OriginalProps[obj] = {ColorMap = obj.ColorMap, NormalMap = obj.NormalMap}
            pcall(function()
                obj.ColorMap = ""
                obj.NormalMap = ""
            end)
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
            or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            pcall(function() obj.Enabled = false end)
        end
    end

    pcall(function()
        Workspace.Terrain.Decoration = false
        Lighting.GlobalShadows = false
    end)
end

local function RestoreAntiLag()
    for obj, data in pairs(OriginalProps) do
        if obj and obj.Parent then
            pcall(function()
                if data.key then obj[data.key] = data.value
                else obj.ColorMap = data.ColorMap obj.NormalMap = data.NormalMap end
            end)
        end
    end
    OriginalProps = {}
    pcall(function()
        Workspace.Terrain.Decoration = true
        Lighting.GlobalShadows = true
    end)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            pcall(function() obj.Enabled = true end)
        end
    end
end

local function StartAntiLagWatcher()
    if AntiLagConn then AntiLagConn:Disconnect() end
    AntiLagConn = Workspace.DescendantAdded:Connect(function(obj)
        if not AntiLagActive then return end
        task.defer(function()
            if obj:IsA("Decal") or obj:IsA("Texture") then
                pcall(function() obj.Texture = "" end)
            elseif obj:IsA("BasePart") and obj.TextureID and obj.TextureID ~= "" then
                pcall(function() obj.TextureID = "" end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                pcall(function() obj.Enabled = false end)
            end
        end)
    end)
end

local function SetAntiLag(enabled)
    AntiLagActive = enabled
    if enabled then
        ApplyAntiLag()
        StartAntiLagWatcher()
    else
        RestoreAntiLag()
        if AntiLagConn then AntiLagConn:Disconnect() AntiLagConn = nil end
    end
end

-- ======================================================
-- UI - GOLEIRO
-- ======================================================
Tabs.Goleiro:AddSection("Auto Dive (Mergulho Nativo do Jogo)")

Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Ativar Auto Dive",
    Default = false,
    Callback = function(v) State.AutoDiveEnabled = v end
})

Tabs.Goleiro:AddToggle("NativeDiveToggle", {
    Title = "Usar RemoteEvent nativo (recomendado)",
    Description = "Se desativado, usa apenas as teclas.",
    Default = true,
    Callback = function(v) State.UseNativeDive = v end
})

Tabs.Goleiro:AddSlider("DiveRangeSlider", {
    Title = "Distância para mergulhar (studs)",
    Default = 40, Min = 10, Max = 100, Rounding = 0,
    Callback = function(v) State.AutoDiveRange = v end
})

Tabs.Goleiro:AddSlider("DiveCooldownSlider", {
    Title = "Cooldown entre mergulhos (s)",
    Default = 0.35, Min = 0.15, Max = 1.00, Rounding = 2,
    Callback = function(v) State.DiveCooldown = v end
})

-- ======================================================
-- UI - REACH
-- ======================================================
Tabs.Reach:AddSection("Ajustes de Reach e Hitbox")

Tabs.Reach:AddToggle("ReachToggle", {
    Title = "Ativar Reach",
    Default = false,
    Callback = function(v) State.ReachEnabled = v end
})

Tabs.Reach:AddSlider("ReachSlider", {
    Title = "Tamanho do Reach (Alcance)",
    Default = 5, Min = 1, Max = 15, Rounding = 0,
    Callback = function(v) State.ReachSize = v end
})

Tabs.Reach:AddToggle("ReachCircleToggle", {
    Title = "Mostrar Círculo Verde na Bola",
    Default = true,
    Callback = function(v) State.ShowReachCircle = v end
})

-- ======================================================
-- UI - FPS
-- ======================================================
Tabs.FPS:AddSection("Desempenho")

Tabs.FPS:AddToggle("AntiLagToggle", {
    Title = "Anti Lag (Remove Texturas)",
    Description = "Remove texturas e efeitos para deixar o jogo mais leve.",
    Default = false,
    Callback = function(v)
        SetAntiLag(v)
        Fluent:Notify({
            Title = "Maritaca FPS",
            Content = v and "Anti Lag ATIVADO!" or "Texturas restauradas.",
            Duration = 4
        })
    end
})

-- ======================================================
-- UI - DEBUG
-- ======================================================
Tabs.Debug:AddSection("Debug / Diagnóstico")

Tabs.Debug:AddToggle("DebugToggle", {
    Title = "Modo Debug",
    Default = false,
    Callback = function(v) State.DebugMode = v end
})

Tabs.Debug:AddButton({
    Title = "Testar Remote Dive",
    Description = "Dispara o RemoteEvent de dive nativo.",
    Callback = function()
        if NativeDiveRemote then
            NativeDiveRemote:FireServer()
            Fluent:Notify({Title = "Maritaca", Content = "Remote Dive disparado!", Duration = 3})
        else
            Fluent:Notify({Title = "Maritaca", Content = "Remote Dive NÃO encontrado.", Duration = 3})
        end
    end
})

Tabs.Debug:AddButton({
    Title = "Forçar Dive Esquerda (teste)",
    Callback = function() TriggerNativeDive(false, false) end
})

Tabs.Debug:AddButton({
    Title = "Forçar Dive Direita (teste)",
    Callback = function() TriggerNativeDive(true, false) end
})

-- ======================================================
-- INICIALIZAÇÃO
-- ======================================================
Fluent:Notify({
    Title = "Maritaca Hub V11",
    Content = "Mergulho NATIVO carregado! Remote: " .. (NativeDiveRemote and "OK" or "buscando..."),
    Duration = 6
})

Window:SelectTab(1)
