local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Jogador local
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

------------------------------------------------------------
-- CONFIGURAÇÕES
------------------------------------------------------------
local Config = {
    AutoDive = false,
    AutoCatch = false,
    Reach = 5,
}

------------------------------------------------------------
-- ESCOLHER ONDE COLOCAR A UI (compatibilidade)
------------------------------------------------------------
local parentGui
pcall(function()
    parentGui = game:GetService("CoreGui")
end)
if not parentGui then
    pcall(function()
        parentGui = LocalPlayer:WaitForChild("PlayerGui")
    end)
end
if not parentGui then
    parentGui = LocalPlayer:WaitForChild("PlayerGui")
end

-- Remove UI antiga se existir
for _, gui in ipairs(parentGui:GetChildren()) do
    if gui.Name == "BlueHubUI" then
        gui:Destroy()
    end
end

------------------------------------------------------------
-- CRIAÇÃO DA UI
------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BlueHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

-- Painel principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(60, 130, 255)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.4
MainStroke.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "BLUE HUB | GK"
Title.TextColor3 = Color3.fromRGB(100, 170, 255)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Botão de fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Container de botões
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, -40, 1, -70)
ButtonContainer.Position = UDim2.new(0, 20, 0, 60)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainFrame

-- Função para criar botão
local function createButton(text, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 45)
    btn.Position = UDim2.new(0, 0, 0, (order - 1) * 55)
    btn.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
    btn.BorderSizePixel = 0
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 220, 255)
    btn.TextSize = 16
    btn.Font = Enum.Font.GothamMedium
    btn.AutoButtonColor = false
    btn.Parent = ButtonContainer

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(60, 130, 255)
    s.Thickness = 1
    s.Transparency = 0.5
    s.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(35, 50, 85)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(25, 35, 60)
        }):Play()
    end)

    return btn
end

local AutoDiveBtn = createButton("GK - Auto Dive", 1)
local AutoCatchBtn = createButton("Auto Catch", 2)

-- Label do Reach
local ReachLabel = Instance.new("TextLabel")
ReachLabel.Size = UDim2.new(1, 0, 0, 25)
ReachLabel.Position = UDim2.new(0, 0, 0, 120)
ReachLabel.BackgroundTransparency = 1
ReachLabel.Text = "Reach: 5"
ReachLabel.TextColor3 = Color3.fromRGB(180, 210, 255)
ReachLabel.TextSize = 15
ReachLabel.Font = Enum.Font.GothamMedium
ReachLabel.TextXAlignment = Enum.TextXAlignment.Left
ReachLabel.Parent = ButtonContainer

-- Slider
local SliderBG = Instance.new("Frame")
SliderBG.Size = UDim2.new(1, 0, 0, 12)
SliderBG.Position = UDim2.new(0, 0, 0, 155)
SliderBG.BackgroundColor3 = Color3.fromRGB(30, 40, 65)
SliderBG.BorderSizePixel = 0
SliderBG.Parent = ButtonContainer

local SliderBGCorner = Instance.new("UICorner")
SliderBGCorner.CornerRadius = UDim.new(0, 6)
SliderBGCorner.Parent = SliderBG

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.5, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(60, 130, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBG

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(0, 6)
SliderFillCorner.Parent = SliderFill

local SliderKnob = Instance.new("Frame")
SliderKnob.Size = UDim2.new(0, 20, 0, 20)
SliderKnob.Position = UDim2.new(0.5, -10, 0.5, -10)
SliderKnob.BackgroundColor3 = Color3.fromRGB(220, 235, 255)
SliderKnob.BorderSizePixel = 0
SliderKnob.ZIndex = 2
SliderKnob.Parent = SliderBG

local SliderKnobCorner = Instance.new("UICorner")
SliderKnobCorner.CornerRadius = UDim.new(1, 0)
SliderKnobCorner.Parent = SliderKnob

-- Lógica do slider
local isDragging = false

local function updateSlider(inputX)
    local bgAbs = SliderBG.AbsolutePosition.X
    local bgSize = SliderBG.AbsoluteSize.X
    if bgSize <= 0 then return end
    local rel = math.clamp((inputX - bgAbs) / bgSize, 0, 1)
    local val = math.floor(rel * 9 + 1)
    Config.Reach = val
    local fill = (val - 1) / 9
    SliderFill.Size = UDim2.new(fill, 0, 1, 0)
    SliderKnob.Position = UDim2.new(fill, -10, 0.5, -10)
    ReachLabel.Text = "Reach: " .. val
end

SliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

------------------------------------------------------------
-- BOTÕES
------------------------------------------------------------
local function updateButtonVisual(btn, state)
    if state then
        btn.Text = btn.Text:gsub(": OFF", ": ON")
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 90, 180)
        }):Play()
    else
        btn.Text = btn.Text:gsub(": ON", ": OFF")
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(25, 35, 60)
        }):Play()
    end
end

AutoDiveBtn.MouseButton1Click:Connect(function()
    Config.AutoDive = not Config.AutoDive
    updateButtonVisual(AutoDiveBtn, Config.AutoDive)
end)

AutoCatchBtn.MouseButton1Click:Connect(function()
    Config.AutoCatch = not Config.AutoCatch
    updateButtonVisual(AutoCatchBtn, Config.AutoCatch)
end)

------------------------------------------------------------
-- DETECÇÃO DE BOLA (mais flexível)
------------------------------------------------------------
local function isBall(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    return n:find("ball") or n:find("bola") or n:find("soccer")
        or n:find("football") or obj:FindFirstChild("Ball")
end

local function getBall()
    -- Procura em todo o workspace (recursivo, limitado)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isBall(obj) then
            return obj
        end
    end
    return nil
end

------------------------------------------------------------
-- FUNÇÕES
------------------------------------------------------------
local function autoDive()
    if not Config.AutoDive then return end
    local ball = getBall()
    if not ball then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dir = (ball.Position - hrp.Position)
    if dir.Magnitude > 0 then
        dir = dir.Unit
        hrp.AssemblyLinearVelocity = Vector3.new(
            dir.X * 30,
            hrp.AssemblyLinearVelocity.Y,
            dir.Z * 30
        )
    end
end

local function autoCatch()
    if not Config.AutoCatch then return end
    local ball = getBall()
    if not ball then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (ball.Position - hrp.Position).Magnitude
    if dist <= Config.Reach * 3 then
        ball.CFrame = hrp.CFrame * CFrame.new(0, 1, -2)
        if ball:IsA("BasePart") then
            ball.AssemblyLinearVelocity = Vector3.zero
            ball.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

------------------------------------------------------------
-- LOOP
------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    pcall(function() if Config.AutoDive then autoDive() end end)
    pcall(function() if Config.AutoCatch then autoCatch() end end)
end)

------------------------------------------------------------
-- NOTIFICAÇÃO
------------------------------------------------------------
print("[BLUE Hub] Script carregado com sucesso!")
