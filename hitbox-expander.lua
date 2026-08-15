local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚔️ PVP MENU ⚔️ | by elvesz",
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
_G.HitboxTargetPlayer = "Todos"
_G.HitboxTeamCheck = false

_G.AimbotEnabled = false
_G.AimbotPart = "Head"
_G.AimbotTargetPlayer = "Todos"
_G.AimbotTeamCheck = false
_G.AimbotWallCheck = false
_G.AimbotCircleEnabled = false
_G.AimbotCircleSize = 100

_G.ESPEnabled = false
_G.ESPBox = false
_G.ESPSkeleton = false
_G.ESPNames = false
_G.ESPTeamCheck = false
_G.ESPBoxColor = Color3.fromRGB(255, 255, 255)
_G.ESPSkeletonColor = Color3.fromRGB(255, 255, 255)
_G.ESPNameColor = Color3.fromRGB(255, 255, 255)
_G.ESPTeamColor = true

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

-- Texto de distância do aimbot
local DistanceText = Drawing.new("Text")
DistanceText.Visible = false
DistanceText.Center = true
DistanceText.Outline = true
DistanceText.Size = 18
DistanceText.Color = Color3.fromRGB(255, 255, 255)
DistanceText.Transparency = 1
DistanceText.Position = Vector2.new(0, 0)
DistanceText.Text = ""

-- Tabela para ESP
local ESPDrawings = {}

local function createESPDrawings(player)
    local drawings = {}
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 2
    box.Filled = false
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Transparency = 1
    
    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Size = 16
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Transparency = 1
    
    local highlight = nil
    pcall(function()
        highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Enabled = false
    end)
    
    drawings.Box = box
    drawings.NameTag = nameTag
    drawings.Highlight = highlight
    drawings.Skeleton = {}
    
    ESPDrawings[player] = drawings
    return drawings
end

local function removeESPDrawings(player)
    local d = ESPDrawings[player]
    if not d then return end
    
    if d.Box then d.Box:Remove() end
    if d.NameTag then d.NameTag:Remove() end
    if d.Highlight then pcall(function() d.Highlight:Destroy() end) end
    if d.Skeleton then
        for _, line in pairs(d.Skeleton) do
            if line then line:Remove() end
        end
    end
    ESPDrawings[player] = nil
end

local function updateCircle()
    FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    FOVCircle.Radius = _G.AimbotCircleSize
    FOVCircle.Color = _G.HitboxColor
    FOVCircle.Visible = _G.AimbotCircleEnabled
end

local function getPlayersList()
    local list = {"Todos"}
    for _, v in pairs(players:GetPlayers()) do
        if v ~= lp then
            table.insert(list, v.Name)
        end
    end
    return list
end

local HitboxPlayerDrop, AimbotPlayerDrop

local function updatePlayerDropdowns()
    local list = getPlayersList()
    if HitboxPlayerDrop then
        pcall(function() HitboxPlayerDrop:Refresh(list) end)
    end
    if AimbotPlayerDrop then
        pcall(function() AimbotPlayerDrop:Refresh(list) end)
    end
end

local function getTargetPart(player)
    local char = player.Character
    if not char then return nil end
    if _G.AimbotPart == "Head" then
        local head = char:FindFirstChild("Head")
        if head then return head end
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

local function isEnemy(player, teamCheck)
    if teamCheck then
        return player.Team ~= lp.Team
    end
    return true
end

local function isVisible(player, part)
    if not _G.AimbotWallCheck then return true end
    local origin = camera.CFrame.Position
    local direction = part.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {lp.Character, player.Character}
    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil or result.Instance:IsDescendantOf(player.Character)
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

local function getSkeletonParts(char)
    if char:FindFirstChild("UpperTorso") and char:FindFirstChild("LowerTorso") then
        return {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LeftUpperArm"},
            {"LeftUpperArm", "LeftLowerArm"},
            {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"},
            {"RightUpperArm", "RightLowerArm"},
            {"RightLowerArm", "RightHand"},
            {"UpperTorso", "LowerTorso"},
            {"LowerTorso", "LeftUpperLeg"},
            {"LeftUpperLeg", "LeftLowerLeg"},
            {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"},
            {"RightUpperLeg", "RightLowerLeg"},
            {"RightLowerLeg", "RightFoot"}
        }
    else
        return {
            {"Head", "Torso"},
            {"Torso", "Left Arm"},
            {"Left Arm", "Left Leg"},
            {"Torso", "Right Arm"},
            {"Right Arm", "Right Leg"},
            {"Torso", "Left Leg"},
            {"Torso", "Right Leg"}
        }
    end
end

local function drawFullBodyBox(char, d, color)
    if not d.Box then return end
    local cf, size = char:GetBoundingBox()
    local corners = {
        (cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)).p,
        (cf * CFrame.new( size.X/2, -size.Y/2, -size.Z/2)).p,
        (cf * CFrame.new( size.X/2,  size.Y/2, -size.Z/2)).p,
        (cf * CFrame.new(-size.X/2,  size.Y/2, -size.Z/2)).p,
        (cf * CFrame.new(-size.X/2, -size.Y/2,  size.Z/2)).p,
        (cf * CFrame.new( size.X/2, -size.Y/2,  size.Z/2)).p,
        (cf * CFrame.new( size.X/2,  size.Y/2,  size.Z/2)).p,
        (cf * CFrame.new(-size.X/2,  size.Y/2,  size.Z/2)).p,
    }
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local onScreenAny = false
    for _, corner in ipairs(corners) do
        local screenPos, onScreen = camera:WorldToViewportPoint(corner)
        if onScreen then
            onScreenAny = true
            if screenPos.X < minX then minX = screenPos.X end
            if screenPos.X > maxX then maxX = screenPos.X end
            if screenPos.Y < minY then minY = screenPos.Y end
            if screenPos.Y > maxY then maxY = screenPos.Y end
        end
    end
    if onScreenAny then
        d.Box.Visible = true
        d.Box.Position = Vector2.new(minX, minY)
        d.Box.Size = Vector2.new(maxX - minX, maxY - minY)
        d.Box.Color = color
    else
        d.Box.Visible = false
    end
end

local function updateESP()
    if not _G.ESPEnabled then
        for _, d in pairs(ESPDrawings) do
            if d.Box then d.Box.Visible = false end
            if d.NameTag then d.NameTag.Visible = false end
            if d.Highlight then pcall(function() d.Highlight.Enabled = false end) end
            if d.Skeleton then
                for _, line in pairs(d.Skeleton) do
                    if line then line.Visible = false end
                end
            end
        end
        return
    end
    
    for _, player in pairs(players:GetPlayers()) do
        if player ~= lp and not ESPDrawings[player] then
            createESPDrawings(player)
        end
    end
    
    for player, d in pairs(ESPDrawings) do
        if not players:FindFirstChild(player.Name) then
            removeESPDrawings(player)
        end
    end
    
    for player, d in pairs(ESPDrawings) do
        if player ~= lp and player.Parent == players then
            local char = player.Character
            if char and char.Parent then
                if d.Highlight and not d.Highlight.Parent then
                    d.Highlight = Instance.new("Highlight")
                    d.Highlight.FillColor = Color3.fromRGB(255,0,0)
                    d.Highlight.OutlineColor = Color3.fromRGB(255,0,0)
                    d.Highlight.FillTransparency = 0.5
                    d.Highlight.OutlineTransparency = 0
                    d.Highlight.Enabled = false
                end
                
                local isEnemyPlayer = isEnemy(player, _G.ESPTeamCheck)
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                
                if hrp and head then
                    if d.Highlight then
                        pcall(function()
                            d.Highlight.Parent = char
                            d.Highlight.Enabled = true
                            if _G.ESPTeamCheck then
                                d.Highlight.FillColor = isEnemyPlayer and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                                d.Highlight.OutlineColor = d.Highlight.FillColor
                            else
                                d.Highlight.FillColor = Color3.fromRGB(255,0,0)
                                d.Highlight.OutlineColor = Color3.fromRGB(255,0,0)
                            end
                        end)
                    end
                    
                    if _G.ESPNames and d.NameTag then
                        local headPos, onScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        if onScreen then
                            d.NameTag.Visible = true
                            d.NameTag.Position = Vector2.new(headPos.X, headPos.Y)
                            d.NameTag.Text = player.Name
                            if _G.ESPTeamColor and _G.ESPTeamCheck then
                                d.NameTag.Color = isEnemyPlayer and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                            else
                                d.NameTag.Color = _G.ESPNameColor
                            end
                        else
                            d.NameTag.Visible = false
                        end
                    else
                        if d.NameTag then d.NameTag.Visible = false end
                    end
                    
                    if _G.ESPBox and d.Box then
                        local color = _G.ESPBoxColor
                        if _G.ESPTeamColor and _G.ESPTeamCheck then
                            color = isEnemyPlayer and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                        end
                        drawFullBodyBox(char, d, color)
                    else
                        if d.Box then d.Box.Visible = false end
                    end
                    
                    if _G.ESPSkeleton then
                        if d.Skeleton then
                            for _, line in pairs(d.Skeleton) do
                                if line then line:Remove() end
                            end
                        end
                        d.Skeleton = {}
                        
                        local bodyParts = getSkeletonParts(char)
                        for _, pair in ipairs(bodyParts) do
                            local p1 = char:FindFirstChild(pair[1])
                            local p2 = char:FindFirstChild(pair[2])
                            if p1 and p2 then
                                local pos1, on1 = camera:WorldToViewportPoint(p1.Position)
                                local pos2, on2 = camera:WorldToViewportPoint(p2.Position)
                                if on1 and on2 then
                                    local line = Drawing.new("Line")
                                    line.Visible = true
                                    line.From = Vector2.new(pos1.X, pos1.Y)
                                    line.To = Vector2.new(pos2.X, pos2.Y)
                                    line.Thickness = 1.5
                                    line.Transparency = 1
                                    if _G.ESPTeamColor and _G.ESPTeamCheck then
                                        line.Color = isEnemyPlayer and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
                                    else
                                        line.Color = _G.ESPSkeletonColor
                                    end
                                    table.insert(d.Skeleton, line)
                                end
                            end
                        end
                    else
                        if d.Skeleton then
                            for _, line in pairs(d.Skeleton) do
                                if line then line.Visible = false end
                            end
                        end
                    end
                end
            else
                if d.Box then d.Box.Visible = false end
                if d.NameTag then d.NameTag.Visible = false end
                if d.Highlight then pcall(function() d.Highlight.Enabled = false end) end
                if d.Skeleton then
                    for _, line in pairs(d.Skeleton) do
                        if line then line.Visible = false end
                    end
                end
            end
        else
            removeESPDrawings(player)
        end
    end
end

-- Loop principal
runService.RenderStepped:Connect(function()
    updateCircle()
    
    -- Hitbox
    if _G.HitboxEnabled then
        for _, player in pairs(players:GetPlayers()) do
            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local isEnemyPlayer = isEnemy(player, _G.HitboxTeamCheck)
                local canApply = (_G.HitboxTargetPlayer == "Todos" or player.Name == _G.HitboxTargetPlayer)
                if canApply and isEnemyPlayer then
                    hrp.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                    hrp.Transparency = _G.HitboxTransparency
                    hrp.Color = _G.HitboxColor
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2,2,1)
                    hrp.Transparency = 1
                    hrp.CanCollide = true
                end
            end
        end
    end
    
    -- Aimbot (mira no mais próximo por distância em studs, com 2 casas decimais)
    if _G.AimbotEnabled then
        local targetPlayer = nil
        local closestStuds = math.huge
        local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local localRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local localPos = localRoot and localRoot.Position or camera.CFrame.Position
        
        for _, player in pairs(players:GetPlayers()) do
            if player ~= lp and player.Character then
                local canTarget = (_G.AimbotTargetPlayer == "Todos" or player.Name == _G.AimbotTargetPlayer)
                if canTarget and isEnemy(player, _G.AimbotTeamCheck) then
                    local part = getTargetPart(player)
                    if part then
                        local studs = (part.Position - localPos).Magnitude
                        
                        if _G.AimbotCircleEnabled then
                            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if screenDist <= _G.AimbotCircleSize and isVisible(player, part) and studs < closestStuds then
                                    closestStuds = studs
                                    targetPlayer = player
                                end
                            end
                        else
                            if isVisible(player, part) and studs < closestStuds then
                                closestStuds = studs
                                targetPlayer = player
                            end
                        end
                    end
                end
            end
        end
        
        if targetPlayer and targetPlayer.Character then
            local part = getTargetPart(targetPlayer)
            if part then
                camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
                local rounded = math.floor(closestStuds * 100 + 0.5) / 100
                DistanceText.Visible = true
                DistanceText.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2 - 50)
                DistanceText.Text = "Alvo: " .. targetPlayer.Name .. " | Distância: " .. tostring(rounded) .. " studs"
            end
        else
            DistanceText.Visible = false
        end
    else
        DistanceText.Visible = false
    end
    
    -- ESP
    updateESP()
end)

-- Eventos de jogadores (atualização automática)
players.PlayerAdded:Connect(function(player)
    if player ~= lp then
        createESPDrawings(player)
        updatePlayerDropdowns()
    end
end)

players.PlayerRemoving:Connect(function(player)
    removeESPDrawings(player)
    updatePlayerDropdowns()
end)

-- Interface com Rayfield
local HitboxTab = Window:CreateTab("Hitbox", 4483362458)
HitboxTab:CreateSection("Hitbox de Players")
HitboxTab:CreateToggle({
   Name = "Ativar Hitbox",
   CurrentValue = false,
   Callback = function(Value)
       _G.HitboxEnabled = Value
       if not Value then resetHitbox() end
   end,
})
HitboxTab:CreateSlider({
   Name = "Tamanho da Hitbox",
   Range = {1, 50},
   Increment = 1,
   CurrentValue = 10,
   Callback = function(Value)
       _G.HitboxSize = Value
   end,
})
HitboxTab:CreateSlider({
   Name = "Transparência da Hitbox",
   Range = {0, 1},
   Increment = 0.1,
   CurrentValue = 0.7,
   Callback = function(Value)
       _G.HitboxTransparency = Value
   end,
})
HitboxTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Callback = function(Value)
       _G.HitboxTeamCheck = Value
   end,
})
HitboxTab:CreateSection("Alvo")
HitboxPlayerDrop = HitboxTab:CreateDropdown({
   Name = "Alvo da Hitbox",
   Options = getPlayersList(),
   CurrentOption = "Todos",
   Callback = function(Option)
       _G.HitboxTargetPlayer = Option
   end,
})
HitboxTab:CreateColorPicker({
   Name = "Cor da Hitbox",
   Color = _G.HitboxColor,
   Callback = function(Value)
       _G.HitboxColor = Value
   end,
})
HitboxTab:CreateButton({
   Name = "Atualizar Lista",
   Callback = function()
       updatePlayerDropdowns()
   end,
})

local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
AimbotTab:CreateSection("Aimbot")
AimbotTab:CreateToggle({
   Name = "Ativar Aimbot",
   CurrentValue = false,
   Callback = function(Value)
       _G.AimbotEnabled = Value
       if not Value then DistanceText.Visible = false end
   end,
})
AimbotTab:CreateDropdown({
   Name = "Parte do Corpo",
   Options = {"Head", "HumanoidRootPart"},
   CurrentOption = "Head",
   Callback = function(Option)
       _G.AimbotPart = Option
   end,
})
AimbotTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Callback = function(Value)
       _G.AimbotTeamCheck = Value
   end,
})
AimbotTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = false,
   Callback = function(Value)
       _G.AimbotWallCheck = Value
   end,
})
AimbotTab:CreateSection("Círculo")
AimbotTab:CreateToggle({
   Name = "Usar Círculo",
   CurrentValue = false,
   Callback = function(Value)
       _G.AimbotCircleEnabled = Value
   end,
})
AimbotTab:CreateSlider({
   Name = "Raio do Círculo",
   Range = {10, 500},
   Increment = 5,
   CurrentValue = 100,
   Callback = function(Value)
       _G.AimbotCircleSize = Value
   end,
})
AimbotTab:CreateSection("Alvo Específico")
AimbotPlayerDrop = AimbotTab:CreateDropdown({
   Name = "Alvo do Aimbot",
   Options = getPlayersList(),
   CurrentOption = "Todos",
   Callback = function(Option)
       _G.AimbotTargetPlayer = Option
   end,
})
AimbotTab:CreateButton({
   Name = "Atualizar Lista",
   Callback = function()
       updatePlayerDropdowns()
   end,
})

local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("ESP Principal")
ESPTab:CreateToggle({
   Name = "Ativar ESP",
   CurrentValue = false,
   Callback = function(Value)
       _G.ESPEnabled = Value
   end,
})
ESPTab:CreateToggle({
   Name = "Mostrar Caixa (Box)",
   CurrentValue = false,
   Callback = function(Value)
       _G.ESPBox = Value
   end,
})
ESPTab:CreateToggle({
   Name = "Mostrar Esqueleto",
   CurrentValue = false,
   Callback = function(Value)
       _G.ESPSkeleton = Value
   end,
})
ESPTab:CreateToggle({
   Name = "Mostrar Nomes",
   CurrentValue = false,
   Callback = function(Value)
       _G.ESPNames = Value
   end,
})
ESPTab:CreateSection("Team Check")
ESPTab:CreateToggle({
   Name = "Team Check (cores automáticas)",
   CurrentValue = false,
   Callback = function(Value)
       _G.ESPTeamCheck = Value
       _G.ESPTeamColor = Value
   end,
})
ESPTab:CreateSection("Cores Personalizadas")
ESPTab:CreateColorPicker({
   Name = "Cor da Caixa",
   Color = _G.ESPBoxColor,
   Callback = function(Value)
       _G.ESPBoxColor = Value
       _G.ESPTeamColor = false
   end,
})
ESPTab:CreateColorPicker({
   Name = "Cor do Esqueleto",
   Color = _G.ESPSkeletonColor,
   Callback = function(Value)
       _G.ESPSkeletonColor = Value
       _G.ESPTeamColor = false
   end,
})
ESPTab:CreateColorPicker({
   Name = "Cor do Nome",
   Color = _G.ESPNameColor,
   Callback = function(Value)
       _G.ESPNameColor = Value
       _G.ESPTeamColor = false
   end,
})
ESPTab:CreateButton({
   Name = "Atualizar Lista",
   Callback = function()
       updatePlayerDropdowns()
   end,
})

-- Inicializar ESP para jogadores existentes
for _, player in pairs(players:GetPlayers()) do
    if player ~= lp then
        createESPDrawings(player)
    end
end

updatePlayerDropdowns()
