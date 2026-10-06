-- ======================================================
-- MARITACA HUB | Futebol Clássico (V9 - DEFINITIVO)
-- By Maritaca | Auto-Discovery + Debug
-- ======================================================

local IMAGE_ASSET_ID = "rbxassetid://1000109123"

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Maritaca Hub | Futebol Clássico",
    SubTitle = "by Maritaca",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 420),
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
    Goleiro  = Window:AddTab({ Title = "Goleiro / Dive", Icon = "shield" }),
    Reach    = Window:AddTab({ Title = "Reach & Hitbox", Icon = "target" }),
    Debug    = Window:AddTab({ Title = "Debug / Info", Icon = "terminal" })
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
local GuiService        = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    task.wait(0.5)
end)

-- ======================================================
-- ESTADO GLOBAL
-- ======================================================
local State = {
    AutoDiveEnabled   = false,
    ReachEnabled      = false,
    ReachSize         = 5,
    ShowReachCircle   = true,
    DebugMode         = false,
    DiveCooldown      = 0.30,
    AutoDiveRange     = 35,
    ForceVelocity     = true,
    lastDiveTime      = 0,
    lastDebugPrint    = 0,
}

-- ======================================================
-- DETECÇÃO DE BOLA (CACHE + VÁRIAS ESTRATÉGIAS)
-- ======================================================
local BallCache     = nil
local LastBallScan  = 0

local function LooksLikeBall(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    if n == "ball" or n == "bola" or n == "football" or n == "soccerball" then return true end
    if n:find("ball") or n:find("bola") then return true end
    -- Bola costuma ser esférica
    if obj.Shape == Enum.PartType.Ball then return true end
    return false
end

local function ScanForBall()
    -- 1) Direto no workspace
    for _, obj in ipairs(Workspace:GetChildren()) do
        if LooksLikeBall(obj) then return obj end
    end
    -- 2) Dentro de folders/models de primeiro nível
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
    if BallCache and BallCache.Parent and LooksLikeBall(BallCache) then
        return BallCache
    end
    if tick() - LastBallScan < 0.4 then return BallCache end
    LastBallScan = tick()
    BallCache = ScanForBall()
    return BallCache
end

-- ======================================================
-- DESCOBERTA AUTOMÁTICA DE BOTÕES DO GOLEIRO
-- ======================================================
-- Estratégia: procura botões na PlayerGui e classifica por posição.
-- Cobre TextButton, ImageButton, e também botões dentro de ViewportFrame.
local function GetAllButtons()
    local list = {}
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return list end
    for _, v in ipairs(pg:GetDescendants()) do
        if (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Visible then
            if v.AbsoluteSize.X >= 20 and v.AbsoluteSize.Y >= 20 then
                table.insert(list, v)
            end
        end
    end
    return list
end

local function FireButton(btn)
    if not btn then return false end
    local ok = false
    -- 1) firesignal em todos os eventos possíveis
    for _, evt in ipairs({"MouseButton1Click", "MouseButton1Down", "Activated", "MouseButton1Up"}) do
        local conn = btn[evt]
        if conn then
            pcall(function() firesignal(conn) ok = true end)
        end
    end
    -- 2) Simulação de clique real por input (mais confiável em alguns jogos)
    pcall(function()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, true,  game, 1)
        task.wait(0.02)
        VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        ok = true
    end)
    return ok
end

-- Classifica os botões da tela em quadrantes (esquerda/direita + alto/baixo)
local function ClassifyButtons()
    local btns = GetAllButtons()
    if #btns < 2 then return nil end

    local vp = Camera.ViewportSize
    local midX, midY = vp.X / 2, vp.Y / 2

    local left, right = {}, {}
    for _, b in ipairs(btns) do
        local cx = b.AbsolutePosition.X + b.AbsoluteSize.X / 2
        local cy = b.AbsolutePosition.Y + b.AbsoluteSize.Y / 2
        -- Descarta botões muito no topo da tela (HUD, chat, etc.)
        if cy > vp.Y * 0.45 then
            if cx < midX then
                table.insert(left, {btn = b, y = cy})
            else
                table.insert(right, {btn = b, y = cy})
            end
        end
    end

    table.sort(left,  function(a,b) return a.y < b.y end)
    table.sort(right, function(a,b) return a.y < b.y end)

    return left, right
end

local LastButtonDump = 0
local function DumpButtons()
    if tick() - LastButtonDump < 2 then return end
    LastButtonDump = tick()
    local btns = GetAllButtons()
    print("========== [Maritaca] BOTÕES ENCONTRADOS:", #btns, "==========")
    for i, b in ipairs(btns) do
        print(string.format("[%d] %s | Text=%q | Pos=(%d,%d) | Size=(%d,%d)",
            i, b:GetFullName(), b.Text or "",
            b.AbsolutePosition.X, b.AbsolutePosition.Y,
            b.AbsoluteSize.X, b.AbsoluteSize.Y))
    end
end

local function TriggerDive(isRight, isHigh)
    local left, right = ClassifyButtons()
    if not left or not right then
        if State.DebugMode then
            warn("[Maritaca] Não foi possível classificar botões de dive.")
            DumpButtons()
        end
        return false
    end
    local side = isRight and right or left
    if #side == 0 then return false end
    -- Mais alto = primeiro (menor Y), mais baixo = último (maior Y)
    local pick = isHigh and side[1] or side[#side]
    local ok = FireButton(pick.btn)
    if State.DebugMode then
        print(("[Maritaca] Dive -> lado=%s altura=%s botao=%s ok=%s")
            :format(isRight and "direita" or "esquerda",
                    isHigh and "alto" or "baixo",
                    pick.btn:GetFullName(), tostring(ok)))
    end
    return ok
end

-- ======================================================
-- DESCOBERTA DE REMOTES (para jogos que usam RemoteEvent)
-- ======================================================
local DiveRemotes = {}
local function ScanRemotes()
    DiveRemotes = {}
    local keywords = {"dive", "keeper", "goalie", "goleiro", "defend", "save", "pulo"}
    local function check(container)
        for _, v in ipairs(container:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                local n = v.Name:lower()
                for _, k in ipairs(keywords) do
                    if n:find(k) then
                        table.insert(DiveRemotes, v)
                        break
                    end
                end
            end
        end
    end
    pcall(check, ReplicatedStorage)
    pcall(check, Workspace)
    if State.DebugMode then
        print("[Maritaca] Remotes de dive encontrados:", #DiveRemotes)
        for _, r in ipairs(DiveRemotes) do print("  ", r:GetFullName()) end
    end
end
ScanRemotes()

local function FireRemotes(dirX, high)
    for _, r in ipairs(DiveRemotes) do
        pcall(function()
            if r:IsA("RemoteEvent") then
                r:FireServer(dirX, high)
                r:FireServer({dir = dirX, high = high})
                r:FireServer(dirX > 0 and "right" or "left", high and "high" or "low")
            elseif r:IsA("RemoteFunction") then
                r:InvokeServer(dirX, high)
            end
        end)
    end
end

-- ======================================================
-- BOLA FLUTUANTE (BOTÃO QUE MINIMIZA A JANELA)
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
FloatBall.BackgroundColor3 = Color3.fromRGB(0,0,0)
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
UIStroke.Color = Color3.fromRGB(255,255,255)
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

    -- Só dispara se estiver perto, em movimento e fora de cooldown
    if dist <= State.AutoDiveRange and vel > 6 and (tick() - State.lastDiveTime) > State.DiveCooldown then
        State.lastDiveTime = tick()

        local localPos = root.CFrame:PointToObjectSpace(ballPos)
        local isRight  = localPos.X > 0
        local isHigh   = ballPos.Y > (rootPos.Y + 1.2)

        -- Tenta primeiro remotes (mais "legítimo" para o jogo)
        FireRemotes(isRight and 1 or -1, isHigh)

        -- Tenta clicar no botão da UI
        TriggerDive(isRight, isHigh)

        -- Impulso físico opcional
        if State.ForceVelocity then
            local flat = Vector3.new(ballPos.X - rootPos.X, 0, ballPos.Z - rootPos.Z)
            if flat.Magnitude > 0.5 then
                local dir = flat.Unit
                root.AssemblyLinearVelocity = dir * 45 + Vector3.new(0, 20, 0)
            end
        end
    end
end)

-- ======================================================
-- LOOP REACH + HIGHLIGHT
-- ======================================================
RunService.Heartbeat:Connect(function()
    local ball = GetBall()
    local char = Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if ball and root then
        local reachRadius = State.ReachSize * 2.5

        -- Atualiza visual
        if State.ReachEnabled and State.ShowReachCircle then
            if SphereVisual.Parent ~= Workspace then
                SphereVisual.Parent = Workspace
            end
            local s = reachRadius * 2
            SphereVisual.Size = Vector3.new(s, s, s)
            SphereVisual.CFrame = ball.CFrame
        elseif SphereVisual.Parent then
            SphereVisual.Parent = nil
        end

        -- Aplica touch interest
        if State.ReachEnabled then
            local dist = (root.Position - ball.Position).Magnitude
            if dist <= reachRadius then
                -- Aplica em todas as partes do personagem (garante toque)
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function()
                            firetouchinterest(part, ball, 0)
                            firetouchinterest(part, ball, 1)
                        end)
                    end
                end
                -- Ativa ProximityPrompts próximos (alguns jogos usam)
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
-- UI - GOLEIRO
-- ======================================================
Tabs.Goleiro:AddSection("Auto Dive (Pulo Automático)")

Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Ativar Auto Dive",
    Default = false,
    Callback = function(v) State.AutoDiveEnabled = v end
})

Tabs.Goleiro:AddSlider("DiveRangeSlider", {
    Title = "Distância para mergulhar",
    Default = 35, Min = 10, Max = 80, Rounding = 0,
    Callback = function(v) State.AutoDiveRange = v end
})

Tabs.Goleiro:AddSlider("DiveCooldownSlider", {
    Title = "Cooldown entre mergulhos (s)",
    Default = 0.30, Min = 0.10, Max = 1.00, Rounding = 2,
    Callback = function(v) State.DiveCooldown = v end
})

Tabs.Goleiro:AddToggle("ForceVelocityToggle", {
    Title = "Forçar impulso físico do goleiro",
    Default = true,
    Callback = function(v) State.ForceVelocity = v end
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
-- UI - DEBUG
-- ======================================================
Tabs.Debug:AddSection("Debug / Diagnóstico")

Tabs.Debug:AddToggle("DebugToggle", {
    Title = "Modo Debug (imprime no console)",
    Default = false,
    Callback = function(v) State.DebugMode = v end
})

Tabs.Debug:AddButton({
    Title = "Listar Botões na Tela",
    Description = "Imprime no console (F9) todos os botões clicáveis encontrados.",
    Callback = function() DumpButtons() end
})

Tabs.Debug:AddButton({
    Title = "Escanear Remotes de Dive",
    Description = "Procura RemoteEvents relacionados a dive/goleiro.",
    Callback = function()
        ScanRemotes()
        Fluent:Notify({
            Title = "Maritaca",
            Content = "Encontrados " .. #DiveRemotes .. " remotes de dive. Veja o console (F9).",
            Duration = 4
        })
    end
})

Tabs.Debug:AddButton({
    Title = "Forçar Mergulho Esquerda",
    Description = "Testa manualmente o mergulho para a esquerda.",
    Callback = function() TriggerDive(false, false) end
})

Tabs.Debug:AddButton({
    Title = "Forçar Mergulho Direita",
    Description = "Testa manualmente o mergulho para a direita.",
    Callback = function() TriggerDive(true, false) end
})

-- ======================================================
-- NOTIFICAÇÃO E SELEÇÃO DE ABA
-- ======================================================
Fluent:Notify({
    Title = "Maritaca Hub",
    Content = "V9 carregado! Use a aba Debug para diagnosticar.",
    Duration = 6
})

Window:SelectTab(1)

-- Auto-dump na primeira execução para facilitar diagnóstico
task.spawn(function()
    task.wait(3)
    ScanRemotes()
end)
