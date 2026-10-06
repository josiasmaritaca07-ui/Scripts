-- ======================================================
-- MARITACA HUB | Futebol Clássico (VERSÃO DEFINITIVA 100% WORKING)
-- By Maritaca
-- ======================================================

local IMAGE_ASSET_ID = "rbxassetid://1000109123" -- Foto da personagem na bola flutuante

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Criando a Janela do Menu
local Window = Fluent:CreateWindow({
    Title = "Maritaca Hub | Futebol Clássico",
    SubTitle = "by Maritaca",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 420),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Deixa o fundo do menu 100% Preto Sólido
task.spawn(function()
    task.wait(0.1)
    if Window.Frame then
        Window.Frame.BackgroundTransparency = 0
        Window.Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    end
end)

local Tabs = {
    Goleiro = Window:AddTab({ Title = "Goleiro / Dive", Icon = "shield" }),
    Reach = Window:AddTab({ Title = "Reach & Hitbox", Icon = "target" })
}

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
end)

-- Variáveis Globais
local AutoDiveEnabled = false
local ReachEnabled = false
local ReachSize = 5
local ShowReachCircle = true

-- Função para achar a Bola no Mapa
local function GetBall()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n == "ball" or n == "bola" or obj:FindFirstChild("TouchInterest") then
                return obj
            end
        end
    end
    return nil
end

-- ======================================================
-- SISTEMA QUE ACIONA OS BOTÕES DE DEFESA DO JOGO (AUTO DIVE)
-- ======================================================
local function TriggerGameButton(buttonName)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    for _, guiElement in ipairs(playerGui:GetDescendants()) do
        if guiElement:IsA("TextButton") or guiElement:IsA("ImageButton") then
            if guiElement.Text and guiElement.Text:lower():find(buttonName:lower()) then
                -- Dispara o evento de clique nativo do Roblox
                for _, connection in ipairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
                    firesignal(guiElement[connection])
                end
            end
        end
    end
end

-- ======================================================
-- BOLA FLUTUANTE COM FOTO (TOGGLE MENU)
-- ======================================================
if CoreGui:FindFirstChild("MaritacaBtnGui") then
    CoreGui.MaritacaBtnGui:Destroy()
end

local BtnGui = Instance.new("ScreenGui")
BtnGui.Name = "MaritacaBtnGui"
BtnGui.Parent = CoreGui
BtnGui.ResetOnSpawn = false

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
-- CÍRCULO 3D NO CHÃO EM VOLTA DA BOLA (REACH CIRCLE)
-- ======================================================
local CirclePart = Instance.new("Part")
CirclePart.Name = "MaritacaReachCirclePart"
CirclePart.Shape = Enum.PartType.Cylinder
CirclePart.Material = Enum.Material.Neon
CirclePart.Color = Color3.fromRGB(0, 255, 120)
CirclePart.Transparency = 0.5
CirclePart.Anchored = true
CirclePart.CanCollide = false
CirclePart.Size = Vector3.new(0.05, 1, 1)

-- ======================================================
-- LOOP DO AUTO DIVE (GOLEIRO AUTOMÁTICO)
-- ======================================================
local lastDiveTime = 0

RunService.RenderStepped:Connect(function()
    if not AutoDiveEnabled then return end
    
    local ball = GetBall()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if ball and root then
        local dist = (root.Position - ball.Position).Magnitude
        
        -- Distância exata de reação do goleiro
        if dist <= 25 and (tick() - lastDiveTime) > 0.7 then
            lastDiveTime = tick()
            
            -- Detecta se a bola vem na Esquerda/Direita e Alta/Baixa
            local localPos = root.CFrame:PointToObjectSpace(ball.Position)
            local isRight = localPos.X > 0
            local isHigh = ball.Position.Y > (root.Position.Y + 1.2)
            
            if isRight and isHigh then
                TriggerGameButton("Direita Alto")
            elseif isRight and not isHigh then
                TriggerGameButton("Direita Baixo")
            elseif not isRight and isHigh then
                TriggerGameButton("Esquerda Alto")
            else
                TriggerGameButton("Esquerda Baixo")
            end
        end
    end
end)

-- ======================================================
-- LOOP DO REACH + CÍRCULO VISUAL 3D
-- ======================================================
RunService.Heartbeat:Connect(function()
    local ball = GetBall()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if ball and root then
        local reachRadius = ReachSize * 2.2
        
        -- Mostrar/Esconder Círculo 3D na Bola
        if ReachEnabled and ShowReachCircle then
            CirclePart.Parent = Workspace
            CirclePart.Size = Vector3.new(0.05, reachRadius * 2, reachRadius * 2)
            CirclePart.CFrame = CFrame.new(ball.Position) * CFrame.Angles(0, 0, math.rad(90))
        else
            CirclePart.Parent = nil
        end

        -- Aplicação Real do Reach (Touch Remoto)
        if ReachEnabled then
            local dist = (root.Position - ball.Position).Magnitude
            if dist <= reachRadius then
                firetouchinterest(root, ball, 0)
                firetouchinterest(root, ball, 1)
            end
        end
    else
        CirclePart.Parent = nil
    end
end)

-- ======================================================
-- ELEMENTOS DA UI
-- ======================================================
Tabs.Goleiro:AddSection("Auto Dive Inteligente")

Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Ativar Auto Dive (Modo Goleiro)",
    Default = false,
    Callback = function(v)
        AutoDiveEnabled = v
    end
})

Tabs.Reach:AddSection("Controle de Reach & Hitbox")

Tabs.Reach:AddToggle("ReachToggle", {
    Title = "Ativar Reach",
    Default = false,
    Callback = function(v)
        ReachEnabled = v
    end
})

Tabs.Reach:AddSlider("ReachSlider", {
    Title = "Nível do Reach (1 a 10)",
    Default = 5,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(v)
        ReachSize = v
    end
})

Tabs.Reach:AddToggle("ReachCircleToggle", {
    Title = "Mostrar Círculo Verde na Bola",
    Default = true,
    Callback = function(v)
        ShowReachCircle = v
    end
})

Fluent:Notify({
    Title = "Maritaca Hub",
    Content = "Script 100% funcional carregado!",
    Duration = 5
})

Window:SelectTab(1)
