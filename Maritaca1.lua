-- ======================================================
-- MARITACA HUB - PARTE 1/2
-- Fluent + Funções
-- ======================================================

print("=== [1/2] CARREGANDO PARTE 1 ===")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
if not Fluent then warn("Fluent falhou") return end

local Window = Fluent:CreateWindow({
    Title = "Maritaca Hub | Futebol",
    SubTitle = "by Maritaca",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 500),
    Theme = "Darker"
})

local Tabs = {
    Reach = Window:AddTab({ Title = "Reach", Icon = "target" }),
    AutoBall = Window:AddTab({ Title = "AutoBall", Icon = "circle" }),
    GK = Window:AddTab({ Title = "GK", Icon = "shield" }),
    SkinBall = Window:AddTab({ Title = "SkinBall", Icon = "disc" })
}

-- Variáveis
local seguindo = false
local reachAtivo = false
local chuteAutomatico = true
local forcaChute = 80
local tamanhoReach = 8
local circulo = nil
local conexaoReach = nil
local conexaoFollow = nil
local tpLoopAtivo = false
local conexaoTPLoop = nil
local autoDiveAtivo = false
local autoCatchAtivo = false
local conexaoAutoDive = nil
local conexaoAutoCatch = nil
local ultimaDefesa = 0
local distanciaDive = 60
local distanciaCatch = 5
local jaAgarrou = false
local tempoAgarrou = 0
local toolManagementCache = nil

local function obterBola()
    local ss = workspace:FindFirstChild("WorkspaceStadiumSounds")
    if ss then
        local tps = ss:FindFirstChild("TPS")
        if tps then
            if tps:IsA("BasePart") then return tps end
            for _, f in ipairs(tps:GetDescendants()) do
                if f:IsA("BasePart") then return f end
            end
        end
    end
    return nil
end

local function obterPosBola()
    local b = obterBola()
    if b then return b.Position end
    return nil
end

local function tocarAnimacao()
    local c = ReplicatedStorage:FindFirstChild("Client")
    if c then c:FireServer("NoobGlitch") end
end

local function obterTM()
    if toolManagementCache then return toolManagementCache end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    local mod = nil
    if bp then mod = bp:FindFirstChild("ToolManagement") end
    if not mod and ch then mod = ch:FindFirstChild("ToolManagement") end
    if mod then
        local ok, r = pcall(function() return require(mod) end)
        if ok and r then toolManagementCache = r return r end
    end
    return nil
end

local function acaoTP()
    local pos = obterPosBola()
    if pos then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

local function iniciarTPLoop()
    if conexaoTPLoop then conexaoTPLoop:Disconnect() end
    conexaoTPLoop = RunService.Heartbeat:Connect(function()
        if not tpLoopAtivo then return end
        local pos = obterPosBola()
        if not pos then return end
        local c = LocalPlayer.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
    end)
end

local function pararTPLoop()
    tpLoopAtivo = false
    if conexaoTPLoop then conexaoTPLoop:Disconnect() conexaoTPLoop = nil end
end

local function ativarFollow(estado)
    seguindo = estado
    if seguindo then
        if conexaoFollow then conexaoFollow:Disconnect() end
        conexaoFollow = RunService.RenderStepped:Connect(function()
            if not seguindo then return end
            local c = LocalPlayer.Character
            if not c then return end
            local hum = c:FindFirstChild("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if not hum or not root then return end
            if hum.MoveDirection.Magnitude > 0.3 then return end
            local pos = obterPosBola()
            if not pos then return end
            local dir = Vector3.new(pos.X - root.Position.X, 0, pos.Z - root.Position.Z)
            if dir.Magnitude < 1.5 then return end
            hum:Move(dir.Unit, false)
            tocarAnimacao()
        end)
    else
        if conexaoFollow then conexaoFollow:Disconnect() conexaoFollow = nil end
    end
end

local function ativarReach(estado)
    reachAtivo = estado
    if reachAtivo then
        if conexaoReach then conexaoReach:Disconnect() end
        local c = LocalPlayer.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            circulo = Instance.new("Part")
            circulo.Name = "ReachVisual"
            circulo.Shape = Enum.PartType.Ball
            circulo.Size = Vector3.new(tamanhoReach*2, tamanhoReach*2, tamanhoReach*2)
            circulo.Anchored = true
            circulo.CanCollide = false
            circulo.CanQuery = false
            circulo.CanTouch = false
            circulo.Material = Enum.Material.SmoothPlastic
            circulo.Color = Color3.fromRGB(0, 255, 150)
            circulo.Transparency = 0.8
            circulo.Parent = workspace
        end
        conexaoReach = RunService.Heartbeat:Connect(function()
            if not circulo or not circulo.Parent then return end
            local ch = LocalPlayer.Character
            if not ch then return end
            local root = ch:FindFirstChild("HumanoidRootPart")
            if not root then return end
            circulo.CFrame = CFrame.new(root.Position)
            local b = obterBola()
            if b then
                local d = (b.Position - root.Position).Magnitude
                if d <= tamanhoReach and chuteAutomatico then
                    local dir = root.CFrame.LookVector
                    b.AssemblyLinearVelocity = Vector3.new(dir.X * forcaChute, 15, dir.Z * forcaChute)
                end
            end
        end)
    else
        if conexaoReach then conexaoReach:Disconnect() conexaoReach = nil end
        if circulo then circulo:Destroy() circulo = nil end
    end
end

local function iniciarAutoDive()
    if conexaoAutoDive then conexaoAutoDive:Disconnect() end
    conexaoAutoDive = RunService.Heartbeat:Connect(function()
        if not autoDiveAtivo then return end
        local agora = tick()
        if agora - ultimaDefesa < 0.8 then return end
        local bola = obterBola()
        if not bola then return end
        local c = LocalPlayer.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChild("Humanoid")
        if not root or not hum then return end
        local dist = (bola.Position - root.Position).Magnitude
        if dist > distanciaDive then return end
        if bola.AssemblyLinearVelocity.Magnitude < 10 then return end
        local rel = root.CFrame:PointToObjectSpace(bola.Position)
        local ladoDireita = rel.X > 0
        local altura = rel.Y
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
        local tm = obterTM()
        if tm then
            pcall(function() tm.SetUsing(true) end)
            pcall(function() tm.Slowdown() end)
        end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        local fL = ladoDireita and 35 or -35
        local fA = (altura > 2) and 25 or 12
        bv.Velocity = (root.CFrame.RightVector * fL) + (root.CFrame.UpVector * fA) + (root.CFrame.LookVector * 10)
        bv.Parent = root
        Debris:AddItem(bv, 0.5)
        if tm then
            pcall(function() tm.ApplyGKForce(bola) end)
            task.delay(0.6, function() pcall(function() tm.Ragdoll() end) end)
        end
        task.delay(1.5, function()
            pcall(function()
                if hum and hum.Parent then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.wait(0.3)
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end)
        ultimaDefesa = agora
    end)
end

local function pararAutoDive()
    if conexaoAutoDive then conexaoAutoDive:Disconnect() conexaoAutoDive = nil end
end

local function iniciarAutoCatch()
    if conexaoAutoCatch then conexaoAutoCatch:Disconnect() end
    jaAgarrou = false
    conexaoAutoCatch = RunService.Heartbeat:Connect(function()
        if not autoCatchAtivo then return end
        local agora = tick()
        if jaAgarrou then
            if agora - tempoAgarrou < 3 then return end
            jaAgarrou = false
        end
        local b = obterBola()
        if not b then return end
        local c = LocalPlayer.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if (b.Position - root.Position).Magnitude < distanciaCatch then
            local tm = obterTM()
            if tm then pcall(function() tm.attachBall(b) end) end
            jaAgarrou = true
            tempoAgarrou = agora
            ultimaDefesa = agora
        end
    end)
end

local function pararAutoCatch()
    if conexaoAutoCatch then conexaoAutoCatch:Disconnect() conexaoAutoCatch = nil end
end

-- Salva tudo pra Parte 2
_G.MaritacaHub = {
    Fluent = Fluent,
    Window = Window,
    Tabs = Tabs,
    LocalPlayer = LocalPlayer,
    acaoTP = acaoTP,
    iniciarTPLoop = iniciarTPLoop,
    pararTPLoop = pararTPLoop,
    ativarFollow = ativarFollow,
    ativarReach = ativarReach,
    iniciarAutoDive = iniciarAutoDive,
    pararAutoDive = pararAutoDive,
    iniciarAutoCatch = iniciarAutoCatch,
    pararAutoCatch = pararAutoCatch,
    setChute = function(v) chuteAutomatico = v end,
    setForca = function(v) forcaChute = v end,
    setTamReach = function(v) tamanhoReach = v; if circulo then circulo.Size = Vector3.new(v*2, v*2, v*2) end end,
    setTpLoop = function(v) tpLoopAtivo = v end,
    setAutoDive = function(v) autoDiveAtivo = v end,
    setAutoCatch = function(v) autoCatchAtivo = v end,
    setDistDive = function(v) distanciaDive = v end,
    setDistCatch = function(v) distanciaCatch = v end,
    getTamReach = function() return tamanhoReach end,
    aplicarTextura = function(id)
        local ss = workspace:FindFirstChild("WorkspaceStadiumSounds")
        if ss then
            local tps = ss:FindFirstChild("TPS")
            if tps then
                for _, f in ipairs(tps:GetDescendants()) do
                    if f:IsA("Texture") or f:IsA("Decal") then
                        f.Texture = "rbxassetid://" .. id
                        return true
                    end
                end
            end
        end
        return false
    end
}

print("=== [1/2] PARTE 1 OK! Execute a PARTE 2 ===")
-- ======================================================
-- MARITACA HUB - PARTE 2/2
-- Interface + Botões
-- ======================================================

print("=== [2/2] CARREGANDO PARTE 2 ===")

local M = _G.MaritacaHub
if not M then warn("Execute a PARTE 1 primeiro!") return end

local Fluent = M.Fluent
local Window = M.Window
local Tabs = M.Tabs
local LocalPlayer = M.LocalPlayer

-- Botão flutuante
local sg = Instance.new("ScreenGui")
sg.Name = "MaritacaFloat"
sg.ResetOnSpawn = false
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 50, 0, 50)
btn.Position = UDim2.new(0.02, 0, 0.2, 0)
btn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
btn.Text = "🪐"
btn.TextSize = 26
btn.Parent = sg

local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(1, 0)
bc.Parent = btn

btn.MouseButton1Click:Connect(function() Window:Minimize() end)

-- ABA REACH
Tabs.Reach:AddSection("Reach")
Tabs.Reach:AddToggle("R1", { Title = "🎯 Reach Ativo", Default = false, Callback = function(v) M.ativarReach(v) end })
Tabs.Reach:AddToggle("R2", { Title = "⚽ Chute Automático", Default = true, Callback = function(v) M.setChute(v) end })
Tabs.Reach:AddButton({ Title = "➕ AUMENTAR (+1)", Callback = function()
    local novo = M.getTamReach() + 1
    if novo <= 15 then M.setTamReach(novo) end
end })
Tabs.Reach:AddButton({ Title = "➖ DIMINUIR (-1)", Callback = function()
    local novo = M.getTamReach() - 1
    if novo >= 1 then M.setTamReach(novo) end
end })
Tabs.Reach:AddSlider("FS", { Title = "💥 Força do Chute", Default = 80, Min = 20, Max = 200, Rounding = 0, Callback = function(v) M.setForca(math.floor(v)) end })

-- ABA AUTOBALL
Tabs.AutoBall:AddSection("⚡ Teleporte")
Tabs.AutoBall:AddButton({ Title = "⚡ TELEPORTAR (1x)", Callback = function() M.acaoTP() end })
Tabs.AutoBall:AddToggle("TL", { Title = "🔁 TP LOOP", Default = false, Callback = function(v)
    M.setTpLoop(v)
    if v then M.iniciarTPLoop() else M.pararTPLoop() end
end })
Tabs.AutoBall:AddSection("🤖 Follow Ball")
Tabs.AutoBall:AddToggle("FT", { Title = "🤖 Follow Ball", Default = false, Callback = function(v) M.ativarFollow(v) end })

-- ABA GK
Tabs.GK:AddSection("🧤 Funções de Goleiro")
Tabs.GK:AddToggle("AD", { Title = "🧤 Auto Dive", Default = false, Callback = function(v)
    M.setAutoDive(v)
    if v then M.iniciarAutoDive() else M.pararAutoDive() end
end })
Tabs.GK:AddToggle("AC", { Title = "🤲 Auto Catch", Default = false, Callback = function(v)
    M.setAutoCatch(v)
    if v then M.iniciarAutoCatch() else M.pararAutoCatch() end
end })
Tabs.GK:AddSlider("DD", { Title = "Distância Dive", Default = 60, Min = 20, Max = 150, Rounding = 0, Callback = function(v) M.setDistDive(math.floor(v)) end })
Tabs.GK:AddSlider("DC", { Title = "Distância Catch", Default = 5, Min = 1, Max = 15, Rounding = 0, Callback = function(v) M.setDistCatch(math.floor(v)) end })

-- ABA SKINBALL
Tabs.SkinBall:AddSection("🎨 Skin")
Tabs.SkinBall:AddButton({ Title = "🟠 CHAMPIONS LARANJA", Callback = function()
    M.aplicarTextura("6631377470")
end })

local idInput = ""
Tabs.SkinBall:AddInput("SI", { Title = "Inserir Textura", Default = "", Placeholder = "Bote o ID...", Numeric = true, Finished = false, Callback = function(v) idInput = v end })
Tabs.SkinBall:AddButton({ Title = "✅ APLICAR", Callback = function()
    if idInput ~= "" then
        local id = tostring(idInput):gsub("rbxassetid://", "")
        M.aplicarTextura(id)
    end
end })
Tabs.SkinBall:AddButton({ Title = "🔄 REMOVER", Callback = function()
    M.aplicarTextura("")
end })

-- NOTIFICAÇÃO
task.spawn(function()
    task.wait(2)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "🪐 Maritaca Hub",
            Text = "Aproveite :)",
            Duration = 5
        })
    end)
end)

Fluent:Notify({ Title = "🪐 Maritaca Hub", Content = "Painel iniciado!", Duration = 4 })
Window:SelectTab(1)

print("=== [2/2] SCRIPT CARREGADO COM SUCESSO! ===")
