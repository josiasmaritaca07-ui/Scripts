-- ======================================================
-- MARITACA HUB - Futebol Clássico (COMPLETO)
-- Versão: 58.0 - Logo limpa + centralizada
-- ======================================================

print("=== [1/5] INICIANDO ===")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("=== [2/5] CARREGANDO FLUENT ===")

local Fluent
local ok = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not ok or not Fluent then
    warn("❌ Fluent não carregou.")
    return
end

print("=== [3/5] CRIANDO INTERFACE ===")

local Window = Fluent:CreateWindow({
    Title = "Maritaca Hub",
    SubTitle = "Futebol Clássico v58.0",
    TabWidth = 150,
    Size = UDim2.fromOffset(560, 460),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Principal = Window:AddTab({ Title = "Principal",      Icon = "home" }),
    Balls     = Window:AddTab({ Title = "Balls",          Icon = "circle" }),
    GK        = Window:AddTab({ Title = "GK",             Icon = "shield" }),
    Hitbox    = Window:AddTab({ Title = "Hitbox",         Icon = "box" }),
    Grafico   = Window:AddTab({ Title = "Gráfico",        Icon = "image" }),
    Char      = Window:AddTab({ Title = "Char",           Icon = "user" }),
    Opcoes    = Window:AddTab({ Title = "Configurações",  Icon = "settings" })
}

-- ==================== VARIÁVEIS ====================
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- REACH
local reachAtivo = false
local reachTamanho = 3.5
local reachHitbox = nil
local mostrarHitboxReach = true
local conexaoReach = nil
local reachSliderRef = nil

-- OUTROS
local hitboxAtivo = false
local tamanhoHitbox = 12
local quadradoVisivel = true
local hitboxVisual = nil
local conexaoHitbox = nil

local autoDiveAtivo = false
local autoCatchAtivo = false
local distanciaDive = 24
local distanciaCatch = 8
local cooldownDive = 0.85
local forcaDiveMin = 30
local forcaDiveMax = 52
local jumpMinimo = 50
local mostrarHitboxGK = false
local hitboxGK = nil
local ultimaDefesa = -1e9
local conexaoAutoDive, conexaoAutoCatch

local tpLoopAtivo = false
local seguindo = false
local followPausado = false
local tempoParado = 0
local conexaoTPLoop, conexaoFollow

local fpsAtivo = false
local fechado = false
local textureIDAtual = ""
local meshIDAtual = ""
local bolaBrancaAtiva = false
local dadosOriginais = {}
local conexaoSkin

-- ==================== BOLA FLUTUANTE 🦜 ====================
local LOGO_ID = "rbxassetid://14998339954"

local floatingGui = Instance.new("ScreenGui")
floatingGui.Name = "MaritacaFloating"
floatingGui.ResetOnSpawn = false
floatingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
floatingGui.Parent = PlayerGui

local floatingBtn = Instance.new("ImageButton")
floatingBtn.Name = "FloatingBall"
floatingBtn.Size = UDim2.new(0, 55, 0, 55)
floatingBtn.Position = UDim2.new(0.03, 0, 0.5, -27)
floatingBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
floatingBtn.BackgroundTransparency = 1
floatingBtn.Image = LOGO_ID
floatingBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
floatingBtn.BorderSizePixel = 0
floatingBtn.AutoButtonColor = false
floatingBtn.Active = true
floatingBtn.ZIndex = 999
floatingBtn.Parent = floatingGui

local fcorner = Instance.new("UICorner")
fcorner.CornerRadius = UDim.new(1, 0)
fcorner.Parent = floatingBtn

local dragging, dragStart, startPos
floatingBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = floatingBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        floatingBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

floatingBtn.MouseButton1Click:Connect(function() Window:Minimize() end)

-- ==================== PEGAR BOLA ====================
local function obterBolaOficial()
    local ss = workspace:FindFirstChild("WorkspaceStadiumSounds")
    if ss then
        local tps = ss:FindFirstChild("TPS")
        if tps then
            if tps:IsA("BasePart") then return tps end
            if tps:IsA("Model") and tps.PrimaryPart then return tps.PrimaryPart end
            for _, f in ipairs(tps:GetDescendants()) do
                if f:IsA("BasePart") then return f end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n == "tps" or n == "pb" or n == "ball" or n == "bola" then
                return obj
            end
        end
    end
    return nil
end

local function tocarAnimacao()
    local c = ReplicatedStorage:FindFirstChild("Client")
    if c then c:FireServer("NoobGlitch") end
end

-- =====================================================================
-- 🎯 REACH (ESFERA/CÍRCULO)
-- =====================================================================
local function acharBolaReach()
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local maisPerto, menorDist = nil, math.huge
    local vector4 = Vector3.new(0, -28.94, 0)
    local raioIgnorar = 3.5

    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name == "TPS" or v.Name:lower():find("ball") or v.Name:lower():find("bola")) then
            local size = v.Size
            if size.X >= 0.8 and size.X <= 5 and not ((v.Position - vector4).Magnitude <= raioIgnorar) then
                local d = (v.Position - hrp.Position).Magnitude
                if d < menorDist then
                    menorDist = d
                    maisPerto = v
                end
            end
        end
    end
    return maisPerto
end

local function destruirHitboxReach()
    if reachHitbox then
        reachHitbox:Destroy()
        reachHitbox = nil
    end
end

local function atualizarHitboxReach()
    if not reachAtivo then
        destruirHitboxReach()
        return
    end

    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then
        destruirHitboxReach()
        return
    end

    if not reachHitbox or not reachHitbox.Parent then
        destruirHitboxReach()

        reachHitbox = Instance.new("Part")
        reachHitbox.Name = "MaritacaReachHitbox"
        reachHitbox.Shape = Enum.PartType.Ball
        reachHitbox.Material = Enum.Material.ForceField
        reachHitbox.Color = Color3.fromRGB(255, 45, 70)
        reachHitbox.Transparency = mostrarHitboxReach and 0.85 or 1
        reachHitbox.CanCollide = false
        reachHitbox.CanTouch = false
        reachHitbox.CanQuery = false
        reachHitbox.Massless = true
        reachHitbox.CastShadow = false

        local weld = Instance.new("Weld")
        weld.Name = "MaritacaReachWeld"
        weld.Part0 = hrp
        weld.Part1 = reachHitbox
        weld.Parent = reachHitbox

        reachHitbox.Parent = ch
    end

    local size = reachTamanho * 4.2
    reachHitbox.Size = Vector3.new(size, size, size)
    reachHitbox.CFrame = hrp.CFrame
    reachHitbox.Transparency = mostrarHitboxReach and 0.85 or 1
end

local function aplicarReach(bola)
    if not reachAtivo or not bola then return end

    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not firetouchinterest then return end

    if (bola.Position - hrp.Position).Magnitude > reachTamanho * 4.2 then return end

    firetouchinterest(hrp, bola, 0)
    firetouchinterest(hrp, bola, 1)

    if reachHitbox and reachHitbox.Parent then
        firetouchinterest(reachHitbox, bola, 0)
        firetouchinterest(reachHitbox, bola, 1)
    end

    local leftFoot = ch:FindFirstChild("Left Foot") or ch:FindFirstChild("Left Leg")
    local rightFoot = ch:FindFirstChild("Right Foot") or ch:FindFirstChild("Right Leg")

    if leftFoot then
        firetouchinterest(leftFoot, bola, 0)
        firetouchinterest(leftFoot, bola, 1)
    end
    if rightFoot then
        firetouchinterest(rightFoot, bola, 0)
        firetouchinterest(rightFoot, bola, 1)
    end
end

local function iniciarReach()
    if conexaoReach then conexaoReach:Disconnect() end
    conexaoReach = RunService.RenderStepped:Connect(function()
        if not reachAtivo or fechado then return end
        atualizarHitboxReach()
        local bola = acharBolaReach()
        if bola then
            aplicarReach(bola)
        end
    end)
end

local function pararReach()
    reachAtivo = false
    if conexaoReach then conexaoReach:Disconnect() conexaoReach = nil end
    destruirHitboxReach()
end

-- =====================================================================
-- BALLS - SKINS
-- =====================================================================
local function GetBalls()
    local balls = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if name == "football" or name == "ball" or name == "soccerball"
            or name == "tps" or name == "hitbox" or name == "bola"
            or string.find(name, "tcs") then
                table.insert(balls, obj)
            end
        end
    end
    return balls
end

local function FormatID(id)
    if not id or id == "" then return "" end
    local cleanId = string.match(id, "%d+")
    return cleanId and ("rbxassetid://" .. cleanId) or id
end

local function aplicarSkins()
    if conexaoSkin then conexaoSkin:Disconnect() end
    conexaoSkin = RunService.Heartbeat:Connect(function()
        local lista = GetBalls()
        if #lista == 0 then return end
        local tex = FormatID(textureIDAtual)
        local mesh = FormatID(meshIDAtual)
        for _, b in pairs(lista) do
            pcall(function()
                if not dadosOriginais[b] then
                    local decalMap = {}
                    for _, c in pairs(b:GetChildren()) do
                        if c:IsA("Decal") or c:IsA("Texture") then
                            decalMap[c] = c.Texture
                        end
                    end
                    dadosOriginais[b] = {
                        Color = b.Color, Material = b.Material,
                        TextureID = b:IsA("MeshPart") and b.TextureID or "",
                        MeshId = b:IsA("MeshPart") and b.MeshId or "",
                        SpecialMeshId = b:FindFirstChildOfClass("SpecialMesh") and b:FindFirstChildOfClass("SpecialMesh").MeshId or "",
                        SpecialMeshTexture = b:FindFirstChildOfClass("SpecialMesh") and b:FindFirstChildOfClass("SpecialMesh").TextureId or "",
                        Decals = decalMap,
                    }
                end
                local meshObj = b:FindFirstChildOfClass("SpecialMesh")
                if mesh ~= "" then
                    if b:IsA("MeshPart") then
                        if b.MeshId ~= mesh then b.MeshId = mesh end
                    else
                        if not meshObj then meshObj = Instance.new("SpecialMesh", b) end
                        if meshObj.MeshId ~= mesh then
                            meshObj.MeshType = Enum.MeshType.FileMesh
                            meshObj.MeshId = mesh
                        end
                    end
                end
                if tex ~= "" then
                    if b:IsA("MeshPart") then
                        if b.TextureID ~= tex then b.TextureID = tex end
                    end
                    if meshObj then
                        if meshObj.TextureId ~= tex then meshObj.TextureId = tex end
                    end
                    for _, c in pairs(b:GetChildren()) do
                        if c:IsA("Decal") or c:IsA("Texture") then
                            if c.Texture ~= tex then c.Texture = tex end
                        end
                    end
                end
                if bolaBrancaAtiva then
                    b.Color = Color3.fromRGB(255, 255, 255)
                    b.Material = Enum.Material.SmoothPlastic
                    for _, child in pairs(b:GetChildren()) do
                        if child:IsA("SurfaceAppearance") then child.Enabled = false end
                    end
                    if tex == "" then
                        if b:IsA("MeshPart") then b.TextureID = "" end
                        if meshObj then meshObj.TextureId = "" end
                        for _, c in pairs(b:GetChildren()) do
                            if c:IsA("Decal") or c:IsA("Texture") then c.Transparency = 1 end
                        end
                    end
                else
                    if dadosOriginais[b] then
                        if b.Color ~= dadosOriginais[b].Color then b.Color = dadosOriginais[b].Color end
                        if b.Material ~= dadosOriginais[b].Material then b.Material = dadosOriginais[b].Material end
                        for _, child in pairs(b:GetChildren()) do
                            if child:IsA("SurfaceAppearance") then
                                child.Enabled = true
                            elseif child:IsA("Decal") or child:IsA("Texture") then
                                child.Transparency = 0
                                if tex == "" then
                                    child.Texture = dadosOriginais[b].Decals[child] or child.Texture
                                end
                            end
                        end
                        if tex == "" then
                            if b:IsA("MeshPart") then b.TextureID = dadosOriginais[b].TextureID end
                            if meshObj then meshObj.TextureId = dadosOriginais[b].SpecialMeshTexture end
                        end
                    end
                end
            end)
        end
    end)
end

local function removerTextura()
    textureIDAtual = ""
    for _, b in pairs(GetBalls()) do
        pcall(function()
            local orig = dadosOriginais[b]
            if orig then
                if b:IsA("MeshPart") then b.TextureID = orig.TextureID end
                local meshObj = b:FindFirstChildOfClass("SpecialMesh")
                if meshObj then meshObj.TextureId = orig.SpecialMeshTexture end
                for _, c in pairs(b:GetChildren()) do
                    if c:IsA("Decal") or c:IsA("Texture") then
                        c.Texture = orig.Decals[c] or c.Texture
                        c.Transparency = 0
                    end
                end
            end
        end)
    end
end

local function removerMesh()
    meshIDAtual = ""
    for _, b in pairs(GetBalls()) do
        pcall(function()
            local orig = dadosOriginais[b]
            if orig then
                if b:IsA("MeshPart") and orig.MeshId ~= "" then b.MeshId = orig.MeshId end
                local meshObj = b:FindFirstChildOfClass("SpecialMesh")
                if meshObj and orig.SpecialMeshId ~= "" then meshObj.MeshId = orig.SpecialMeshId end
            end
        end)
    end
end

-- =====================================================================
-- AUTO DIVE
-- =====================================================================
local gkContainer, gkBtnCache = nil, {}
local function norm(s) return (s:lower():gsub("%s+", "")) end

local function findChildCI(parent, name)
    name = name:lower()
    for _, c in ipairs(parent:GetChildren()) do
        if c.Name:lower() == name then return c end
    end
    return nil
end

local function findGKContainer()
    local cur = PlayerGui
    for _, n in ipairs({ "start", "imagelabel" }) do
        cur = cur and findChildCI(cur, n)
        if not cur then return nil end
    end
    return cur
end

local function getGKButton(name)
    local b = gkBtnCache[name]
    if b and b.Parent then return b end
    if not (gkContainer and gkContainer.Parent) then gkContainer = findGKContainer() end
    local want = norm(name)
    local function search(root)
        if not root then return nil end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("GuiObject") and norm(d.Name) == want then return d end
        end
    end
    b = (gkContainer and search(gkContainer)) or search(PlayerGui)
    gkBtnCache[name] = b
    return b
end

local function pressGK(name)
    local b = getGKButton(name)
    if not b then return false end
    local fired = false
    pcall(function() firesignal(b.Activated); fired = true end)
    if not fired then pcall(function() firesignal(b.MouseButton1Click); fired = true end) end
    if not fired then pcall(function() firesignal(b.MouseButton1Down); fired = true end) end
    return fired
end

local catchRemote
local function obterCatchBallRemote()
    if catchRemote and catchRemote.Parent then return catchRemote end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d.Name:lower() == "catchball" and d:IsA("RemoteEvent") then
            catchRemote = d
            return d
        end
    end
end

local function tentarCatch(bola)
    if not bola then return end
    local ch = LocalPlayer.Character
    if not ch then return end
    pcall(function() bola:SetNetworkOwner(LocalPlayer) end)
    for _, p in ipairs(ch:GetChildren()) do
        if p:IsA("BasePart") and p.Parent then
            pcall(function()
                firetouchinterest(p, bola, 0)
                firetouchinterest(p, bola, 1)
            end)
        end
    end
    pcall(function()
        local ev = obterCatchBallRemote()
        if ev then ev:FireServer(bola) end
    end)
end

local function atualizarHitboxGK()
    if not mostrarHitboxGK then
        if hitboxGK then hitboxGK.Transparency = 1 end
        return
    end
    if not hitboxGK or not hitboxGK.Parent then
        hitboxGK = Instance.new("Part")
        hitboxGK.Name = "MariGkHitbox"
        hitboxGK.Shape = Enum.PartType.Ball
        hitboxGK.Size = Vector3.new(36, 36, 36)
        hitboxGK.Transparency = 0.88
        hitboxGK.Material = Enum.Material.ForceField
        hitboxGK.Color = Color3.fromRGB(170, 70, 255)
        hitboxGK.Anchored = true
        hitboxGK.CanCollide = false
        hitboxGK.CanTouch = false
        hitboxGK.CanQuery = false
        hitboxGK.CastShadow = false
        hitboxGK.Parent = workspace
    end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        hitboxGK.Size = Vector3.new(36, 36, 36)
        hitboxGK.CFrame = root.CFrame
        hitboxGK.Transparency = 0.88
    end
end

local function iniciarAutoDive()
    if conexaoAutoDive then conexaoAutoDive:Disconnect() end
    conexaoAutoDive = RunService.Heartbeat:Connect(function()
        if not autoDiveAtivo or fechado then return end
        local agora = os.clock()
        if agora - ultimaDefesa < cooldownDive
                            return
        end

        local bola = obterBola()
        if not bola then return end
        local ch = LocalPlayer.Character
        if not ch then return end
        local root = ch:FindFirstChild("HumanoidRootPart")
        local hum = ch:FindFirstChild("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end

        local dist = (bola.Position - root.Position).Magnitude
        if dist > distanciaDive then return end

        local vel = bola.AssemblyLinearVelocity
        local vh = Vector3.new(vel.X, 0, vel.Z).Magnitude
        if vh < 3 then return end

        local dirJ = root.Position - bola.Position
        if vel:Dot(dirJ.Unit) < -2 then return end

        local pt = vh >= 100 and 0.05 or 0.13
        local g = workspace.Gravity
        if g <= 0 then g = 196.2 end
        local prev = bola.Position + vel * pt + Vector3.new(0, -0.5 * g * pt * pt, 0)

        local ox = (prev - root.Position):Dot(root.CFrame.RightVector)
        local oy = prev.Y - root.Position.Y
        if math.abs(ox) > 18 then return end

        pcall(function() root:SetNetworkOwner(LocalPlayer) end)

        local dir
        if oy >= 2.5 then dir = "R"
        elseif oy <= -2 then
            if ox < -2 then dir = "Z"
            elseif ox > 2 then dir = "C"
            else dir = "F" end
        elseif math.abs(ox) <= 1.5 then dir = "F"
        elseif ox < -2 then dir = "Q"
        elseif ox > 2 then dir = "E"
        else dir = "F" end

        if oy >= 1.8 and oy <= 4.3 then
            ultimaDefesa = agora
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            pcall(function()
                hum.Jump = true
                root.AssemblyLinearVelocity = Vector3.new(
                    root.AssemblyLinearVelocity.X,
                    math.max(root.AssemblyLinearVelocity.Y, jumpMinimo),
                    root.AssemblyLinearVelocity.Z
                )
            end)
            return
        end

        local dp = (prev - root.Position).Magnitude
        if dp <= 4 and dir == "F" then
            ultimaDefesa = agora
            tentarCatch(bola)
            return
        end

        local lado = 0
        if dir == "Q" or dir == "Z" then lado = -1
        elseif dir == "E" or dir == "C" then lado = 1
        else
            ultimaDefesa = agora
            tentarCatch(bola)
            return
        end

        ultimaDefesa = agora

        local fator = math.clamp(vh * 0.008, 0, 0.12)
        local forca = math.clamp(forcaDiveMin + (forcaDiveMax - forcaDiveMin) * fator / 0.12, forcaDiveMin, forcaDiveMax)

        local imp = root.CFrame.RightVector * (lado * forca)
        local vy = root.AssemblyLinearVelocity.Y

        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        task.wait()
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Freefall) end)
        pcall(function() root.AssemblyLinearVelocity = imp + Vector3.new(0, vy + 5, 0) end)

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = imp + Vector3.new(0, 8, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.P = 8000
        bv.Parent = root
        Debris:AddItem(bv, 0.35)

        task.delay(0.8, function()
            pcall(function()
                if hum and hum.Parent then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.wait(0.2)
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end)

        local mp = { Q = "GK Z2", E = "GK C2", Z = "GK Z", C = "GK C" }
        local b = mp[dir]
        if b then pressGK(b) end
    end)
end

local function pararDive()
    if conexaoAutoDive then conexaoAutoDive:Disconnect() conexaoAutoDive = nil end
end

local function iniciarCatch()
    if conexaoAutoCatch then conexaoAutoCatch:Disconnect() end
    local ult = 0
    conexaoAutoCatch = RunService.Heartbeat:Connect(function()
        if not autoCatchAtivo or fechado then return end
        local ag = os.clock()
        if ag - ult < 0.12 then return end
        local b = obterBola()
        local ch = LocalPlayer.Character
        if not b or not ch then return end
        local r = ch:FindFirstChild("HumanoidRootPart")
        if not r then return end
        if (b.Position - r.Position).Magnitude <= distanciaCatch then
            ult = ag
            tentarCatch(b)
        end
    end)
end

local function pararCatch()
    if conexaoAutoCatch then conexaoAutoCatch:Disconnect() conexaoAutoCatch = nil end
end

-- ==================== HITBOX BOLA ====================
local function ativarHitbox(estado)
    hitboxAtivo = estado
    if conexaoHitbox then conexaoHitbox:Disconnect() conexaoHitbox = nil end
    if not estado then
        if hitboxVisual then hitboxVisual:Destroy() hitboxVisual = nil end
        return
    end
    hitboxVisual = Instance.new("Part")
    hitboxVisual.Shape = Enum.PartType.Ball
    hitboxVisual.Size = Vector3.new(tamanhoHitbox, tamanhoHitbox, tamanhoHitbox)
    hitboxVisual.Anchored = true
    hitboxVisual.CanCollide = false
    hitboxVisual.CanQuery = false
    hitboxVisual.CanTouch = false
    hitboxVisual.Material = Enum.Material.ForceField
    hitboxVisual.Color = Color3.fromRGB(0, 255, 120)
    hitboxVisual.Transparency = 0.6
    hitboxVisual.CastShadow = false
    hitboxVisual.Parent = workspace
    conexaoHitbox = RunService.Heartbeat:Connect(function()
        if not hitboxAtivo then return end
        local b = obterBola()
        if not b or not hitboxVisual then return end
        hitboxVisual.Transparency = quadradoVisivel and 0.6 or 1
        hitboxVisual.Size = Vector3.new(tamanhoHitbox, tamanhoHitbox, tamanhoHitbox)
        hitboxVisual.CFrame = CFrame.new(b.Position)
    end)
end

-- ==================== TP / FOLLOW ====================
local function acaoTP()
    local b = obterBola()
    local ch = LocalPlayer.Character
    if not b or not ch then return end
    local r = ch:FindFirstChild("HumanoidRootPart")
    if r then r.CFrame = CFrame.new(b.Position + Vector3.new(0, 3, 0)) end
end

local function iniciarTPLoop()
    if conexaoTPLoop then conexaoTPLoop:Disconnect() end
    conexaoTPLoop = RunService.Heartbeat:Connect(function()
        if not tpLoopAtivo then return end
        local b = obterBola()
        local ch = LocalPlayer.Character
        if not b or not ch then return end
        local r = ch:FindFirstChild("HumanoidRootPart")
        if r then r.CFrame = CFrame.new(b.Position + Vector3.new(0, 2.5, 0)) end
    end)
end

local function iniciarFollow()
    if conexaoFollow then conexaoFollow:Disconnect() end
    conexaoFollow = RunService.RenderStepped:Connect(function(dt)
        if not seguindo then return end
        local ch = LocalPlayer.Character
        if not ch then return end
        local hum = ch:FindFirstChild("Humanoid")
        local r = ch:FindFirstChild("HumanoidRootPart")
        if not hum or not r then return end
        if hum.MoveDirection.Magnitude > 0.3 then
            followPausado = true
            tempoParado = 0
            return
        end
        if followPausado then
            tempoParado = tempoParado + dt
            if tempoParado >= 0.5 then followPausado = false else return end
        end
        local b = obterBola()
        if not b then return end
        local dir = Vector3.new(b.Position.X - r.Position.X, 0, b.Position.Z - r.Position.Z)
        if dir.Magnitude < 1.5 then return end
        hum:Move(dir.Unit, false)
    end)
end

-- ==================== LOOP ====================
task.spawn(function()
    while not fechado do
        task.wait(0.05)
        if mostrarHitboxGK then updHitGK() end
    end
end)

-- ==================== ABA PRINCIPAL ====================
Tabs.Principal:AddSection("TP / Follow")
Tabs.Principal:AddButton({ Title = "🎯 TP para Bola", Callback = function() acaoTP() end })
Tabs.Principal:AddToggle("tpLoop", { Title = "Grudar na Bola", Default = false, Callback = function(v)
    tpLoopAtivo = v
    if v then iniciarTPLoop() elseif conexaoTPLoop then conexaoTPLoop:Disconnect() end
end })
Tabs.Principal:AddToggle("follow", { Title = "🤖 Auto Follow", Default = false, Callback = function(v)
    seguindo = v
    if v then iniciarFollow() elseif conexaoFollow then conexaoFollow:Disconnect() end
end })

-- ==================== ABA BALLS ====================
Tabs.Balls:AddSection("Skin Custom")
Tabs.Balls:AddInput("tex", { Title = "Texture ID", Default = "", Placeholder = "rbxassetid://...", Callback = function(v) textureIDAtual = v end })
Tabs.Balls:AddInput("mesh", { Title = "Mesh ID", Default = "", Placeholder = "rbxassetid://...", Callback = function(v) meshIDAtual = v end })
Tabs.Balls:AddButton({ Title = "🔄 Remover Textura", Callback = function() removerTextura() end })
Tabs.Balls:AddButton({ Title = "🔄 Remover Mesh", Callback = function() removerMesh() end })
Tabs.Balls:AddSection("Champions")
Tabs.Balls:AddButton({ Title = "🟠 Champions Laranja", Callback = function()
    textureIDAtual = "rbxassetid://6631296730"
    meshIDAtual = "rbxassetid://4545270159"
end })
Tabs.Balls:AddButton({ Title = "🔵 Champions Azul", Callback = function()
    textureIDAtual = "rbxassetid://8108082224"
    meshIDAtual = "rbxassetid://4454597214"
end })
Tabs.Balls:AddButton({ Title = "⚪ Champions Branca", Callback = function()
    textureIDAtual = "rbxassetid://7897839361"
    meshIDAtual = "rbxassetid://4761031195"
end })
Tabs.Balls:AddButton({ Title = "⚽ Original", Callback = function()
    textureIDAtual = "" meshIDAtual = ""
    removerTextura() removerMesh()
end })

-- ==================== ABA GK ====================
Tabs.GK:AddSection("Auto Dive")
Tabs.GK:AddToggle("dive", { Title = "Auto Dive", Default = false, Callback = function(v)
    autoDiveAtivo = v
    if v then iniciarDive() else pararDive() end
end })
Tabs.GK:AddSlider("distD", { Title = "Distância Dive", Default = 24, Min = 5, Max = 100, Rounding = 1, Callback = function(v) distanciaDive = v end })
Tabs.GK:AddSlider("cdD", { Title = "Cooldown x0.01s", Default = 85, Min = 20, Max = 300, Rounding = 1, Callback = function(v) cooldownDive = v / 100 end })
Tabs.GK:AddSlider("fMin", { Title = "Força Mínima", Default = 30, Min = 10, Max = 80, Rounding = 1, Callback = function(v) forcaDiveMin = v end })
Tabs.GK:AddSlider("fMax", { Title = "Força Máxima", Default = 52, Min = 20, Max = 120, Rounding = 1, Callback = function(v) forcaDiveMax = v end })
Tabs.GK:AddSlider("jMin", { Title = "Jump", Default = 50, Min = 20, Max = 120, Rounding = 1, Callback = function(v) jumpMinimo = v end })
Tabs.GK:AddToggle("hkGK", { Title = "Mostrar Esfera Roxa", Default = false, Callback = function(v) mostrarHitboxGK = v end })

Tabs.GK:AddSection("Auto Catch")
Tabs.GK:AddToggle("catch", { Title = "Auto Catch", Default = false, Callback = function(v)
    autoCatchAtivo = v
    if v then iniciarCatch() else pararCatch() end
end })
Tabs.GK:AddSlider("distC", { Title = "Distância Catch", Default = 8, Min = 2, Max = 25, Rounding = 1, Callback = function(v) distanciaCatch = v end })

-- ==================== ABA HITBOX ====================
Tabs.Hitbox:AddSection("🎯 Reach")
Tabs.Hitbox:AddToggle("reach", { Title = "Ativar Reach", Default = false, Callback = function(v)
    reachAtivo = v
    if v then iniciarReach() else pararReach() end
end })

reachSliderRef = Tabs.Hitbox:AddSlider("reachSize", {
    Title = "Tamanho do Reach", Default = 3.5, Min = 1, Max = 30, Rounding = 0.5,
    Callback = function(v) reachTamanho = v atualizarReach() end
})

Tabs.Hitbox:AddButton({ Title = "➕ Aumentar (+1)", Callback = function()
    reachTamanho = math.min(30, reachTamanho + 1)
    if reachSliderRef and reachSliderRef.SetValue then pcall(function() reachSliderRef:SetValue(reachTamanho) end) end
    atualizarReach()
    Fluent:Notify({ Title = "➕", Content = "Reach: " .. reachTamanho, Duration = 1 })
end })

Tabs.Hitbox:AddButton({ Title = "➖ Diminuir (-1)", Callback = function()
    reachTamanho = math.max(1, reachTamanho - 1)
    if reachSliderRef and reachSliderRef.SetValue then pcall(function() reachSliderRef:SetValue(reachTamanho) end) end
    atualizarReach()
    Fluent:Notify({ Title = "➖", Content = "Reach: " .. reachTamanho, Duration = 1 })
end })

Tabs.Hitbox:AddButton({ Title = "🔄 Resetar (3.5)", Callback = function()
    reachTamanho = 3.5
    if reachSliderRef and reachSliderRef.SetValue then pcall(function() reachSliderRef:SetValue(3.5) end) end
    atualizarReach()
end })

Tabs.Hitbox:AddToggle("mostrarR", { Title = "Mostrar Círculo", Default = true, Callback = function(v)
    mostrarHitboxReach = v
    if reachHitbox then reachHitbox.Transparency = v and 0.85 or 1 end
end })

Tabs.Hitbox:AddSection("📦 Hitbox Bola")
Tabs.Hitbox:AddToggle("hb", { Title = "Ativar Hitbox", Default = false, Callback = function(v) ativarHitbox(v) end })
Tabs.Hitbox:AddSlider("hbSize", { Title = "Tamanho", Default = 12, Min = 5, Max = 50, Rounding = 1, Callback = function(v)
    tamanhoHitbox = v
    if hitboxVisual then hitboxVisual.Size = Vector3.new(v, v, v) end
end })
Tabs.Hitbox:AddToggle("hbVis", { Title = "Mostrar Círculo Verde", Default = true, Callback = function(v) quadradoVisivel = v end })

-- ==================== ABA OPÇÕES ====================
Tabs.Opcoes:AddSection("Logo")
Tabs.Opcoes:AddToggle("logo", { Title = "Mostrar Logo na Tela", Default = true, Callback = function(v) floatingGui.Enabled = v end })

Tabs.Opcoes:AddSection("Info")
Tabs.Opcoes:AddParagraph({ Title = "Maritaca Hub v59.0", Content = "Versão compacta" })

Tabs.Opcoes:AddButton({ Title = "❌ Fechar Script", Callback = function()
    fechado = true
    pararReach() pararDive() pararCatch() ativarHitbox(false)
    if conexaoSkin then conexaoSkin:Disconnect() end
    if hitboxGK then hitboxGK:Destroy() end
    if floatingGui then floatingGui:Destroy() end
    pcall(function() Window:Destroy() end)
end })

-- ==================== START ====================
aplicarSkins()
Window:SelectTab(1)

Fluent:Notify({
    Title = "🦜 Maritaca Hub v59.0",
    Content = "Compacto e funcional!",
    Duration = 5
})

print("=== CARREGADO COM SUCESSO! ===")
