-- ======================================================
-- MARITACA HUB - Futebol Clássico
-- By Maritaca
-- Tema: Escuro (Preto)
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
local DiveDistance = 15 -- Distância mínima para detectar a bola
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- ======================================================
-- LÓGICA DO AUTO DIVE (GOLEIRO AUTOMÁTICO SEM DELAY)
-- ======================================================

local function GetBall()
    -- Busca o objeto da bola na Workspace
    return workspace:FindFirstChild("Ball") or workspace:FindFirstChild("Bola") or workspace:FindFirstChildOfClass("Part")
end

-- Thread de Detecção e Pulo na Bola
task.spawn(function()
    while task.wait(0.01) do -- Rodando em alta frequência (sem delay)
        if AutoDiveEnabled then
            local root = Character and Character:FindFirstChild("HumanoidRootPart")
            local humanoid = Character and Character:FindFirstChild("Humanoid")
            local ball = GetBall()

            if root and humanoid and ball then
                local distance = (root.Position - ball.Position).Magnitude

                -- Se a bola estiver dentro do alcance de defesa/pulo
                if distance <= DiveDistance then
                    -- Direção em direção à bola
                    local direction = (ball.Position - root.Position).Unit
                    
                    -- Aplica o impulso/pulo automático na direção da bola
                    root.Velocity = direction * 50 + Vector3.new(0, 25, 0)
                    
                    -- Ativa a animação/estado de pulo/carrinho se necessário
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    
                    -- Aguarda a bola se afastar um pouco para evitar pulos repetidos sem parar
                    task.wait(0.5)
                end
            end
        end
    end
end)

-- Atualiza o personagem quando renascer (Reset/Morte)
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
end)

-- ======================================================
-- ELEMENTOS DA INTERFACE (UI)
-- ======================================================

Tabs.Goleiro:AddSection("Funções de Goleiro")

-- Alternador (Toggle) do Auto Dive
local DiveToggle = Tabs.Goleiro:AddToggle("AutoDiveToggle", {
    Title = "Auto Dive (Defesa Automática)",
    Default = false,
    Callback = function(Value)
        AutoDiveEnabled = Value
        if Value then
            Fluent:Notify({
                Title = "Maritaca Hub",
                Content = "Auto Dive Ativado! Mantenha-se perto do gol.",
                Duration = 3
            })
        end
    end
})

-- Slider de Ajuste de Distância
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
    Content = "Iniciado com sucesso! Desenvolvido por Maritaca.",
    Duration = 5
})

-- Seleciona a Aba Principal por Padrão
Window:SelectTab(1)
