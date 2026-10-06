-- ======================================================
-- MARITACA HUB | Futebol Clássico (V10 - TRIPLE DIVE)
-- By Maritaca | Auto Dive + Anti Lag
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
local UserInput         = game:GetService("UserInputService")

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
    DiveCooldown      = 0.25,
    AutoDiveRange     = 40,
    ForceVelocity     = true,
    SmartDive         = true,
    lastDiveTime      = 0,
    lastDiveDir       = nil,
}

-- ======================================================
-- DETECÇÃO DE BOLA
-- ======================================================
local BallCache    = nil
local LastBallScan = 0

local function LooksLikeBall(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    if n == "ball" or n == "bola" or n == "football" or n == "soccerball" then return true end
    if n:find("ball") or n:find("bola") then return true end
    if obj.Shape == Enum.PartType.Ball and obj.Size.Magnitude < 10 then return true end
    return false
end

local function ScanForBall()
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
-- MERGULHO EM 3 CAMADAS (TRIPLE DIVE)
-- ======================================================
-- Camada 1: Humanoid ChangeState (pular)
-- Camada 2: Clique sintético na direção da bola (alguns jogos aceitam)
-- Camada 3: Impulso físico + CFrame (fallback garantido)
-- ======================================================

local function Layer1_Jump(high)
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
    return true
end

local function Layer2_TouchInput(ballPos, isRight)
    -- Simula toque na direção onde a bola está
    local ok = false
    pcall(function()
        local vp = Camera.ViewportSize
        -- Posição do lado correspondente (esquerda/direita no terço inferior da tela)
        local screenX = isRight and (vp.X * 0.85) or (vp.X * 0.15)
        local screenY = vp.Y * 0.75

        VirtualInput:SendMouseButtonEvent(screenX, screenY, 0, true,  game, 1)
        task.wait(0.03)
        VirtualInput:SendMouseButtonEvent(screenX, screenY, 0, false, game, 1)

        -- Também tenta touch
        VirtualInput:SendTouchEvent(Enum.UserInputType.Touch, 0, screenX, screenY)
        ok = true
    end)
    return ok
end

local function Layer3_Physics(ballPos, isRight, high)
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local flat = Vector3.new(ballPos.X - root.Position.X, 0, ballPos.Z - root.Position.Z)
    local dir
    if flat.Magnitude < 0.5 then
        dir = isRight and Vector3.new(1, 0, 0) or Vector3.new(-1, 0, 0)
    else
        dir = flat.Unit
    end

    -- Impulso horizontal forte + vertical pra "voar" na direção da bola
    local horizForce = 55
    local vertForce  = high and 38 or 22

    -- Aplica velocity
    root.AssemblyLinearVelocity = dir * horizForce + Vector3.new(0, vertForce, 0)

    -- Rotaciona o goleiro pra deitar (visual de mergulho)
    if State.SmartDive then
        pcall(function()
            local lookDir = isRight and 1 or -1
            local newCF = root.CFrame * CFrame.Angles(0, 0, math.rad(-60 * lookDir))
            root.CFrame = newCF
        end)
    end
    return true
end

local function ExecuteDive(ballPos, isRight, high)
    -- 1: tenta pular (Humanoid)
    Layer1_Jump(high)
    -- 2: simula input (toque/clique)
    task.spawn(function() Layer2_TouchInput(ballPos, isRight) end)
    -- 3: força física (sempre)
    Layer3_Physics(ballPos, isRight, high)
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
-- LOOP AUTO DIVE
-- ======================================================
RunService.Heartbeat:Connect(function()
    if not State.AutoDiveEnabled then return end

    local ball = GetBall()
    local char = Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (ball and root and hum and hum.Health > 0) then return end

    local ballPos = ball.Position
    local rootPos = root.Position
    local dist    = (rootPos - ballPos).Magnitude
    local vel     = ball.AssemblyLinearVelocity.Magnitude

    -- Detecção mais permissiva: perto OU se movendo rápido pra perto
    local fastApproach = vel > 20 and dist < State.AutoDiveRange * 1.5

    if (dist <= State.AutoDiveRange or fastApproach) and (tick() - State.lastDiveTime) > State.DiveCooldown then
        State.lastDiveTime = tick()

        local localPos = root.CFrame:PointToObjectSpace(ballPos)
        local isRight  = localPos.X > 0
        local isHigh   = ballPos.Y > (rootPos.Y + 1.0)

        ExecuteDive(ballPos, isRight, isHigh)

        if State.DebugMode then
            print(("[Maritaca] DIVE -> dist=%.1f vel=%.1f lado=%s alto=%s")
                :format(dist, vel, isRight and "R" or "L", tostring(isHigh)))
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
                for _, pp in ipairs(ball:GetDescendants()) do
                    if pp:IsA("ProximityPrompt") and pp.Enabled then
                        pcall(function() fireproximityprompt(pp) end)
                    end
                end
            end
        end
    elseif SphereVisual.Parent then
        SphereVisual.Parent = nil
    end
end)

-- ======================================================
-- ANTI LAG (REMOVE TEXTURAS)
-- ======================================================
local AntiLagActive   = false
local OriginalProps   = {}   -- guarda texturas removidas para restaurar

local function ApplyAntiLag()
    -- 1) Remove texturas de todas as partes
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj.TextureID and obj.TextureID ~= "" then
                OriginalProps[obj] = {key = "TextureID", value = obj.TextureID}
                pcall(function() obj.TextureID = "" end)
            end
            if obj:IsA("MeshPart") and obj.TextureID and obj.TextureID ~= "" then
                OriginalProps[obj] = {key = "TextureID", value = obj.TextureID}
                pcall(function() obj.TextureID = "" end)
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if obj.Texture and obj.Texture ~= "" then
                OriginalProps[obj] = {key = "Texture", value = obj.Texture}
                pcall(function() obj.Texture = "" end)
            end
        elseif obj:IsA("SurfaceAppearance") then
            OriginalProps[obj] = {
                ColorMap = obj.ColorMap,
                NormalMap = obj.NormalMap,
                RoughnessMap = obj.RoughnessMap,
                MetalnessMap = obj.MetalnessMap,
            }
            pcall(function()
                obj.ColorMap     = ""
                obj.NormalMap    = ""
                obj.RoughnessMap = ""
                obj.MetalnessMap = ""
            end)
        end
    end

    -- 2) Remove materiais detalhados de terreno (grama, etc)
    pcall(function()
        Workspace.Terrain.Decoration = false
    end)

    -- 3) Baixa qualidade de iluminação
    pcall(function()
        Lighting.GlobalShadows   = false
        Lighting.FogEnd          = 100000
        Lighting.Brightness      = 2
        Lighting.EnvironmentDiffuseScale  = 0
        Lighting.EnvironmentSpecularScale = 0
    end)

    -- 4) Desativa efeitos pesados
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
            pcall(function() obj.Enabled = false end)
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            pcall(function() obj.Enabled = false end)
        end
    end
end

local function RestoreAntiLag()
    -- Restaura tudo que foi removido
    for obj, data in pairs(OriginalProps) do
        if obj and obj.Parent then
            pcall(function()
                if data.key then
                    obj[data.key] = data.value
                else
                    obj.ColorMap     = data.ColorMap
                    obj.NormalMap    = data.NormalMap
                    obj.RoughnessMap = data.RoughnessMap
                    obj.MetalnessMap = data.MetalnessMap
                end
            end)
        end
    end
    OriginalProps = {}

    pcall(function()
        Workspace.Terrain.Decoration = true
        Lighting.GlobalShadows = true
    end)

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
            pcall(function() obj.Enabled = true end)
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            pcall(function() obj.Enabled = true end)
        end
    end
end

-- Monitorar novas partes que entram (mantém anti lag aplicado)
local AntiLagConn
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
Tabs.Goleiro:AddSection("Auto Dive (Mergulho Automático)")

Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Ativar Auto Dive",
    Default = false,
    Callback = function(v) State.AutoDiveEnabled = v end
})

Tabs.Goleiro:AddSlider("DiveRangeSlider", {
    Title = "Distância para mergulhar (studs)",
    Default = 40, Min = 10, Max = 100, Rounding = 0,
    Callback = function(v) State.AutoDiveRange = v end
})

Tabs.Goleiro:AddSlider("DiveCooldownSlider", {
    Title = "Cooldown entre mergulhos (s)",
    Default = 0.25, Min = 0.10, Max = 1.00, Rounding = 2,
    Callback = function(v) State.DiveCooldown = v end
})

Tabs.Goleiro:AddToggle("ForceVelocityToggle", {
    Title = "Forçar impulso físico (garantido)",
    Default = true,
    Callback = function(v) State.ForceVelocity = v end
})

Tabs.Goleiro:AddToggle("SmartDiveToggle", {
    Title = "Rotacionar corpo ao mergulhar (visual)",
    Default = true,
    Callback = function(v) State.SmartDive = v end
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
-- UI - FPS (NOVO)
-- ======================================================
Tabs.FPS:AddSection("Desempenho")

Tabs.FPS:AddToggle("AntiLagToggle", {
    Title = "Anti Lag (Remove Texturas)",
    Description = "Remove texturas, partículas, sombras e efeitos para deixar o jogo mais leve.",
    Default = false,
    Callback = function(v)
        SetAntiLag(v)
        Fluent:Notify({
            Title = "Maritaca FPS",
            Content = v and "Anti Lag ATIVADO — jogo mais leve!" or "Anti Lag desativado — texturas restauradas.",
            Duration = 4
        })
    end
})

Tabs.FPS:AddButton({
    Title = "Aplicar Anti Lag Agora",
    Description = "Roda o Anti Lag sem precisar reiniciar.",
    Callback = function()
        SetAntiLag(true)
        Fluent:Notify({ Title = "Maritaca FPS", Content = "Anti Lag aplicado!", Duration = 3 })
    end
})

Tabs.FPS:AddButton({
    Title = "Restaurar Texturas",
    Description = "Restaura tudo que o Anti Lag removeu.",
    Callback = function()
        SetAntiLag(false)
        Fluent:Notify({ Title = "Maritaca FPS", Content = "Texturas restauradas.", Duration = 3 })
    end
})

-- ======================================================
-- UI - DEBUG
-- ======================================================
Tabs.Debug:AddSection("Debug / Diagnóstico")

Tabs.Debug:AddToggle("DebugToggle", {
    Title = "Modo Debug (imprime no console)",
    Default = false,
    Callback = function(v) State.DebugMode = v end
})

Tabs.Debug:AddButton({
    Title = "Forçar Mergulho Esquerda (teste)",
    Callback = function()
        local ball = GetBall()
        local pos = ball and ball.Position or (Character.HumanoidRootPart.Position + Vector3.new(-15, 0, 0))
        ExecuteDive(pos, false, false)
    end
})

Tabs.Debug:AddButton({
    Title = "Forçar Mergulho Direita (teste)",
    Callback = function()
        local ball = GetBall()
        local pos = ball and ball.Position or (Character.HumanoidRootPart.Position + Vector3.new(15, 0, 0))
        ExecuteDive(pos, true, false)
    end
})

-- ======================================================
-- NOTIFICAÇÃO E SELEÇÃO
-- ======================================================
Fluent:Notify({
    Title = "Maritaca Hub V10",
    Content = "Auto Dive (triplo) + Anti Lag carregados. Teste o Dive na aba Debug!",
    Duration = 6
})

Window:SelectTab(1)
