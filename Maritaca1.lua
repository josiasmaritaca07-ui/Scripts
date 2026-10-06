-- Maritaca Hub | O clássico futebol
-- by Maritaca

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Config = {
    AutoDive = false,
    AutoCatch = false,
    BF = false,
    ShowCircle = false,
    Reach = 12,
}

-- ==================== PARENT ====================
local parentGui
pcall(function() parentGui = game:GetService("CoreGui") end)
if not parentGui then parentGui = LocalPlayer:WaitForChild("PlayerGui") end

for _, gui in ipairs(parentGui:GetChildren()) do
    if gui.Name == "MaritacaHubUI" then gui:Destroy() end
end

-- ==================== UI PRINCIPAL ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MaritacaHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = parentGui

-- Painel principal (preto, estilo Neon X)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 300)
Main.Position = UDim2.new(0.5, -260, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = Color3.fromRGB(60, 130, 255)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3

-- ==================== CABEÇALHO ====================
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 55)
Header.BackgroundColor3 = Color3.fromRGB(10, 15, 28)
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

-- Título
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -80, 0, 28)
Title.Position = UDim2.new(0, 15, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "Maritaca Hub | O clássico futebol"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Subtítulo "by Maritaca"
local SubTitle = Instance.new("TextLabel", Header)
SubTitle.Size = UDim2.new(1, -80, 0, 18)
SubTitle.Position = UDim2.new(0, 15, 0, 32)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "by Maritaca"
SubTitle.TextColor3 = Color3.fromRGB(120, 170, 255)
SubTitle.TextSize = 13
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Botão minimizar
local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -66, 0, 13)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 7)

-- Botão fechar
local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -33, 0, 13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)

-- ==================== ABA LATERAL ====================
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 130, 1, -65)
Sidebar.Position = UDim2.new(0, 0, 0, 58)
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 18, 32)
Sidebar.BorderSizePixel = 0

local SidebarCorner = Instance.new("UICorner", Sidebar)
SidebarCorner.CornerRadius = UDim.new(0, 10)

-- Botão "Menu" (ativo)
local MenuBtn = Instance.new("TextButton", Sidebar)
MenuBtn.Size = UDim2.new(1, -16, 0, 38)
MenuBtn.Position = UDim2.new(0, 8, 0, 10)
MenuBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 130)
MenuBtn.Text = "⚽  Goleiro"
MenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuBtn.TextSize = 14
MenuBtn.Font = Enum.Font.GothamMedium
MenuBtn.BorderSizePixel = 0
MenuBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", MenuBtn).CornerRadius = UDim.new(0, 8)
local menuStroke = Instance.new("UIStroke", MenuBtn)
menuStroke.Color = Color3.fromRGB(60, 130, 255)
menuStroke.Thickness = 1

-- Linha divisória
local Div = Instance.new("Frame", Sidebar)
Div.Size = UDim2.new(1, -16, 0, 1)
Div.Position = UDim2.new(0, 8, 0, 58)
Div.BackgroundColor3 = Color3.fromRGB(50, 70, 110)
Div.BorderSizePixel = 0

-- Botão "Jogador" (placeholder visual)
local PlayerBtn = Instance.new("TextButton", Sidebar)
PlayerBtn.Size = UDim2.new(1, -16, 0, 38)
PlayerBtn.Position = UDim2.new(0, 8, 0, 70)
PlayerBtn.BackgroundColor3 = Color3.fromRGB(18, 25, 42)
PlayerBtn.Text = "👤  Jogador"
PlayerBtn.TextColor3 = Color3.fromRGB(180, 200, 230)
PlayerBtn.TextSize = 14
PlayerBtn.Font = Enum.Font.GothamMedium
PlayerBtn.BorderSizePixel = 0
PlayerBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", PlayerBtn).CornerRadius = UDim.new(0, 8)

-- Botão "Bola" (placeholder visual)
local BallBtn = Instance.new("TextButton", Sidebar)
BallBtn.Size = UDim2.new(1, -16, 0, 38)
BallBtn.Position = UDim2.new(0, 8, 0, 116)
BallBtn.BackgroundColor3 = Color3.fromRGB(18, 25, 42)
BallBtn.Text = "⚽  Bola"
BallBtn.TextColor3 = Color3.fromRGB(180, 200, 230)
BallBtn.TextSize = 14
BallBtn.Font = Enum.Font.GothamMedium
BallBtn.BorderSizePixel = 0
BallBtn.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", BallBtn).CornerRadius = UDim.new(0, 8)

-- ==================== ÁREA DE CONTEÚDO ====================
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -140, 1, -65)
Content.Position = UDim2.new(0, 138, 0, 58)
Content.BackgroundTransparency = 1

-- Título da seção
local SectionTitle = Instance.new("TextLabel", Content)
SectionTitle.Size = UDim2.new(1, -10, 0, 20)
SectionTitle.Position = UDim2.new(0, 0, 0, 0)
SectionTitle.BackgroundTransparency = 1
SectionTitle.Text = "FUNÇÕES DO GOLEIRO"
SectionTitle.TextColor3 = Color3.fromRGB(100, 170, 255)
SectionTitle.TextSize = 13
SectionTitle.Font = Enum.Font.GothamBold
SectionTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Função de botão toggle (grande, azul)
local function createToggle(name, order, defaultState)
    local btn = Instance.new("TextButton", Content)
    btn.Size = UDim2.new(1, -10, 0, 42)
    btn.Position = UDim2.new(0, 0, 0, 28 + (order - 1) * 50)
    btn.BackgroundColor3 = Color3.fromRGB(20, 35, 65)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220, 235, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamMedium
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(50, 100, 200)
    stroke.Thickness = 1

    -- Indicador ON/OFF à direita
    local indicator = Instance.new("TextLabel", btn)
    indicator.Size = UDim2.new(0, 60, 1, 0)
    indicator.Position = UDim2.new(1, -65, 0, 0)
    indicator.BackgroundTransparency = 1
    indicator.Text = defaultState and "ON" or "OFF"
    indicator.TextColor3 = defaultState and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(150, 150, 150)
    indicator.TextSize = 13
    indicator.Font = Enum.Font.GothamBold

    return btn, indicator, stroke
end

local AutoDiveBtn, AutoDiveInd, AutoDiveStroke = createToggle("🎯  Auto Dive", 1, false)
local AutoCatchBtn, AutoCatchInd, AutoCatchStroke = createToggle("🧤  Auto Catch", 2, false)
local BFBtn, BFInd, BFStroke = createToggle("📏  BF (Reach)", 3, false)
local CircleBtn, CircleInd, CircleStroke = createToggle("⭕  Mostrar Círculo", 4, false)

-- Slider Reach
local ReachLabel = Instance.new("TextLabel", Content)
ReachLabel.Size = UDim2.new(1, -10, 0, 20)
ReachLabel.Position = UDim2.new(0, 0, 0, 240)
ReachLabel.BackgroundTransparency = 1
ReachLabel.Text = "Reach (distância): 12"
ReachLabel.TextColor3 = Color3.fromRGB(180, 200, 230)
ReachLabel.TextSize = 13
ReachLabel.Font = Enum.Font.GothamMedium
ReachLabel.TextXAlignment = Enum.TextXAlignment.Left

local SliderBG = Instance.new("Frame", Content)
SliderBG.Size = UDim2.new(1, -10, 0, 8)
SliderBG.Position = UDim2.new(0, 0, 0, 265)
SliderBG.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
SliderBG.BorderSizePixel = 0
Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(0, 4)

local SliderFill = Instance.new("Frame", SliderBG)
SliderFill.Size = UDim2.new(0.55, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(60, 130, 255)
SliderFill.BorderSizePixel = 0
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 4)

local SliderKnob = Instance.new("Frame", SliderBG)
SliderKnob.Size = UDim2.new(0, 16, 0, 16)
SliderKnob.Position = UDim2.new(0.55, -8, 0.5, -8)
SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderKnob.BorderSizePixel = 0
SliderKnob.ZIndex = 2
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

local isDragging = false
local function updateSlider(x)
    local bgAbs = SliderBG.AbsolutePosition.X
    local bgSize = SliderBG.AbsoluteSize.X
    if bgSize <= 0 then return end
    local rel = math.clamp((x - bgAbs) / bgSize, 0, 1)
    local val = math.floor(rel * 19 + 1)
    Config.Reach = val
    local fill = (val - 1) / 19
    SliderFill.Size = UDim2.new(fill, 0, 1, 0)
    SliderKnob.Position = UDim2.new(fill, -8, 0.5, -8)
    ReachLabel.Text = "Reach (distância): " .. val
end
SliderBG.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        updateSlider(i.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(i.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

-- ==================== BOTÃO FLUTUANTE ====================
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 55, 0, 55)
FloatBtn.Position = UDim2.new(0, 20, 0.5, -27)
FloatBtn.BackgroundColor3 = Color3.fromRGB(10, 15, 28)
FloatBtn.Text = "⚽"
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.TextSize = 26
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.BorderSizePixel = 0
FloatBtn.Visible = false
FloatBtn.Active = true
FloatBtn.Draggable = true
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local floatStroke = Instance.new("UIStroke", FloatBtn)
floatStroke.Color = Color3.fromRGB(60, 130, 255)
floatStroke.Thickness = 2

-- ==================== LIGAÇÕES ====================
local function toggleVisual(indicator, stroke, state)
    if state then
        indicator.Text = "ON"
        indicator.TextColor3 = Color3.fromRGB(80, 220, 120)
        stroke.Color = Color3.fromRGB(80, 200, 120)
    else
        indicator.Text = "OFF"
        indicator.TextColor3 = Color3.fromRGB(150, 150, 150)
        stroke.Color = Color3.fromRGB(50, 100, 200)
    end
end

AutoDiveBtn.MouseButton1Click:Connect(function()
    Config.AutoDive = not Config.AutoDive
    toggleVisual(AutoDiveInd, AutoDiveStroke, Config.AutoDive)
end)
AutoCatchBtn.MouseButton1Click:Connect(function()
    Config.AutoCatch = not Config.AutoCatch
    toggleVisual(AutoCatchInd, AutoCatchStroke, Config.AutoCatch)
end)
BFBtn.MouseButton1Click:Connect(function()
    Config.BF = not Config.BF
    toggleVisual(BFInd, BFStroke, Config.BF)
end)
CircleBtn.MouseButton1Click:Connect(function()
    Config.ShowCircle = not Config.ShowCircle
    toggleVisual(CircleInd, CircleStroke, Config.ShowCircle)
    if not Config.ShowCircle and circlePart and circlePart.Parent then
        circlePart:Destroy()
        circlePart = nil
    end
end)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    FloatBtn.Visible = true
end)
FloatBtn.MouseButton1Click:Connect(function()
    Main.Visible = true
    FloatBtn.Visible = false
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    if circlePart and circlePart.Parent then circlePart:Destroy() end
end)

-- ==================== BOLA ====================
local function getBall()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n == "ball" or n:find("soccerball") or n:find("bola") then
                return obj
            end
        end
    end
    return nil
end

-- ==================== CÍRCULO ====================
local circlePart
local function updateCircle()
    if not Config.ShowCircle then
        if circlePart and circlePart.Parent then
            circlePart:Destroy()
            circlePart = nil
        end
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not circlePart or not circlePart.Parent then
        circlePart = Instance.new("Part")
        circlePart.Name = "MaritacaCircle"
        circlePart.Shape = Enum.PartType.Cylinder
        circlePart.Anchored = true
        circlePart.CanCollide = false
        circlePart.CanQuery = false
        circlePart.CanTouch = false
        circlePart.Material = Enum.Material.Neon
        circlePart.Color = Color3.fromRGB(60, 130, 255)
        circlePart.Transparency = 0.6
        circlePart.Parent = workspace
    end
    local d = Config.Reach * 2
    circlePart.Size = Vector3.new(0.5, d, d)
    circlePart.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
end

-- ==================== AUTO DIVE ====================
local isDiving = false
local diveCooldown = 0

local function autoDive()
    if not Config.AutoDive then return end
    if isDiving then return end
    if tick() - diveCooldown < 1.5 then return end

    local ball = getBall()
    if not ball then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (ball.Position - hrp.Position).Magnitude
    if dist > 30 then return end

    local vel = ball.AssemblyLinearVelocity
    if vel.Magnitude < 5 then return end

    isDiving = true

    local localBall = hrp.CFrame:PointToObjectSpace(ball.Position)
    local dirX = localBall.X < -1 and -1 or (localBall.X > 1 and 1 or 0)
    local dirY = localBall.Y > 0 and 1 or -1

    hrp.AssemblyLinearVelocity = Vector3.new(
        dirX * 25, 35, (ball.Position - hrp.Position).Unit.Z * 15
    )

    task.delay(0.15, function()
        if hrp and hrp.Parent then
            local rot = CFrame.Angles(math.rad(dirY * -60), 0, math.rad(dirX * -75))
            local cf = CFrame.new(hrp.Position) * (hrp.CFrame - hrp.CFrame.Position) * rot
            TweenService:Create(hrp, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {CFrame = cf}):Play()
        end
    end)
    task.delay(0.9, function()
        if hrp and hrp.Parent then
            local cf = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(hrp.Orientation.Y), 0)
            TweenService:Create(hrp, TweenInfo.new(0.3), {CFrame = cf}):Play()
        end
        isDiving = false
    end)
    diveCooldown = tick()
end

-- ==================== AUTO CATCH ====================
local function autoCatch()
    if not Config.AutoCatch then return end
    local ball = getBall()
    if not ball then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (ball.Position - hrp.Position).Magnitude
    local range = Config.BF and Config.Reach or 3
    if dist <= range then
        ball.CFrame = hrp.CFrame * CFrame.new(0, -1, -2.5)
        ball.AssemblyLinearVelocity = Vector3.zero
        ball.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ==================== BF (REACH) ====================
local function applyBF()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not hrp:GetAttribute("MaritacaOrigSize") then
        hrp:SetAttribute("MaritacaOrigSize", hrp.Size)
    end
    local orig = hrp:GetAttribute("MaritacaOrigSize")

    if not Config.BF then
        if hrp.Size ~= orig then hrp.Size = orig end
        return
    end

    local scale = 1 + (Config.Reach / 20)
    local newSize = Vector3.new(orig.X * scale, orig.Y * scale, orig.Z * scale)
    if hrp.Size ~= newSize then hrp.Size = newSize end
end

-- ==================== LOOP ====================
RunService.Heartbeat:Connect(function()
    pcall(function() if Config.AutoDive then autoDive() end end)
    pcall(function() if Config.AutoCatch then autoCatch() end end)
    pcall(applyBF)
    pcall(updateCircle)
end)

LocalPlayer.CharacterAdded:Connect(function()
    if circlePart and circlePart.Parent then circlePart:Destroy() end
    circlePart = nil
    isDiving = false
end)

print("[Maritaca Hub] Carregado - by Maritaca")
