-- ======================================================
-- MARITACA HUB - Futebol Clássico (COMPLETO)
-- Versão: 32.0 - Auto Dive com restauração de estado
-- ======================================================

print("=== [1/5] INICIANDO ===")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

print("=== [2/5] CARREGANDO FLUENT ===")

local Fluent
local sucesso = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not sucesso or not Fluent then
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()
    end)
end

if not Fluent then
    warn("❌ NÃO FOI POSSÍVEL CARREGAR O FLUENT.")
    return
end

print("=== [3/5] FLUENT CARREGADO ===")

local Window = Fluent:CreateWindow({
    Title = "Maritaca Hub | Futebol Clássico",
    SubTitle = "by Maritaca",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 500),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Reach = Window:AddTab({ Title = "Reach", Icon = "target" }),
    AutoBall = Window:AddTab({ Title = "AutoBall", Icon = "circle" }),
    GK = Window:AddTab({ Title = "GK", Icon = "shield" }),
    FPS = Window:AddTab({ Title = "FPS", Icon = "monitor" }),
    SkinBall = Window:AddTab({ Title = "SkinBall", Icon = "disc" }),
    Opcoes = Window:AddTab({ Title = "Configurações", Icon = "settings" })
}

print("=== [4/5] ABAS CRIADAS ===")

-- ==================== VARIÁVEIS ====================
local seguindo = false
local followPausado = false
local tempoParado = 0
local reachAtivo = false
local circuloVisivel = true
local chuteAutomatico = true
local forcaChute = 80
local tamanhoReach = 8
local circulo = nil
local conexaoReach = nil
local conexaoFollow = nil
local fpsAtivo = false
local tpLoopAtivo = false
local conexaoTPLoop = nil
local idTexturaPersonalizado = ""
local autoDiveAtivo = false
local autoCatchAtivo = false
local conexaoAutoDive = nil
local conexaoAutoCatch = nil
local ultimaDefesa = 0
local distanciaDive = 60
local distanciaCatch = 5
local jaAgarrou = false
local tempoAgarrou = 0
local TEXTURA_CHAMPIONS = 6631377470
local screenGui = nil
local fechado = false
local toolManagementCache = nil
local estadoOriginalSalvo = nil

-- ==================== FECHAR ====================
local function fecharScript()
    if fechado then return end
    fechado = true
    print("=== FECHANDO ===")
    if conexaoReach then pcall(function() conexaoReach:Disconnect() end) end
    if conexaoFollow then pcall(function() conexaoFollow:Disconnect() end) end
    if conexaoTPLoop then pcall(function() conexaoTPLoop:Disconnect() end) end
    if conexaoAutoDive then pcall(function() conexaoAutoDive:Disconnect() end) end
    if conexaoAutoCatch then pcall(function() conexaoAutoCatch:Disconnect() end) end
    if circulo then pcall(function() circulo:Destroy() end) end
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "ReachVisual" then obj:Destroy() end
        end
    end)
    if humanoid then
        pcall(function() humanoid:Move(Vector3.new(0,0,0), false) end)
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    if screenGui and screenGui.Parent then pcall(function() screenGui:Destroy() end) end
    pcall(function() Window:Destroy() end)
    seguindo = false
    reachAtivo = false
    tpLoopAtivo = false
    followPausado = false
    print("=== FECHADO ===")
end

-- ==================== PEGAR BOLA ====================
local function obterBolaOficial()
    local ss = workspace:FindFirstChild("WorkspaceStadiumSounds")
    if ss then
        local tps = ss:FindFirstChild("TPS")
        if tps then
            if tps:IsA("BasePart") then return tps end
            if tps:IsA("Model") then
                if tps.PrimaryPart then return tps.PrimaryPart end
                for _, f in ipairs(tps:GetDescendants()) do
                    if f:IsA("BasePart") then return f end
                end
            end
            for _, f in ipairs(tps:GetDescendants()) do
                if f:IsA("BasePart") then return f end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        local rm = obj:FindFirstChild("RealMatch")
        if rm and (rm.Value == true or rm.Value == 1) then
            if obj:IsA("BasePart") then return obj
            elseif obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            local t = obj.Size.Magnitude
            if t > 0.5 and t < 5 then
                if n == "tps" or n == "pb" or n == "ball" or n == "bola" or n == "soccerball" or n == "football" then
                    return obj
                end
            end
        end
    end
    return nil
end

local function obterPosBola()
    local b = obterBolaOficial()
    if b then return b.Position end
    return nil
end

local function tocarAnimacao()
    local c = ReplicatedStorage:FindFirstChild("Client")
    if c then c:FireServer("NoobGlitch") end
end

-- ==================== TOOLMANAGEMENT ====================
local function obterToolManagement()
    if toolManagementCache then return toolManagementCache end
    local player = game:GetService("Players").LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    local modulo = nil
    if backpack then modulo = backpack:FindFirstChild("ToolManagement") end
    if not modulo and char then modulo = char:FindFirstChild("ToolManagement") end
    if modulo then
        local ok, resultado = pcall(function() return require(modulo) end)
        if ok and resultado then
            toolManagementCache = resultado
            print("✅ ToolManagement carregado!")
            return resultado
        end
    end
    return nil
end

-- ==================== APLICAR TEXTURA ====================
local function aplicarTexturaBola(id)
    local aplicado = false
    local ss = workspace:FindFirstChild("WorkspaceStadiumSounds")
    if ss then
        local tps = ss:FindFirstChild("TPS")
        if tps then
            if tps:IsA("BasePart") and tps:FindFirstChild("Texture") then
                local tex = tps:FindFirstChild("Texture")
                if tex:IsA("Decal") or tex:IsA("Texture") then
                    tex.Texture = "rbxassetid://" .. id
                    aplicado = true
                end
            end
            if not aplicado and (tps:IsA("Decal") or tps:IsA("Texture")) then
                tps.Texture = "rbxassetid://" .. id
                aplicado = true
            end
            if not aplicado then
                for _, f in ipairs(tps:GetDescendants()) do
                    if f:IsA("Texture") or f:IsA("Decal") then
                        f.Texture = "rbxassetid://" .. id
                        aplicado = true
                        break
                    end
                end
            end
        end
    end
    if not aplicado then
        local b = obterBolaOficial()
        if b then
            if b:IsA("MeshPart") then
                b.TextureID = "rbxassetid://" .. id
                aplicado = true
            else
                local mesh = b:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    mesh.TextureId = "rbxassetid://" .. id
                    aplicado = true
                end
            end
        end
    end
    return aplicado
end

-- ==================== TP ====================
local function acaoTP()
    local pos = obterPosBola()
    if pos then
        humanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        Fluent:Notify({ Title = "⚡ TP", Content = "Teleportado!", Duration = 2 })
    else
        Fluent:Notify({ Title = "❌ Erro", Content = "Bola não encontrada.", Duration = 3 })
    end
end

-- ==================== TP LOOP ====================
local function iniciarTPLoop()
    if conexaoTPLoop then conexaoTPLoop:Disconnect() end
    conexaoTPLoop = RunService.Heartbeat:Connect(function()
        if not tpLoopAtivo then return end
        local pos = obterPosBola()
        if not pos then return end
        local c = LocalPlayer.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root then return end
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end)
    Fluent:Notify({ Title = "🔁 TP Loop", Content = "ATIVADO!", Duration = 2 })
end

local function pararTPLoop()
    tpLoopAtivo = false
    if conexaoTPLoop then conexaoTPLoop:Disconnect() conexaoTPLoop = nil end
    Fluent:Notify({ Title = "🔁 TP Loop", Content = "Desativado.", Duration = 2 })
end

-- ==================== FOLLOW ====================
local function ativarFollow(estado)
    seguindo = estado
    followPausado = false
    tempoParado = 0
    if seguindo then
        if conexaoFollow then conexaoFollow:Disconnect() end
        conexaoFollow = RunService.RenderStepped:Connect(function(dt)
            if not seguindo then return end
            local c = LocalPlayer.Character
            if not c then return end
            local hum = c:FindFirstChild("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if not hum or not root then return end
            if hum.MoveDirection.Magnitude > 0.3 then
                followPausado = true
                tempoParado = 0
                return
            end
            if followPausado then
                tempoParado = tempoParado + dt
                if tempoParado >= 0.5 then followPausado = false else return end
            end
            local pos = obterPosBola()
            if not pos then return end
            local dir = Vector3.new(pos.X - root.Position.X, 0, pos.Z - root.Position.Z)
            if dir.Magnitude < 1.5 then return end
            hum:Move(dir.Unit, false)
            tocarAnimacao()
        end)
        Fluent:Notify({ Title = "🤖 Follow", Content = "Ativado!", Duration = 2 })
    else
        if conexaoFollow then conexaoFollow:Disconnect() conexaoFollow = nil end
        local c = LocalPlayer.Character
        if c then
            local hum = c:FindFirstChild("Humanoid")
            local root = c:FindFirstChild("HumanoidRootPart")
            if hum and root then pcall(function() hum:MoveTo(root.Position) end) end
        end
        Fluent:Notify({ Title = "🛑 Follow", Content = "Desativado.", Duration = 2 })
    end
end

-- ==================== REACH ====================
local function limparReach()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "ReachVisual" then obj:Destroy() end
    end
end

local function criarCirculo()
    limparReach()
    if conexaoReach then conexaoReach:Disconnect() conexaoReach = nil end
    local c = LocalPlayer.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    local posIni = hrp and hrp.Position or Vector3.new(0,0,0)
    circulo = Instance.new("Part")
    circulo.Name = "ReachVisual"
    circulo.Shape = Enum.PartType.Ball
    circulo.Size = Vector3.new(tamanhoReach*2, tamanhoReach*2, tamanhoReach*2)
    circulo.CFrame = CFrame.new(posIni)
    circulo.Anchored = true
    circulo.CanCollide = false
    circulo.CanQuery = false
    circulo.CanTouch = false
    circulo.Material = Enum.Material.SmoothPlastic
    circulo.Color = Color3.fromRGB(0, 255, 150)
    circulo.Transparency = 0.8
    circulo.Parent = workspace
    conexaoReach = RunService.Heartbeat:Connect(function()
        if not circulo or not circulo.Parent then return end
        local ch = LocalPlayer.Character
        if not ch then return end
        local root = ch:FindFirstChild("HumanoidRootPart")
        if not root then return end
        circulo.CFrame = CFrame.new(root.Position)
        circulo.Transparency = circuloVisivel and 0.8 or 1
        local b = obterBolaOficial()
        if b then
            local d = (b.Position - root.Position).Magnitude
            if d <= tamanhoReach and chuteAutomatico then
                local dir = root.CFrame.LookVector
                b.AssemblyLinearVelocity = Vector3.new(dir.X * forcaChute, 15, dir.Z * forcaChute)
            end
        end
    end)
end

local function ativarReach(estado)
    reachAtivo = estado
    if reachAtivo then
        criarCirculo()
        Fluent:Notify({ Title = "🎯 Reach", Content = "Ativado! (" .. tamanhoReach .. ")", Duration = 2 })
    else
        if conexaoReach then conexaoReach:Disconnect() conexaoReach = nil end
        if circulo then circulo:Destroy() circulo = nil end
        limparReach()
        Fluent:Notify({ Title = "🎯 Reach", Content = "Desativado.", Duration = 2 })
    end
end

-- ==================== GK - AUTO DIVE (COM RESTAURAÇÃO DE ESTADO) ====================
local function iniciarAutoDive()
    if conexaoAutoDive then conexaoAutoDive:Disconnect() end
    conexaoAutoDive = RunService.Heartbeat:Connect(function()
        if not autoDiveAtivo then return end
        
        local agora = tick()
        if agora - ultimaDefesa < 0.8 then return end
        
        local bola = obterBolaOficial()
        if not bola then return end
        
        local c = LocalPlayer.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChild("Humanoid")
        if not root or not hum then return end
        
        -- 1️⃣ DISTÂNCIA
        local dist = (bola.Position - root.Position).Magnitude
        if dist > distanciaDive then return end
        
        -- 2️⃣ VELOCIDADE
        local velocidadeBola = bola.AssemblyLinearVelocity
        if velocidadeBola.Magnitude < 10 then return end
        
        -- 3️⃣ DIREÇÃO
        local direcaoBola = velocidadeBola.Unit
        local paraGoleiro = (root.Position - bola.Position).Unit
        local dotProduto = direcaoBola:Dot(paraGoleiro)
        if dotProduto < 0.3 then return end
        
        -- 4️⃣ POSIÇÃO RELATIVA
        local bolaRelativa = root.CFrame:PointToObjectSpace(bola.Position)
        local ladoDireita = bolaRelativa.X > 0
        local altura = bolaRelativa.Y
        
        -- 5️⃣ SALVA O ESTADO ORIGINAL E MUDA PRA PHYSICS
        local estadoOriginal = hum:GetState()
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
        
        -- 6️⃣ TOOLMANAGEMENT
        local tm = obterToolManagement()
        if tm then
            pcall(function() tm.SetUsing(true) end)
            pcall(function() tm.Slowdown() end)
            local torso = c:FindFirstChild("Torso")
            if torso then
                pcall(function() torso.AssemblyAngularVelocity = Vector3.new() end)
            end
        end
        
        -- 7️⃣ ANIMAÇÃO
        local animAnimations = ReplicatedStorage:FindFirstChild("Animations")
        local gkAnim = animAnimations and animAnimations:FindFirstChild("GK")
        local dives = gkAnim and gkAnim:FindFirstChild("Dives")
        
        local animacao = nil
        if dives then
            if altura > 2 then
                animacao = ladoDireita and dives:FindFirstChild("HighDive_R") or dives:FindFirstChild("HighDive_L")
                if not animacao then
                    animacao = dives:FindFirstChild("HighDive_L") or dives:FindFirstChild("HighDive_R")
                end
            elseif altura < 0.5 then
                animacao = ladoDireita and dives:FindFirstChild("LowDive_R") or dives:FindFirstChild("LowDive_L")
                if not animacao then
                    animacao = dives:FindFirstChild("MidDive_L") or dives:FindFirstChild("MidDive_R")
                end
            else
                animacao = ladoDireita and dives:FindFirstChild("MidDive_R") or dives:FindFirstChild("MidDive_L")
            end
            
            if animacao then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    local track = animator:LoadAnimation(animacao)
                    track.Priority = Enum.AnimationPriority.Action4
                    pcall(function() track:Play() end)
                    print("🎬 Animação: " .. animacao.Name)
                end
            end
        end
        
        -- 8️⃣ BODYVELOCITY COM FORÇA REAL
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        local forcaLateral = ladoDireita and 35 or -35
        local forcaAltura = (altura > 2) and 25 or 12
        bodyVelocity.Velocity = (root.CFrame.RightVector * forcaLateral) 
                              + (root.CFrame.UpVector * forcaAltura) 
                              + (root.CFrame.LookVector * 10)
        bodyVelocity.Parent = root
        Debris:AddItem(bodyVelocity, 0.5)
        
        -- 9️⃣ APLICA FORÇA NA BOLA E RAGDOLL
        if tm then
            pcall(function() tm.ApplyGKForce(bola) end)
            task.delay(0.6, function()
                pcall(function() tm.Ragdoll() end)
            end)
        end
        
        -- 🔟 RESTAURA O ESTADO (evita trava permanente)
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
        print("🧤 Auto Dive! Lado: " .. (ladoDireita and "Direita" or "Esquerda") .. " | Altura: " .. string.format("%.1f", altura))
    end)
end

local function pararAutoDive()
    if conexaoAutoDive then conexaoAutoDive:Disconnect() conexaoAutoDive = nil end
end

-- ==================== GK - AUTO CATCH (PEGA SÓ UMA VEZ) ====================
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
        
        if agora - ultimaDefesa < 0.3 then return end
        
        local b = obterBolaOficial()
        if not b then return end
        
        local c = LocalPlayer.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local d = (b.Position - root.Position).Magnitude
        
        if d < distanciaCatch then
            local tm = obterToolManagement()
            local sucesso = false
            
            if tm then
                pcall(function() tm.attachBall(b) end)
                sucesso = true
                print("🤲 Auto Catch! (ToolManagement.attachBall)")
            else
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local long = backpack:FindFirstChild("Long")
                    if long then
                        local gk = long:Find
