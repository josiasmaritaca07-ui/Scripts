-- ======================================================
-- MARITACA HUB - Futebol Clássico
-- By Maritaca
-- Tema: Escuro (Preto) + Botão Flutuante (Toggle UI)
-- ======================================================

-- Carregando a Biblioteca de UI (Fluent Library)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

-- Criando a Janela Principal
local Window = Fluent:CreateWindow({
    Title = "Maritaca Hub | Futebol Clássico",
    SubTitle = "by Maritaca",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 420),
    Acrylic = false, -- Mantém o painel bem preto/sólido
    Theme = "Darker", -- Estilo escuro
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Criando as Abas
local Tabs = {
    Goleiro = Window:AddTab({ Title = "Goleiro / Dive", Icon = "shield" }),
    Opcoes = Window:AddTab({ Title = "Configurações", Icon = "settings" })
}

-- Variáveis Globais de Controle
local AutoDiveEnabled = false
local DiveDistance = 15
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- ======================================================
-- CRIAÇÃO DA BOLA/BOTÃO FLUTUANTE PARA MINIMIZAR/ABRIR
-- ======================================================

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Remove botão antigo se já existir
if CoreGui:FindFirstChild("MaritacaToggleGui") then
    CoreGui.MaritacaToggleGui:Destroy()
end

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "MaritacaToggleGui"
ToggleGui.Parent = CoreGui
ToggleGui.ResetOnSpawn = false

local FloatButton = Instance.new("TextButton")
FloatButton.Name = "MaritacaBall"
FloatButton.Parent = ToggleGui
FloatButton.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
FloatButton.BorderColor3 = Color3.fromRGB(0, 150, 255)
FloatButton.BorderSizePixel = 2
FloatButton.Position = UDim2.new(0.05, 0, 0.2, 0)
FloatButton.Size = UDim2.new(0, 50, 0, 50)
FloatButton.Font = Enum.Font.SourceSansBold
FloatButton.Text = "M"
FloatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatButton.TextSize = 22
FloatButton.Active = true
FloatButton.Draggable = true -- Permite arrastar a bola pela tela

-- Deixa o botão redondo (Formato de Bola/Logo)
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FloatButton

-- Efeito de brilho/sombra
local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = FloatButton
UIStroke.Color = Color3.fromRGB(0, 150, 255)
UIStroke.Thickness = 2

-- Função de alternar a visibilidade da janela ao clicar na bola
local isVisible = true
FloatButton.MouseButton1Click:Connect(function()
    isVisible = not isVisible
    Window:Minimize() -- Alterna visibilidade da janela
end)

-- ======================================================
-- LÓGICA DO AUTO DIVE (GOLEIRO AUTOMÁTICO SEM DELAY)
-- ======================================================

local function GetBall()
    return workspace:FindFirstChild("Ball") or workspace:FindFirstChild("Bola") or workspace:FindFirstChildOfClass("Part")
end

task.spawn(function()
    while task.wait(0.01) do
        if AutoDiveEnabled then
            local root = Character and Character:FindFirstChild("HumanoidRootPart")
            local humanoid = Character and Character:FindFirstChild("Humanoid")
            local ball = GetBall()

            if root and humanoid and ball then
                local distance = (root.Position - ball.Position).Magnitude

                if distance <= DiveDistance then
                    local direction = (ball.Position - root.Position).Unit
                    root.Velocity = direction * 50 + Vector3.new(0, 25, 0)
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.5)
                end
            end
        end
    end
end)

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
end)

-- ======================================================
-- ELEMENTOS DA INTERFACE (UI)
-- ======================================================

Tabs.Goleiro:AddSection("Funções de Goleiro")

Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Auto Dive (Defesa Automática)",
    Default = false,
    Callback = function(Value)
        AutoDiveEnabled = Value
        if Value then
            Fluent:Notify({
                Title = "Maritaca Hub",
                Content = "Auto Dive Ativado!",
                Duration = 3
            })
        end
    end
})

Tabs.Goleiro:AddSlider("DiveDistanceSlider", {
    Title = "Distância de Reação (Metros)",
    Default = 15,
    Min = 5,
    Max = 35,
    Rounding = 0,
    Callback = function(Value)
        DiveDistance = Value
    end
})

-- Notificação Inicial
Fluent:Notify({
    Title = "Maritaca Hub",
    Content = "Carregado! Clique no botão 'M' para abrir/fechar o menu.",
    Duration = 5
})

Window:SelectTab(1)
