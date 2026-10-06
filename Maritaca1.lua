-- ======================================================
-- MARITACA HUB | Futebol Clássico
-- By Maritaca
-- UI Escura + Auto Dive + Reach com Círculo + Bola Flutuante
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

-- Variáveis Globais
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local AutoDiveEnabled = false
local ReachEnabled = false
local ReachValue = 5
local ShowReachCircle = true

-- Instância do Círculo do Reach
local ReachCircle = Instance.new("SelectionBox")
ReachCircle.Name = "MaritacaReachCircle"
ReachCircle.Color3 = Color3.fromRGB(0, 255, 120)
ReachCircle.LineThickness = 0.05
ReachCircle.Transparency = 0.3

-- Busca a Bola no Jogo
local function GetBall()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:lower():find("ball") or obj.Name:lower():find("bola") then
            if obj:IsA("BasePart") then
                return obj
            end
        end
    end
    return nil
end

-- ======================================================
-- BOLA FLUTUANTE (TOGGLE UI)
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
-- LÓGICA AUTO DIVE (PULO AUTOMÁTICO NA BOLA)
-- ======================================================

RunService.RenderStepped:Connect(function()
    if AutoDiveEnabled then
        local root = Character and Character:FindFirstChild("HumanoidRootPart")
        local humanoid = Character and Character:FindFirstChild("Humanoid")
        local ball = GetBall()

        if root and humanoid and ball then
            local dist = (root.Position - ball.Position).Magnitude

            -- Pula/Se joga no tempo certo quando a bola aproxima do gol/jogador
            if dist <= 18 then
                local diveDir = (ball.Position - root.Position).Unit
                root.Velocity = (diveDir * 65) + Vector3.new(0, 30, 0)
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.4)
            end
        end
    end
end)

-- ======================================================
-- LÓGICA REACH (AUMENTA ALCANCE E CÍRCULO)
-- ======================================================

RunService.RenderStepped:Connect(function()
    local ball = GetBall()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")

    if ReachEnabled and ball and root then
        -- Aumenta a Hitbox da Bola com base no valor (1 a 10)
        local reachRadius = ReachValue * 3
        local dist = (root.Position - ball.Position).Magnitude

        if dist <= reachRadius then
            firetouchinterest(root, ball, 0)
            firetouchinterest(root, ball, 1)
        end

        -- Exibição do Círculo em volta da Bola
        if ShowReachCircle then
            ReachCircle.Adornee = ball
            ReachCircle.Parent = ball
        else
            ReachCircle.Parent = nil
        end
    else
        ReachCircle.Parent = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(nChar)
    Character = nChar
end)

-- ======================================================
-- COMPONENTES DA UI
-- ======================================================

-- Aba Goleiro
Tabs.Goleiro:AddSection("Auto Dive")

Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Auto Dive (Modo Goleiro)",
    Default = false,
    Callback = function(v)
        AutoDiveEnabled = v
    end
})

-- Aba Reach
Tabs.Reach:AddSection("Reach & Hitbox")

Tabs.Reach:AddToggle("ReachToggle", {
    Title = "Ativar Reach",
    Default = false,
    Callback = function(v)
        ReachEnabled = v
    end
})

Tabs.Reach:AddSlider("ReachSlider", {
    Title = "Distância / Nível do Reach",
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
    Content = "Script carregado! Toque no botão 'M' para abrir/fechar.",
    Duration = 5
})

Window:SelectTab(1)
