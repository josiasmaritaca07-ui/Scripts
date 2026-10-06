-- ======================================================
-- MARITACA HUB | Futebol Clássico (V7 DEFINITIVE FIX)
-- By Maritaca
-- ======================================================

local IMAGE_ASSET_ID = "rbxassetid://1000109123"

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

-- Fundo Totalmente Preto Sólido
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

-- Serviços do Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- ======================================================
-- DETECÇÃO DA BOLA NO MAPA
-- ======================================================
local function GetBall()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name == "ball" or name == "bola" or name == "football" or obj:FindFirstChildOfClass("TouchInterest") then
                return obj
            end
        end
    end
    return nil
end

-- ======================================================
-- SISTEMA DE ACIONAMENTO DOS BOTÕES DO GOLEIRO (DIVE)
-- ======================================================
local function TriggerKeeperButton(btnName)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, v in ipairs(playerGui:GetDescendants()) do
            if (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Visible then
                if (v.Text and v.Text:lower():find(btnName:lower())) or v.Name:lower():find(btnName:lower()) then
                    -- Dispara o evento de clique do botão nativo do jogo
                    pcall(function()
                        for _, signal in ipairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
                            firesignal(v[signal])
                        end
                    end)
                end
            end
        end
    end
    
    -- Dispara também nos Remotes do Servidor caso o jogo utilize
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") and (remote.Name:lower():find("dive") or remote.Name:lower():find("keeper")) then
            pcall(function()
                remote:FireServer(btnName)
            end)
        end
    end
end

-- ======================================================
-- BOLA FLUTUANTE COM FOTO PERSONALIZADA
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
-- CÍRCULO VISUAL DE REACH (SELECTION BOX NA BOLA)
-- ======================================================
local ReachHighlight = Instance.new("SelectionBox")
ReachHighlight.Name = "MaritacaReachHighlight"
ReachHighlight.Color3 = Color3.fromRGB(0, 255, 120)
ReachHighlight.LineThickness = 0.08
ReachHighlight.SurfaceColor3 = Color3.fromRGB(0, 255, 120)
ReachHighlight.SurfaceTransparency = 0.7

local SphereVisual = Instance.new("Part")
SphereVisual.Name = "MaritacaSphereVisual"
SphereVisual.Shape = Enum.PartType.Ball
SphereVisual.Material = Enum.Material.Neon
SphereVisual.Color = Color3.fromRGB(0, 255, 120)
SphereVisual.Transparency = 0.6
SphereVisual.CanCollide = false
SphereVisual.Anchored = true

-- ======================================================
-- LOOP AUTO DIVE (GOLEIRO AUTOMÁTICO)
-- ======================================================
local lastDiveTime = 0

RunService.RenderStepped:Connect(function()
    if not AutoDiveEnabled then return end
    
    local ball = GetBall()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if ball and root then
        local ballPos = ball.Position
        local rootPos = root.Position
        local dist = (rootPos - ballPos).Magnitude
        
        -- Quando a bola se aproxima da área do goleiro (32 studs)
        if dist <= 32 and (tick() - lastDiveTime) > 0.4 then
            lastDiveTime = tick()
            
            local localPos = root.CFrame:PointToObjectSpace(ballPos)
            local isRight = localPos.X > 0
            local isHigh = ballPos.Y > (rootPos.Y + 1.2)
            
            -- Pula e ativa o botão correspondente
            if isRight and isHigh then
                TriggerKeeperButton("Direita Alto")
            elseif isRight and not isHigh then
                TriggerKeeperButton("Direita Baixo")
            elseif not isRight and isHigh then
                TriggerKeeperButton("Esquerda Alto")
            else
                TriggerKeeperButton("Esquerda Baixo")
            end
            
            -- Aplica impulso físico direto no goleiro em direção à bola
            local diveDir = (ballPos - rootPos).Unit
            root.AssemblyLinearVelocity = diveDir * 65 + Vector3.new(0, 25, 0)
        end
    end
end)

-- ======================================================
-- LOOP REACH + EXIBIÇÃO CORRETA DO CÍRCULO VERDE
-- ======================================================
RunService.Heartbeat:Connect(function()
    local ball = GetBall()
    local root = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if ball and root then
        local reachRadius = ReachSize * 2.5
        
        -- Exibe a Esfera/Círculo Neon na Bola
        if ReachEnabled and ShowReachCircle then
            SphereVisual.Parent = Workspace
            SphereVisual.Size = Vector3.new(reachRadius * 2, reachRadius * 2, reachRadius * 2)
            SphereVisual.CFrame = ball.CFrame
        else
            SphereVisual.Parent = nil
        end

        -- Aplicação Física do Reach
        if ReachEnabled then
            local dist = (root.Position - ball.Position).Magnitude
            if dist <= reachRadius then
                -- Teleporta a interativação de toque de todas as partes do corpo para a bola
                for _, part in ipairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        firetouchinterest(part, ball, 0)
                        firetouchinterest(part, ball, 1)
                    end
                end
            end
        end
    else
        SphereVisual.Parent = nil
    end
end)

-- ======================================================
-- INTERFACE (UI)
-- ======================================================
Tabs.Goleiro:AddSection("Auto Dive (Pulo Automático)")

Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Ativar Auto Dive",
    Default = false,
    Callback = function(v)
        AutoDiveEnabled = v
    end
})

Tabs.Reach:AddSection("Ajustes de Reach e Hitbox")

Tabs.Reach:AddToggle("ReachToggle", {
    Title = "Ativar Reach",
    Default = false,
    Callback = function(v)
        ReachEnabled = v
    end
})

Tabs.Reach:AddSlider("ReachSlider", {
    Title = "Tamanho do Reach (Alcance)",
    Default = 5,
    Min = 1,
    Max = 12,
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
    Content = "Auto Dive e Círculo do Reach 100% corrigidos!",
    Duration = 5
})

Window:SelectTab(1)
