local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🌌 Player Hitbox System",
   LoadingTitle = "Carregando Players...",
   LoadingSubtitle = "Aguarde...",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

_G.HitboxSize = 10
_G.HitboxTransparency = 0.7
_G.HitboxColor = Color3.fromRGB(255, 0, 0)
_G.HitboxEnabled = false
_G.TargetPlayer = "Todos"
_G.CircleEnabled = false
_G.CircleSize = 100

local lp = game:GetService("Players").LocalPlayer
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local camera = workspace.CurrentCamera

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

runService.RenderStepped:Connect(function()
    updateCircle()

    if _G.HitboxEnabled then
        for _, player in pairs(players:GetPlayers()) do
            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local canApply = false
                local isTarget = (_G.TargetPlayer == "Todos" or player.Name == _G.TargetPlayer)

                if isTarget then
                    if _G.CircleEnabled then
                        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local mag = (Vector2.new(screenPos.X, screenPos.Y) - FOVCircle.Position).Magnitude
                            if mag <= _G.CircleSize then
                                canApply = true
                            end
                        end
                    else
                        canApply = true
                    end
                end

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
end)

local function getPlayers()
    local pList = {"Todos"}
    for _, v in pairs(players:GetPlayers()) do
        if v ~= lp then table.insert(pList, v.Name) end
    end
    return pList
end

local Tab = Window:CreateTab("Configurações", 4483362458)

Tab:CreateSection("Hitbox de Players")

Tab:CreateToggle({
   Name = "Ativar Hitbox",
   CurrentValue = false,
   Callback = function(Value) _G.HitboxEnabled = Value end,
})

Tab:CreateInput({
   Name = "Tamanho da Hitbox",
   PlaceholderText = "Ex: 25",
   Callback = function(Text)
       local n = tonumber(Text)
       if n then _G.HitboxSize = n end
   end,
})

Tab:CreateSection("Filtro de Círculo")

Tab:CreateToggle({
   Name = "Usar Círculo",
   CurrentValue = false,
   Callback = function(Value) _G.CircleEnabled = Value end,
})

Tab:CreateInput({
   Name = "Tamanho da bola",
   PlaceholderText = "Ex: 150",
   Callback = function(Text)
       local n = tonumber(Text)
       if n then _G.CircleSize = n end
   end,
})

Tab:CreateSection("Personalização")

local PlayerDrop = Tab:CreateDropdown({
   Name = "Alvo",
   Options = getPlayers(),
   CurrentOption = {"Todos"},
   Callback = function(Option) _G.TargetPlayer = Option[1] end,
})

Tab:CreateButton({
   Name = "Atualizar Lista",
   Callback = function() PlayerDrop:Refresh(getPlayers()) end,
})

Tab:CreateColorPicker({
    Name = "Cor Geral",
    Color = _G.HitboxColor,
    Callback = function(Value) _G.HitboxColor = Value end,
})

