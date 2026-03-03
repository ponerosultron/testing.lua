local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Unified Settings
local Settings = {
    -- Aimbot
    AimbotEnabled = false,
    TeamCheck = false,
    FOV = 150,
    AimbotKey = Enum.UserInputType.MouseButton2,
    SmoothingFactor = 1,
    MaxDistance = 1000,
    HeadOffset = Vector3.new(0, 0.5, 0),
    
    -- Visuals
    ESPEnabled = true,
    CornerBoxEnabled = false,
    FOVColor = Color3.fromRGB(255, 255, 255),
    BoxColor = Color3.fromRGB(255, 0, 0),
    HighlightColor = Color3.fromRGB(255, 170, 60),
    Box_Thickness = 2,

    -- Misc
    Flying = false,
    FlySpeed = 50,
    Noclip = false,
    NoclipKey = Enum.KeyCode.V
}

-- FOV Circle Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = Settings.FOV
FOVCircle.Filled = false
FOVCircle.Color = Settings.FOVColor
FOVCircle.Thickness = 1.5
FOVCircle.Visible = true

-- UI Setup
local Window = Rayfield:CreateWindow({
    Name = "Gemini Hub | Final Edition",
    LoadingTitle = "Loading All Systems...",
    ConfigurationSaving = {Enabled = true, FolderName = "GeminiConfigs", FileName = "MasterConfig"}
})

local MainTab = Window:CreateTab("Aimbot", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

--- FLY CLEANUP ---
local function StopFlying()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
        if hrp:FindFirstChild("FlyVel") then hrp.FlyVel:Destroy() end
        if hum then hum.PlatformStand = false end
    end
end

--- AIMBOT TAB ---
MainTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(Value) Settings.AimbotEnabled = Value end,
})

MainTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(Value) Settings.TeamCheck = Value end,
})

MainTab:CreateKeybind({
    Name = "Aimbot Keybind",
    CurrentKeybind = "MouseButton2",
    HoldToInteract = true,
    Callback = function(Key) Settings.AimbotKey = Key end,
})

MainTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {0, 800},
    Increment = 10,
    CurrentValue = 150,
    Callback = function(Value) Settings.FOV = Value; FOVCircle.Radius = Value end,
})

MainTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = Settings.FOVColor,
    Callback = function(Value) Settings.FOVColor = Value; FOVCircle.Color = Value end
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
    Callback = function(Value) Settings.HighlightColor = Value end
})

VisualsTab:CreateToggle({
    Name = "Corner Box ESP",
    CurrentValue = false,
    Callback = function(Value) Settings.CornerBoxEnabled = Value end,
})

VisualsTab:CreateColorPicker({
    Name = "Corner Box Color",
    Color = Settings.BoxColor,
    Callback = function(Value) Settings.BoxColor = Value end
})

--- MISC TAB ---
MiscTab:CreateToggle({
    Name = "Fly (Status)",
    CurrentValue = false,
    Callback = function(Value) 
        Settings.Flying = Value 
        if not Value then StopFlying() end
    end,
})

MiscTab:CreateKeybind({
    Name = "Fly Keybind",
    CurrentKeybind = "E",
    HoldToInteract = false,
    Callback = function()
        Settings.Flying = not Settings.Flying
        if not Settings.Flying then StopFlying() end
        Rayfield:Notify({Title = "Fly Toggle", Content = "Fly is now "..(Settings.Flying and "ON" or "OFF")})
    end,
})

MiscTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 500},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value) Settings.FlySpeed = Value end,
})

MiscTab:CreateSection("Noclip")

MiscTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value) Settings.Noclip = Value end,
})

MiscTab:CreateKeybind({
    Name = "Noclip Keybind",
    CurrentKeybind = "V",
    HoldToInteract = false,
    Callback = function()
        Settings.Noclip = not Settings.Noclip
        Rayfield:Notify({Title = "Noclip Toggle", Content = "Noclip is now "..(Settings.Noclip and "ON" or "OFF")})
    end,
})

--- CORE LOGIC ---

local function getClosestPlayer()
    local target = nil
    local dist = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
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

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    local char = LocalPlayer.Character
    
    -- Aimbot Execution
    local isAimbotKeyHeld = tostring(Settings.AimbotKey):find("MouseButton") and UserInputService:IsMouseButtonPressed(Settings.AimbotKey) or UserInputService:IsKeyDown(Settings.AimbotKey)
    if Settings.AimbotEnabled and isAimbotKeyHeld then
        local target = getClosestPlayer()
        if target and target:FindFirstChild("Head") then
            local aimPos = CFrame.new(Camera.CFrame.Position, target.Head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(aimPos, 1 / Settings.SmoothingFactor)
        end
    end

    -- Fly Execution
    if char and char:FindFirstChild("HumanoidRootPart") and Settings.Flying then
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        hum.PlatformStand = true
        
        local gyro = hrp:FindFirstChild("FlyGyro") or Instance.new("BodyGyro", hrp)
        local vel = hrp:FindFirstChild("FlyVel") or Instance.new("BodyVelocity", hrp)
        gyro.Name = "FlyGyro"
        vel.Name = "FlyVel"
        
        gyro.P = 9e4
        gyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        gyro.cframe = Camera.CFrame
        vel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        vel.Velocity = moveDir * Settings.FlySpeed
    end

    -- Noclip Execution
    if char and Settings.Noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

--- VISUAL HELPERS ---

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
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            if vis then
                local sizeX, sizeY = 2000 / pos.Z, 3000 / pos.Z
                local x, y = pos.X, pos.Y
                local o = sizeX / 4
                lines.TL1.From = Vector2.new(x-sizeX/2, y-sizeY/2); lines.TL1.To = Vector2.new(x-sizeX/2+o, y-sizeY/2)
                lines.TL2.From = Vector2.new(x-sizeX/2, y-sizeY/2); lines.TL2.To = Vector2.new(x-sizeX/2, y-sizeY/2+o)
                lines.TR1.From = Vector2.new(x+sizeX/2, y-sizeY/2); lines.TR1.To = Vector2.new(x+sizeX/2-o, y-sizeY/2)
                lines.TR2.From = Vector2.new(x+sizeX/2, y-sizeY/2); lines.TR2.To = Vector2.new(x+sizeX/2, y-sizeY/2+o)
                lines.BL1.From = Vector2.new(x-sizeX/2, y+sizeY/2); lines.BL1.To = Vector2.new(x-sizeX/2+o, y+sizeY/2)
                lines.BL2.From = Vector2.new(x-sizeX/2, y+sizeY/2); lines.BL2.To = Vector2.new(x-sizeX/2, y+sizeY/2-o)
                lines.BR1.From = Vector2.new(x+sizeX/2, y+sizeY/2); lines.BR1.To = Vector2.new(x+sizeX/2-o, y+sizeY/2)
                lines.BR2.From = Vector2.new(x+sizeX/2, y+sizeY/2); lines.BR2.To = Vector2.new(x+sizeX/2, y+sizeY/2-o)
                for _, l in pairs(lines) do l.Visible = true; l.Color = Settings.BoxColor; l.Thickness = Settings.Box_Thickness end
            else
                for _, l in pairs(lines) do l.Visible = false end
            end
        else
            for _, l in pairs(lines) do l.Visible = false end
        end
    end)
end

local function applyHighlight(char)
    local h = Instance.new("Highlight", char)
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    RunService.RenderStepped:Connect(function()
        h.Enabled = Settings.ESPEnabled
        h.FillColor = Settings.HighlightColor
        h.OutlineColor = Settings.HighlightColor
        h.FillTransparency = 0.6
    end)
end

-- Initialization
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
