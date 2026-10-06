-- ======================================================
-- MARITACA HUB | Futebol Clássico (V2 Refeito)
-- By Maritaca
-- Auto Dive Inteligente Nativo + Reach com Círculo 3D
-- ======================================================

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

local Tabs = {
    Goleiro = Window:AddTab({ Title = "Goleiro / Dive", Icon = "shield" }),
    Reach = Window:AddTab({ Title = "Reach", Icon = "target" })
}

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Variáveis de Estado
local AutoDiveEnabled = false
local ReachEnabled = false
local ReachValue = 5
local ShowReachCircle = true

-- Busca a bola atual no Workspace
local function GetBall()
    for _, obj in ipairs(workspace:GetChildren()) do
        if (obj.Name:lower():find("ball") or obj.Name:lower():find("bola")) and obj:IsA("BasePart") then
            return obj
        end
    end
    return nil
end

-- ======================================================
-- DISPARADOR DOS BOTÕES DO JOGO (REMOTE EVENTS)
-- ======================================================

local function TriggerKeeperAction(actionName)
    -- Tenta disparar os eventos nativos do jogo/UI
    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events") or ReplicatedStorage
    local actionEvent = remotes:FindFirstChild(actionName) or remotes:FindFirstChild("Dive") or remotes:FindFirstChild("Keeper")
    
    if actionEvent and actionEvent:IsA("RemoteEvent") then
        actionEvent:FireServer(actionName)
    else
        -- Fallback: Simula clique no botão da UI do jogo
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, v in ipairs(playerGui:GetDescendants()) do
                if v:IsA("TextButton") or v:IsA("ImageButton") then
                    if v.Name:lower() == actionName:lower() or (v.Text and v.Text:lower() == actionName:lower()) then
                        for _, signal in ipairs({"MouseButton1Click", "Activated"}) do
                            firesignal(v[signal])
                        end
                    end
                end
            end
        end
    end
end

-- ======================================================
-- CRIAÇÃO DO CÍRCULO 3D DO REACH (Cylinder Visualizer)
-- ======================================================

local CirclePart = Instance.new("Part")
CirclePart.Name = "MaritacaReachCircleVisual"
CirclePart.Shape = Enum.PartType.Cylinder
CirclePart.Material = Enum.Material.Neon
CirclePart.Color = Color3.fromRGB(0, 255, 120)
CirclePart.Transparency = 0.6
CirclePart.Anchored = true
CirclePart.CanCollide = false
CirclePart.Size = Vector3.new(0.1, 1, 1)

-- ======================================================
-- BOLA FLUTUANTE (TOGGLE MENU)
-- ======================================================

if CoreGui:FindFirstChild("MaritacaBtnGui") then
    CoreGui.MaritacaBtnGui:Destroy()
end

local BtnGui = Instance.new("ScreenGui")
BtnGui.Name = "MaritacaBtnGui"
BtnGui.Parent = CoreGui
BtnGui.ResetOnSpawn = false

local FloatBall = Instance.new("TextButton")
FloatBall.Name = "MaritacaBall"
FloatBall.Parent = BtnGui
FloatBall.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
FloatBall.BorderColor3 = Color3.fromRGB(0, 150, 255)
FloatBall.BorderSizePixel = 2
FloatBall.Position = UDim2.new(0.08, 0, 0.2, 0)
FloatBall.Size = UDim2.new(0, 50, 0, 50)
FloatBall.Font = Enum.Font.SourceSansBold
FloatBall.Text = "M"
FloatBall.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBall.TextSize = 22
FloatBall.Active = true
FloatBall.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FloatBall

FloatBall.MouseButton1Click:Connect(function()
    Window:Minimize()
end)

-- ======================================================
-- LOOP AUTO DIVE (CÁLCULO DIREIONAL: ALTURA E LADO)
-- ======================================================

local lastDiveTime = 0

RunService.RenderStepped:Connect(function()
    if not AutoDiveEnabled then return end
    
    local ball = GetBall()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if ball and root then
        local ballPos = ball.Position
        local rootPos = root.Position
        local distance = (rootPos - ballPos).Magnitude
        
        -- Quando a bola entra na área de defesa (raio de reação)
        if distance <= 22 and (tick() - lastDiveTime) > 0.8 then
            lastDiveTime = tick()
            
            -- Converte a posição da bola para o espaço local do jogador (Esquerda/Direita)
            local localPos = root.CFrame:PointToObjectSpace(ballPos)
            
            local isRight = localPos.X > 0
            local isHigh = ballPos.Y > (rootPos.Y + 1.5)
            
            -- Escolhe a ação exata baseada na trajetória da bola
            if isRight and isHigh then
                TriggerKeeperAction("Direita Alto")
            elseif isRight and not isHigh then
                TriggerKeeperAction("Direita Baixo")
            elseif not isRight and isHigh then
                TriggerKeeperAction("Esquerda Alto")
            else
                TriggerKeeperAction("Esquerda Baixo")
            end
            
            -- Impulso físico complementar para garantir o salto
            local dir = (ballPos - rootPos).Unit
            root.Velocity = dir * 55 + Vector3.new(0, 25, 0)
        end
    end
end)

-- ======================================================
-- LOOP DO REACH + CÍRCULO VISUAL
-- ======================================================

RunService.RenderStepped:Connect(function()
    local ball = GetBall()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if ReachEnabled and ball and root then
        -- Calcula o raio do Reach (Nível 1 a 10)
        local reachRadius = ReachValue * 2.5
        local dist = (root.Position - ball.Position).Magnitude
        
        -- Toca na bola remotamente se estiver no raio
        if dist <= reachRadius then
            firetouchinterest(root, ball, 0)
            firetouchinterest(root, ball, 1)
        end
        
        -- Atualiza Círculo 3D na bola
        if ShowReachCircle then
            CirclePart.Parent = workspace
            CirclePart.Size = Vector3.new(0.2, reachRadius * 2, reachRadius * 2)
            CirclePart.CFrame = CFrame.new(ball.Position) * CFrame.Angles(0, 0, math.rad(90))
        else
            CirclePart.Parent = nil
        end
    else
        CirclePart.Parent = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(nChar)
    Character = nChar
end)

-- ======================================================
-- INTERFACE (UI FLUENT)
-- ======================================================

Tabs.Goleiro:AddSection("Auto Dive Inteligente")

Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Auto Dive (Modo Goleiro)",
    Default = false,
    Callback = function(v)
        AutoDiveEnabled = v
    end
})

Tabs.Reach:AddSection("Ajustes do Reach")

Tabs.Reach:AddToggle("ReachToggle", {
    Title = "Ativar Reach",
    Default = false,
    Callback = function(v)
        ReachEnabled = v
    end
})

Tabs.Reach:AddSlider("ReachSlider", {
    Title = "Nível do Reach (1-10)",
    Default = 5,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(v)
        ReachValue = v
    end
})

Tabs.Reach:AddToggle("ReachCircleToggle", {
    Title = "Mostrar Círculo na Bola",
    Default = true,
    Callback = function(v)
        ShowReachCircle = v
    end
})

Fluent:Notify({
    Title = "Maritaca Hub",
    Content = "Script totalmente corrigido! Clique na bola 'M' para abrir/fechar.",
    Duration = 5
})

Window:SelectTab(1)
