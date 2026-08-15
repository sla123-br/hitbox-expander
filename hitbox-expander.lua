local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🌌 Player Hitbox & Aimbot System",
   LoadingTitle = "Carregando...",
   LoadingSubtitle = "Aguarde...",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

-- Variáveis globais
_G.HitboxEnabled = false
_G.HitboxSize = 10
_G.HitboxTransparency = 0.7
_G.HitboxColor = Color3.fromRGB(255, 0, 0)
_G.TargetPlayer = "Todos"

_G.AimbotEnabled = false
_G.AimbotPart = "Head" -- "Head" ou "HumanoidRootPart"
_G.TeamCheck = false
_G.WallCheck = false
_G.CircleEnabled = false
_G.CircleSize = 100

local lp = game:GetService("Players").LocalPlayer
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local camera = workspace.CurrentCamera

-- Círculo FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Color = _G.HitboxColor
FOVCircle.Transparency = 1

local function updateCircle()
    FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    FOVCircle.Radius = _G.CircleSize
    FOVCircle.Color = _G.HitboxColor
    FOVCircle.Visible = _G.CircleEnabled
end

-- Funções auxiliares
local function getPlayersList()
    local list = {"Todos"}
    for _, v in pairs(players:GetPlayers()) do
        if v ~= lp then
            table.insert(list, v.Name)
        end
    end
    return list
end

local function getTargetPart(player)
    local char = player.Character
    if not char then return nil end
    if _G.AimbotPart == "Head" then
        local head = char:FindFirstChild("Head")
        if head then return head end
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp end
    return char:FindFirstChild("Torso") -- fallback
end

local function isEnemy(player)
    if _G.TeamCheck then
        return player.Team ~= lp.Team
    end
    return true
end

local function isVisible(player, part)
    if not _G.WallCheck then return true end
    local origin = camera.CFrame.Position
    local direction = part.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {lp.Character, player.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(player.Character)
end

local function getClosestPlayerInCircle()
    local closest = nil
    local minDist = math.huge
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    for _, player in pairs(players:GetPlayers()) do
        if player ~= lp and player.Character and isEnemy(player) then
            local part = getTargetPart(player)
            if part then
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local pos2D = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = (pos2D - center).Magnitude
                    if dist <= _G.CircleSize and dist < minDist then
                        if isVisible(player, part) then
                            minDist = dist
                            closest = player
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function resetHitbox()
    for _, player in pairs(players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
            hrp.CanCollide = true
        end
    end
end

-- Loop principal
runService.RenderStepped:Connect(function()
    updateCircle()

    -- Hitbox expansiva
    if _G.HitboxEnabled then
        for _, player in pairs(players:GetPlayers()) do
            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local canApply = (_G.TargetPlayer == "Todos" or player.Name == _G.TargetPlayer)
                if canApply then
                    hrp.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                    hrp.Transparency = _G.HitboxTransparency
                    hrp.Color = _G.HitboxColor
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
    end

    -- Aimbot
    if _G.AimbotEnabled then
        local targetPlayer = nil
        if _G.CircleEnabled then
            targetPlayer = getClosestPlayerInCircle()
        else
            -- Sem círculo: alvo selecionado ou mais próximo da mira
            if _G.TargetPlayer == "Todos" then
                local closestDist = math.huge
                local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                for _, player in pairs(players:GetPlayers()) do
                    if player ~= lp and player.Character and isEnemy(player) then
                        local part = getTargetPart(player)
                        if part then
                            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if dist < closestDist and isVisible(player, part) then
                                    closestDist = dist
                                    targetPlayer = player
                                end
                            end
                        end
                    end
                end
            else
                local found = players:FindFirstChild(_G.TargetPlayer)
                if found and found.Character and isEnemy(found) then
                    targetPlayer = found
                end
            end
        end

        if targetPlayer and targetPlayer.Character then
            local part = getTargetPart(targetPlayer)
            if part then
                camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
            end
        end
    end
end)

-- Interface
local Tab = Window:CreateTab("Hitbox", 4483362458)
Tab:CreateSection("Hitbox de Players")
Tab:CreateToggle({
   Name = "Ativar Hitbox",
   CurrentValue = false,
   Callback = function(Value)
       _G.HitboxEnabled = Value
       if not Value then resetHitbox() end
   end,
})
Tab:CreateInput({
   Name = "Tamanho da Hitbox",
   PlaceholderText = "Ex: 25",
   Callback = function(Text)
       local n = tonumber(Text)
       if n then _G.HitboxSize = n end
   end,
})
Tab:CreateSection("Alvo")
local PlayerDrop = Tab:CreateDropdown({
   Name = "Alvo (Hitbox e Aimbot sem círculo)",
   Options = getPlayersList(),
   CurrentOption = {"Todos"},
   Callback = function(Option) _G.TargetPlayer = Option[1] end,
})
Tab:CreateButton({
   Name = "Atualizar Lista",
   Callback = function() PlayerDrop:Refresh(getPlayersList()) end,
})
Tab:CreateColorPicker({
    Name = "Cor da Hitbox",
    Color = _G.HitboxColor,
    Callback = function(Value) _G.HitboxColor = Value end,
})

local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
AimbotTab:CreateSection("Aimbot")
AimbotTab:CreateToggle({
   Name = "Ativar Aimbot",
   CurrentValue = false,
   Callback = function(Value) _G.AimbotEnabled = Value end,
})
AimbotTab:CreateDropdown({
   Name = "Parte do Corpo",
   Options = {"Head", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   Callback = function(Option) _G.AimbotPart = Option[1] end,
})
AimbotTab:CreateSection("Filtro de Círculo")
AimbotTab:CreateToggle({
   Name = "Usar Círculo (mira apenas dentro)",
   CurrentValue = false,
   Callback = function(Value) _G.CircleEnabled = Value end,
})
AimbotTab:CreateInput({
   Name = "Raio do Círculo",
   PlaceholderText = "Ex: 150",
   Callback = function(Text)
       local n = tonumber(Text)
       if n then _G.CircleSize = n end
   end,
})
AimbotTab:CreateSection("Checagens")
AimbotTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Callback = function(Value) _G.TeamCheck = Value end,
})
AimbotTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = false,
   Callback = function(Value) _G.WallCheck = Value end,
})
AimbotTab:CreateSection("Visual")
AimbotTab:CreateColorPicker({
    Name = "Cor do Círculo",
    Color = _G.HitboxColor,
    Callback = function(Value) _G.HitboxColor = Value end,
})
