local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚔️ PVP MENU ⚔️ | by elvesz",
   LoadingTitle = "best pvp menu fr",
   LoadingSubtitle = "enjoy!",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local function notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title, Text = text, Icon = "rbxassetid://4483362458", Duration = 2
    })
end

_G.HitboxEnabled, _G.HitboxSize, _G.HitboxTransparency, _G.HitboxColor = false, 10, 0.7, Color3.fromRGB(255, 0, 0)
_G.HitboxTargetPlayer, _G.HitboxTeamCheck = "Todos", false

_G.AimbotEnabled, _G.AimbotPart, _G.AimbotTargetPlayer = false, "Head", "Todos"
_G.AimbotTeamCheck, _G.AimbotWallCheck, _G.AimbotCircleEnabled, _G.AimbotCircleSize = false, false, false, 100

_G.ESPEnabled, _G.ESPBox, _G.ESPSkeleton, _G.ESPNames = false, false, false, false
_G.ESPLine, _G.ESPHealthBar, _G.ESPTeamCheck = false, false, false
_G.ESPBoxColor = Color3.fromRGB(255, 255, 255)

_G.SpeedValue, _G.JumpValue, _G.GravityValue = 16, 50, 196.2
_G.LoopSpeed, _G.LoopJump, _G.LoopGravity, _G.NoclipEnabled, _G.InstantInteractEnabled = false, false, false, false, false
_G.TeleportTargetPlayer, _G.TeleportPlayerLoop, _G.TeleportPlayerCooldown = nil, false, 0.05
_G.TeleportPos, _G.TeleportPosLoop, _G.TeleportPosCooldown = nil, false, 0.05

local lp = game:GetService("Players").LocalPlayer
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible, FOVCircle.Thickness, FOVCircle.Filled = false, 1.5, false
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Transparency = 1

local DistanceText = Drawing.new("Text")
DistanceText.Visible, DistanceText.Center, DistanceText.Outline = false, true, true
DistanceText.Size, DistanceText.Font, DistanceText.Color = 16, Drawing.Fonts.UI, Color3.new(1, 1, 1)

local function getScreenCenter() return Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2) end

local function updateCircle()
    local center = getScreenCenter()
    FOVCircle.Position = center
    FOVCircle.Radius = _G.AimbotCircleSize
    FOVCircle.Visible = _G.AimbotCircleEnabled
    FOVCircle.Color = _G.HitboxColor
    FOVCircle.Transparency = 1
end

local ESPDrawings = {}

local function createESPDrawings(player)
    local d = {}
    d.Box = Drawing.new("Square")
    d.Box.Visible, d.Box.Thickness, d.Box.Filled = false, 1.5, false
    d.Box.Transparency = 0.7

    d.NameTag = Drawing.new("Text")
    d.NameTag.Visible, d.NameTag.Center, d.NameTag.Outline = false, true, true
    d.NameTag.Size, d.NameTag.Font, d.NameTag.Transparency = 14, Drawing.Fonts.UI, 0.9

    d.HealthBar = { Background = Drawing.new("Square"), Fill = Drawing.new("Square") }
    d.HealthBar.Background.Visible, d.HealthBar.Background.Filled = false, true
    d.HealthBar.Background.Color, d.HealthBar.Background.Transparency = Color3.new(0, 0, 0), 0.7
    d.HealthBar.Fill.Visible, d.HealthBar.Fill.Filled, d.HealthBar.Fill.Transparency = false, true, 0.9

    d.Line = Drawing.new("Line")
    d.Line.Visible, d.Line.Thickness, d.Line.Transparency = false, 1.5, 0.7

    d.Skeleton = {}
    ESPDrawings[player] = d
    return d
end

local function removeESPDrawings(player)
    local d = ESPDrawings[player]
    if not d then return end
    pcall(function() d.Box:Remove() d.NameTag:Remove() d.Line:Remove() d.HealthBar.Background:Remove() d.HealthBar.Fill:Remove() end)
    for _, line in pairs(d.Skeleton or {}) do pcall(function() line:Remove() end) end
    ESPDrawings[player] = nil
end

local function isEnemy(player, teamCheck)
    if teamCheck and player.Team and lp.Team then return player.Team ~= lp.Team end
    return true
end

-- CORRIGIDO: esqueleto R6 sem ligações erradas
local function getSkeletonParts(char)
    if char:FindFirstChild("UpperTorso") then
        -- R15
        return {
            {"Head", "UpperTorso"},
            {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
            {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
            {"UpperTorso", "LowerTorso"},
            {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
            {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
        }
    else
        -- R6 (corrigido)
        return {
            {"Head", "Torso"},
            {"Torso", "Left Arm"},
            {"Torso", "Right Arm"},
            {"Torso", "Left Leg"},
            {"Torso", "Right Leg"}
        }
    end
end

local function updateESP()
    for _, d in pairs(ESPDrawings) do
        d.Box.Visible, d.NameTag.Visible, d.Line.Visible = false, false, false
        d.HealthBar.Background.Visible, d.HealthBar.Fill.Visible = false, false
        for _, l in pairs(d.Skeleton) do l.Visible = false end
    end

    if not _G.ESPEnabled then return end

    for _, player in pairs(players:GetPlayers()) do
        if player ~= lp and not ESPDrawings[player] then createESPDrawings(player) end
    end

    for player, _ in pairs(ESPDrawings) do
        if not players:FindFirstChild(player.Name) then removeESPDrawings(player) end
    end

    local lineStartX, lineStartY = camera.ViewportSize.X / 2, camera.ViewportSize.Y

    for player, d in pairs(ESPDrawings) do
        pcall(function()
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
                local hrp, head = char.HumanoidRootPart, char.Head
                local hum = char:FindFirstChildOfClass("Humanoid")

                local rootPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if not onScreen or (hum and hum.Health <= 0) then return end

                local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                local boxX, boxY = rootPos.X - width / 2, headPos.Y

                local baseColor = _G.ESPBoxColor
                if _G.ESPTeamCheck then
                    baseColor = (player.Team and lp.Team and player.Team == lp.Team) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                end

                if _G.ESPNames then
                    d.NameTag.Visible = true
                    d.NameTag.Position = Vector2.new(rootPos.X, boxY - 18)
                    d.NameTag.Text = player.Name
                    d.NameTag.Color = baseColor
                end

                if _G.ESPBox then
                    d.Box.Visible = true
                    d.Box.Position = Vector2.new(boxX, boxY)
                    d.Box.Size = Vector2.new(width, height)
                    d.Box.Color = baseColor
                end

                if _G.ESPHealthBar and hum then
                    local hRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = height * hRatio
                    local barX = boxX - 8
                    local barWidth = 5
                    local barY = boxY

                    d.HealthBar.Background.Visible = true
                    d.HealthBar.Background.Position = Vector2.new(barX, barY)
                    d.HealthBar.Background.Size = Vector2.new(barWidth, height)

                    d.HealthBar.Fill.Visible = true
                    d.HealthBar.Fill.Position = Vector2.new(barX, barY + (height - barHeight))
                    d.HealthBar.Fill.Size = Vector2.new(barWidth, barHeight)
                    d.HealthBar.Fill.Color = hRatio > 0.5 and Color3.new(1 - (hRatio - 0.5) * 2, 1, 0) or Color3.new(1, hRatio * 2, 0)
                end

                if _G.ESPLine then
                    d.Line.Visible = true
                    d.Line.From = Vector2.new(lineStartX, lineStartY)
                    d.Line.To = Vector2.new(rootPos.X, legPos.Y)
                    d.Line.Color = baseColor
                end

                if _G.ESPSkeleton then
                    for _, line in pairs(d.Skeleton) do pcall(function() line:Remove() end) end
                    d.Skeleton = {}
                    for _, pair in ipairs(getSkeletonParts(char)) do
                        local p1, p2 = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                        if p1 and p2 then
                            local pos1, on1 = camera:WorldToViewportPoint(p1.Position)
                            local pos2, on2 = camera:WorldToViewportPoint(p2.Position)
                            if on1 and on2 then
                                local line = Drawing.new("Line")
                                line.Visible, line.Thickness, line.Transparency = true, 1.5, 0.7
                                line.From, line.To, line.Color = Vector2.new(pos1.X, pos1.Y), Vector2.new(pos2.X, pos2.Y), baseColor
                                table.insert(d.Skeleton, line)
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function findPlayerByPartialName(partial)
    partial = partial:lower()
    for _, v in pairs(players:GetPlayers()) do
        if v ~= lp and v.Name:lower():sub(1, #partial) == partial then
            return v
        end
    end
    return nil
end

local function setTargetFromInput(text, targetType)
    local found = findPlayerByPartialName(text)
    if found then
        if targetType == "hitbox" then
            _G.HitboxTargetPlayer = found.Name
            notify("hitbox", found.Name .. " picked!")
        elseif targetType == "aimbot" then
            _G.AimbotTargetPlayer = found.Name
            notify("aimbot", found.Name .. " picked!")
        end
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

local function applyPlayerSettings()
    local char = lp.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if _G.LoopSpeed then humanoid.WalkSpeed = _G.SpeedValue end
        if _G.LoopJump then humanoid.JumpPower = _G.JumpValue end
    end
    if _G.LoopGravity then workspace.Gravity = _G.GravityValue end
end

local function applyNoclip()
    if not _G.NoclipEnabled then return end
    local char = lp.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

local function applyImmediate(attr, value)
    if attr == "Speed" then
        _G.SpeedValue = value
        if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then lp.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value end
    elseif attr == "Jump" then
        _G.JumpValue = value
        if lp.Character and lp.Character:FindFirstChildOfClass("Humanoid") then lp.Character:FindFirstChildOfClass("Humanoid").JumpPower = value end
    elseif attr == "Gravity" then
        _G.GravityValue = value
        workspace.Gravity = value
    end
end

local lastTeleportPlayerTime = 0
local lastTeleportPosTime = 0

local function teleportToPlayer()
    if not _G.TeleportTargetPlayer then return end
    local target = players:FindFirstChild(_G.TeleportTargetPlayer)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = target.Character.HumanoidRootPart.Position
        local localRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if localRoot then localRoot.CFrame = CFrame.new(targetPos) end
    end
end

local function teleportToPosition()
    if not _G.TeleportPos then return end
    local localRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if localRoot then localRoot.CFrame = CFrame.new(_G.TeleportPos) end
end

runService.RenderStepped:Connect(function()
    pcall(updateCircle)
    pcall(applyPlayerSettings)
    pcall(applyNoclip)

    pcall(function()
        if _G.TeleportPlayerLoop then
            local now = tick()
            if now - lastTeleportPlayerTime >= _G.TeleportPlayerCooldown then
                teleportToPlayer()
                lastTeleportPlayerTime = now
            end
        end
    end)

    pcall(function()
        if _G.TeleportPosLoop then
            local now = tick()
            if now - lastTeleportPosTime >= _G.TeleportPosCooldown then
                teleportToPosition()
                lastTeleportPosTime = now
            end
        end
    end)

    pcall(function()
        if _G.InstantInteractEnabled then
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end
            end
        end
    end)

    pcall(function()
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
    end)

    pcall(function()
        if _G.AimbotEnabled then
            local targetPlayer = nil
            local closestStuds = math.huge
            local center = getScreenCenter()
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
                    DistanceText.Position = Vector2.new(center.X, center.Y - 50)
                    DistanceText.Text = "target: " .. targetPlayer.Name .. " | distance: " .. tostring(rounded) .. " studs"
                end
            else
                DistanceText.Visible = false
            end
        else
            DistanceText.Visible = false
        end
    end)

    pcall(updateESP)
end)

players.PlayerAdded:Connect(function(player)
    if player ~= lp then pcall(function() createESPDrawings(player) end) end
end)
players.PlayerRemoving:Connect(function(player)
    pcall(function() removeESPDrawings(player) end)
end)
lp.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    pcall(applyPlayerSettings)
    pcall(applyNoclip)
end)

-- UI
local HitboxTab = Window:CreateTab("🎯 Hitbox")
local AimbotTab = Window:CreateTab("🔫 Aimbot")
local HighlightTab = Window:CreateTab("💡 Esp")
local PlayerTab = Window:CreateTab("🏃 Local Player")

HitboxTab:CreateSection("📦 Hitbox")
HitboxTab:CreateToggle({ Name = "✅ Toggle hitbox", CurrentValue = false, Callback = function(Value) _G.HitboxEnabled = Value; if not Value then resetHitbox() end end })
HitboxTab:CreateInput({ Name = "📏 Hitbox size", PlaceholderText = "e.g. 25", Callback = function(Text) local n = tonumber(Text); if n then _G.HitboxSize = n end end })
HitboxTab:CreateSlider({ Name = "🔍 Hitbox transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.7, Callback = function(Value) _G.HitboxTransparency = Value end })
HitboxTab:CreateToggle({ Name = "🛡️ Team check", CurrentValue = false, Callback = function(Value) _G.HitboxTeamCheck = Value end })
HitboxTab:CreateSection("🎯 target")
HitboxTab:CreateInput({ Name = "🔎 Hitbox target (partial name)", PlaceholderText = "", Callback = function(Text) setTargetFromInput(Text, "hitbox") end })
HitboxTab:CreateButton({ Name = "👥 Everyone", Callback = function() _G.HitboxTargetPlayer = "Todos"; notify("hitbox", "everyone selected!") end })
HitboxTab:CreateColorPicker({ Name = "🎨 Hitbox color", Color = _G.HitboxColor, Callback = function(Value) _G.HitboxColor = Value end })

AimbotTab:CreateSection("🔫 Aimbot")
AimbotTab:CreateToggle({ Name = "✅ Toggle aimbot", CurrentValue = false, Callback = function(Value) _G.AimbotEnabled = Value; if not Value then DistanceText.Visible = false end end })
AimbotTab:CreateDropdown({ Name = "🧍 Body part", Options = {"Head", "HumanoidRootPart"}, CurrentOption = "Head", Callback = function(Option) _G.AimbotPart = Option end })
AimbotTab:CreateToggle({ Name = "🛡️ Team check", CurrentValue = false, Callback = function(Value) _G.AimbotTeamCheck = Value end })
AimbotTab:CreateToggle({ Name = "🧱 Wall check", CurrentValue = false, Callback = function(Value) _G.AimbotWallCheck = Value end })
AimbotTab:CreateSection("⭕ Fov")
AimbotTab:CreateToggle({ Name = "✅ Use fov", CurrentValue = false, Callback = function(Value) _G.AimbotCircleEnabled = Value end })
AimbotTab:CreateSlider({ Name = "📏 Circle fov", Range = {10, 1000}, Increment = 5, CurrentValue = 100, Callback = function(Value) _G.AimbotCircleSize = Value end })
AimbotTab:CreateSection("🎯 Specific target")
AimbotTab:CreateInput({ Name = "🔎 Aimbot target", PlaceholderText = "", Callback = function(Text) setTargetFromInput(Text, "aimbot") end })
AimbotTab:CreateButton({ Name = "👥 Everyone", Callback = function() _G.AimbotTargetPlayer = "Todos"; notify("aimbot", "everyone selected!") end })

-- Reorganização da aba Highlight: duas seções
HighlightTab:CreateSection("👁️ Visual options")
HighlightTab:CreateToggle({ Name = "📦 Show boxes", CurrentValue = false, Callback = function(v) _G.ESPBox = v end })
HighlightTab:CreateToggle({ Name = "🦴 Show skeletons", CurrentValue = false, Callback = function(v) _G.ESPSkeleton = v end })
HighlightTab:CreateToggle({ Name = "🏷️ Show names", CurrentValue = false, Callback = function(v) _G.ESPNames = v end })
HighlightTab:CreateToggle({ Name = "📏 Show lines", CurrentValue = false, Callback = function(v) _G.ESPLine = v end })
HighlightTab:CreateToggle({ Name = "❤️ Show health bar", CurrentValue = false, Callback = function(v) _G.ESPHealthBar = v end })

HighlightTab:CreateSection("🎨 Style")
HighlightTab:CreateToggle({ Name = "✅ Toggle highlight (dont work, i will fix later)", CurrentValue = false, Callback = function(v) _G.ESPEnabled = v end })
HighlightTab:CreateToggle({ Name = "🛡️ Team check (ally: green | enemy: red)", CurrentValue = false, Callback = function(v) _G.ESPTeamCheck = v end })
HighlightTab:CreateColorPicker({ Name = "Default highlight color (turns off team check)", Color = _G.ESPBoxColor, Callback = function(v) _G.ESPBoxColor = v; _G.ESPTeamCheck = false end })

PlayerTab:CreateSection("🏃 Physical stats")
local SpeedInput = PlayerTab:CreateInput({ Name = "⚡ Speed", PlaceholderText = "16", Callback = function(Text) local n = tonumber(Text); if n then applyImmediate("Speed", n) end end })
local JumpInput = PlayerTab:CreateInput({ Name = "🦘 Jump", PlaceholderText = "50", Callback = function(Text) local n = tonumber(Text); if n then applyImmediate("Jump", n) end end })
local GravityInput = PlayerTab:CreateInput({ Name = "🌍 Gravity", PlaceholderText = "196.2", Callback = function(Text) local n = tonumber(Text); if n then applyImmediate("Gravity", n) end end })
PlayerTab:CreateSection("🔄 loops")
PlayerTab:CreateToggle({ Name = "⚡ Loop speed", CurrentValue = false, Callback = function(v) _G.LoopSpeed = v; if v then local c = lp.Character; if c and c:FindFirstChildOfClass("Humanoid") then c:FindFirstChildOfClass("Humanoid").WalkSpeed = _G.SpeedValue end end end })
PlayerTab:CreateToggle({ Name = "🦘 Loop jump", CurrentValue = false, Callback = function(v) _G.LoopJump = v; if v then local c = lp.Character; if c and c:FindFirstChildOfClass("Humanoid") then c:FindFirstChildOfClass("Humanoid").JumpPower = _G.JumpValue end end end })
PlayerTab:CreateToggle({ Name = "🌍 Loop gravity", CurrentValue = false, Callback = function(v) _G.LoopGravity = v; if v then workspace.Gravity = _G.GravityValue end end })
PlayerTab:CreateSection("🚶 Movement")
PlayerTab:CreateToggle({ Name = "👻 NoClip", CurrentValue = false, Callback = function(v) _G.NoclipEnabled = v; if not v then local c = lp.Character; if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end end })
PlayerTab:CreateSection("🔄 Reset")
PlayerTab:CreateButton({ Name = "♻️ Reset values", Callback = function() _G.SpeedValue = 16; _G.JumpValue = 50; _G.GravityValue = 196.2; applyImmediate("Speed", 16); applyImmediate("Jump", 50); applyImmediate("Gravity", 196.2); pcall(function() SpeedInput:Set("16") end); pcall(function() JumpInput:Set("50") end); pcall(function() GravityInput:Set("196.2") end); notify("player", "values reset!") end })
PlayerTab:CreateSection("📡 TP to player")
PlayerTab:CreateInput({ Name = "🔎 Player name (partial)", PlaceholderText = "", Callback = function(Text) local found = findPlayerByPartialName(Text); if found then _G.TeleportTargetPlayer = found.Name; notify("tp", found.Name .. " picked!") else _G.TeleportTargetPlayer = nil end end })
PlayerTab:CreateButton({ Name = "🚀 TP now", Callback = function() teleportToPlayer() end })
PlayerTab:CreateToggle({ Name = "🔄 Loop tp (player)", CurrentValue = false, Callback = function(v) _G.TeleportPlayerLoop = v end })
PlayerTab:CreateInput({ Name = "⏱️ Loop tp cooldown (seconds)", PlaceholderText = "0.05", Callback = function(Text) local n = tonumber(Text); if n then _G.TeleportPlayerCooldown = n end end })
PlayerTab:CreateSection("📍 T0 to position")
PlayerTab:CreateInput({ Name = "📌 Position (x,y,z)", PlaceholderText = "10,20,30", Callback = function(Text) local parts = Text:split(","); if #parts == 3 then local x = tonumber(parts[1]); local y = tonumber(parts[2]); local z = tonumber(parts[3]); if x and y and z then _G.TeleportPos = Vector3.new(x, y, z) end end end })
PlayerTab:CreateButton({ Name = "🚀 TP to position", Callback = function() teleportToPosition() end })
PlayerTab:CreateToggle({ Name = "🔄 Loop tp pos", CurrentValue = false, Callback = function(v) _G.TeleportPosLoop = v end })
PlayerTab:CreateInput({ Name = "⏱️ Loop tp pos cooldown (seconds)", PlaceholderText = "0.05", Callback = function(Text) local n = tonumber(Text); if n then _G.TeleportPosCooldown = n end end })
PlayerTab:CreateSection("🛠️ Utilities")
PlayerTab:CreateButton({ Name = "⚡ Instant interact", Callback = function() _G.InstantInteractEnabled = true; for _, prompt in pairs(workspace:GetDescendants()) do if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end end; notify("player", "instant interact on!") end })

-- init highlight
for _, player in pairs(players:GetPlayers()) do
    if player ~= lp then pcall(function() createESPDrawings(player) end) end
end
