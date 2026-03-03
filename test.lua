local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Unified Settings
local Settings = {
    AimbotEnabled = false,
    ESPEnabled = true,
    CornerBoxEnabled = false,
    FOV = 150,
    AimbotKey = Enum.UserInputType.MouseButton2, -- Default
    SmoothingFactor = 1,
    MaxDistance = 500,
    HeadOffset = Vector3.new(0, 0.5, 0),
    
    -- Colors
    FOVColor = Color3.fromRGB(255, 0, 0),
    BoxColor = Color3.fromRGB(255, 0, 0),
    HighlightColor = Color3.fromRGB(255, 170, 60),
    
    Box_Thickness = 2
}

local State = {TrackedCharacters = {}}

-- FOV Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = Settings.FOV
FOVCircle.Filled = false
FOVCircle.Color = Settings.FOVColor
FOVCircle.Thickness = 2
FOVCircle.Visible = true

-- UI Setup
local Window = Rayfield:CreateWindow({
    Name = "Gemini Premium Hub",
    LoadingTitle = "Authenticating...",
    ConfigurationSaving = {Enabled = true, FolderName = "GeminiConfigs", FileName = "UserPref"}
})

local MainTab = Window:CreateTab("Aimbot", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

--- AIMBOT TAB ---
MainTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(Value) Settings.AimbotEnabled = Value end,
})

MainTab:CreateKeybind({
    Name = "Aimbot Keybind",
    CurrentKeybind = "MouseButton2",
    HoldToInteract = true,
    Callback = function(Keybind)
        Settings.AimbotKey = Keybind
    end,
})

MainTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {0, 800},
    Increment = 10,
    CurrentValue = 150,
    Callback = function(Value) 
        Settings.FOV = Value
        FOVCircle.Radius = Value 
    end,
})

MainTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = Settings.FOVColor,
    Callback = function(Value)
        Settings.FOVColor = Value
        FOVCircle.Color = Value
    end
})

--- VISUALS TAB ---
VisualsTab:CreateToggle({
    Name = "Highlight ESP",
    CurrentValue = true,
    Callback = function(Value) Settings.ESPEnabled = Value end,
})

VisualsTab:CreateColorPicker({
    Name = "Highlight Color",
    Color = Settings.HighlightColor,
    Callback = function(Value)
        Settings.HighlightColor = Value
    end
})

VisualsTab:CreateToggle({
    Name = "Corner Box ESP",
    CurrentValue = false,
    Callback = function(Value) Settings.CornerBoxEnabled = Value end,
})

VisualsTab:CreateColorPicker({
    Name = "Corner Box Color",
    Color = Settings.BoxColor,
    Callback = function(Value)
        Settings.BoxColor = Value
    end
})

--- LOGIC FUNCTIONS ---

local function getClosestPlayer()
    local target = nil
    local dist = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToScreenPoint(p.Character.HumanoidRootPart.Position + Settings.HeadOffset)
                if onScreen then
                    local screenDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if screenDist <= Settings.FOV and screenDist < dist then
                        dist = screenDist
                        target = p.Character
                    end
                end
            end
        end
    end
    return target
end

local function CreateCornerBox(plr)
    local lines = {
        TL1 = Drawing.new("Line"), TL2 = Drawing.new("Line"),
        TR1 = Drawing.new("Line"), TR2 = Drawing.new("Line"),
        BL1 = Drawing.new("Line"), BL2 = Drawing.new("Line"),
        BR1 = Drawing.new("Line"), BR2 = Drawing.new("Line")
    }
    
    RunService.RenderStepped:Connect(function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and Settings.CornerBoxEnabled then
            local hrp = plr.Character.HumanoidRootPart
            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
            
            if visible then
                local sizeX, sizeY = 2000 / pos.Z, 3000 / pos.Z -- Adaptive sizing
                local x, y = pos.X, pos.Y
                local offset = sizeX / 4
                
                -- Top Left
                lines.TL1.From = Vector2.new(x - sizeX/2, y - sizeY/2); lines.TL1.To = Vector2.new(x - sizeX/2 + offset, y - sizeY/2)
                lines.TL2.From = Vector2.new(x - sizeX/2, y - sizeY/2); lines.TL2.To = Vector2.new(x - sizeX/2, y - sizeY/2 + offset)
                -- Top Right
                lines.TR1.From = Vector2.new(x + sizeX/2, y - sizeY/2); lines.TR1.To = Vector2.new(x + sizeX/2 - offset, y - sizeY/2)
                lines.TR2.From = Vector2.new(x + sizeX/2, y - sizeY/2); lines.TR2.To = Vector2.new(x + sizeX/2, y - sizeY/2 + offset)
                -- Bottom Left
                lines.BL1.From = Vector2.new(x - sizeX/2, y + sizeY/2); lines.BL1.To = Vector2.new(x - sizeX/2 + offset, y + sizeY/2)
                lines.BL2.From = Vector2.new(x - sizeX/2, y + sizeY/2); lines.BL2.To = Vector2.new(x - sizeX/2, y + sizeY/2 - offset)
                -- Bottom Right
                lines.BR1.From = Vector2.new(x + sizeX/2, y + sizeY/2); lines.BR1.To = Vector2.new(x + sizeX/2 - offset, y + sizeY/2)
                lines.BR2.From = Vector2.new(x + sizeX/2, y + sizeY/2); lines.BR2.To = Vector2.new(x + sizeX/2, y + sizeY/2 - offset)
                
                for _, l in pairs(lines) do 
                    l.Visible = true; l.Color = Settings.BoxColor; l.Thickness = Settings.Box_Thickness 
                end
            else
                for _, l in pairs(lines) do l.Visible = false end
            end
        else
            for _, l in pairs(lines) do l.Visible = false end
        end
    end)
end

local function applyHighlight(char)
    local highlight = Instance.new("Highlight")
    highlight.Parent = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    RunService.RenderStepped:Connect(function()
        highlight.Enabled = Settings.ESPEnabled
        highlight.OutlineColor = Settings.HighlightColor
        highlight.FillColor = Settings.HighlightColor
        highlight.FillTransparency = 0.6
    end)
end

-- Input/Aim Check
local function isKeyDown()
    if tostring(Settings.AimbotKey):find("MouseButton") then
        return UserInputService:IsMouseButtonPressed(Settings.AimbotKey)
    else
        return UserInputService:IsKeyDown(Settings.AimbotKey)
    end
end

-- Main Run Loop
RunService.RenderStepped:Connect(function()
    local target = getClosestPlayer()
    FOVCircle.Position = UserInputService:GetMouseLocation()

    if Settings.AimbotEnabled and target and isKeyDown() then
        local head = target:FindFirstChild("Head")
        if head then
            local aimPos = CFrame.new(Camera.CFrame.Position, head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(aimPos, 1 / Settings.SmoothingFactor)
        end
    end
end)

-- Initialize
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        if p.Character then applyHighlight(p.Character) end
        p.CharacterAdded:Connect(applyHighlight)
        CreateCornerBox(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(applyHighlight)
    CreateCornerBox(p)
end)
