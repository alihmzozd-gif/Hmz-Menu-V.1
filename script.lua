-- Hmz V.1 - Xeno Compatible 3D Glow, White Tracers, ESP Toggle, Aimbot, FOV Circle & Wide UI Menu Script
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Settings Table
local Settings = {
    ESPEnabled = true,
    FillColor = Color3.fromRGB(255, 0, 100),
    OutlineColor = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.5,
    OutlineTransparency = 0,
    AlwaysOnTop = true,
    RainbowMode = false,
    Tracers = false,
    AimbotEnabled = false,
    AimbotKey = Enum.UserInputType.MouseButton2, -- Sağ tık
    ShowFOV = true,
    FOVRadius = 120 -- Varsayılan FOV boyutu
}

local activeHighlights = {}

-- 3D Glow Effect Application Function
local function apply3DGlow(player)
    local function setup(character)
        if not character then return end
        
        local existing = character:FindFirstChild("HmzV1Glow")
        if existing then existing:Destroy() end

        local highlight = Instance.new("Highlight")
        highlight.Name = "HmzV1Glow"
        highlight.FillColor = Settings.FillColor
        highlight.OutlineColor = Settings.OutlineColor
        highlight.FillTransparency = Settings.FillTransparency
        highlight.OutlineTransparency = Settings.OutlineTransparency
        highlight.DepthMode = Settings.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        highlight.Enabled = Settings.ESPEnabled
        highlight.Parent = character

        table.insert(activeHighlights, highlight)

        character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                for i, h in ipairs(activeHighlights) do
                    if h == highlight then
                        table.remove(activeHighlights, i)
                        break
                    end
                end
            end
        end)
    end

    if player.Character then
        setup(player.Character)
    end
    player.CharacterAdded:Connect(setup)
end

-- In-Game GUI Menu (Xeno Safe Parent Fix)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HmzV1Menu"
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Tracer UI Container & FOV Circle GUI
local TracerHolder = Instance.new("Folder")
TracerHolder.Name = "TracerHolder"
TracerHolder.Parent = ScreenGui

-- FOV Çemberi (Ekranın Ortasında Çıkan UI Çember)
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.Parent = ScreenGui
FOVCircle.BackgroundTransparency = 1
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Visible = false

local UICornerFOV = Instance.new("UICorner")
UICornerFOV.CornerRadius = UDim.new(1, 0)
UICornerFOV.Parent = FOVCircle

local UIStrokeFOV = Instance.new("UIStroke")
UIStrokeFOV.Thickness = 1.5
UIStrokeFOV.Color = Color3.fromRGB(255, 255, 255)
UIStrokeFOV.Transparency = 0.3
UIStrokeFOV.Parent = FOVCircle

-- Tracer (Line) Çizim Sistemi
local function createTracer(player)
    local tracerFrame = Instance.new("Frame")
    tracerFrame.Name = player.Name .. "_Tracer"
    tracerFrame.BackgroundTransparency = 0
    tracerFrame.BorderSizePixel = 0
    tracerFrame.Visible = false
    tracerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracerFrame.Parent = TracerHolder

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not Settings.ESPEnabled or not Settings.Tracers or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            tracerFrame.Visible = false
            return
        end

        local hrp = player.Character.HumanoidRootPart
        local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)

        if onScreen then
            local topCenter = Vector2.new(Camera.ViewportSize.X / 2, 0)
            local targetPos = Vector2.new(vector.X, vector.Y)
            local distance = (targetPos - topCenter).Magnitude
            
            tracerFrame.Size = UDim2.new(0, 2, 0, distance)
            tracerFrame.Position = UDim2.new(0, (topCenter.X + targetPos.X) / 2 - 1, 0, (topCenter.Y + targetPos.Y) / 2 - distance / 2)
            
            local angle = math.atan2(targetPos.Y - topCenter.Y, targetPos.X - topCenter.X)
            tracerFrame.Rotation = math.deg(angle) - 90
            
            tracerFrame.Visible = true
        else
            tracerFrame.Visible = false
        end
    end)

    player.Removing:Connect(function()
        connection:Disconnect()
        tracerFrame:Destroy()
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        task.spawn(function() 
            apply3DGlow(player) 
            createTracer(player)
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.spawn(function() 
            apply3DGlow(player) 
            createTracer(player)
        end)
    end
end)

-- Aimbot & FOV Kontrol Mekanizması
local aimbotActive = false
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Settings.AimbotKey or input.KeyCode == Settings.AimbotKey then
        aimbotActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.AimbotKey or input.KeyCode == Settings.AimbotKey then
        aimbotActive = false
    end
end)

RunService.RenderStepped:Connect(function()
    -- FOV Çember Güncelleme
    FOVCircle.Visible = Settings.AimbotEnabled and Settings.ShowFOV
    FOVCircle.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)

    if Settings.AimbotEnabled and aimbotActive then
        local closestPlayer = nil
        local shortestDistance = Settings.FOVRadius

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChildOfClass("Humanoid") then
                local humanoid = player.Character.Humanoid
                if humanoid.Health > 0 then
                    local head = player.Character.Head
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                        local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
                        local distance = (mousePos - targetPos).Magnitude

                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end

        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestPlayer.Character.Head.Position)
        end
    end

    -- Main Update Loop for Highlights
    local currentRainbowColor
    if Settings.RainbowMode then
        local hue = tick() % 5 / 5
        currentRainbowColor = Color3.fromHSV(hue, 1, 1)
    end

    for _, highlight in ipairs(activeHighlights) do
        if highlight and highlight.Parent then
            highlight.Enabled = Settings.ESPEnabled
            if Settings.ESPEnabled then
                if Settings.RainbowMode then
                    highlight.FillColor = currentRainbowColor
                    highlight.OutlineColor = currentRainbowColor
                else
                    highlight.FillColor = Settings.FillColor
                    highlight.OutlineColor = Settings.OutlineColor
                end
                highlight.FillTransparency = Settings.FillTransparency
                highlight.OutlineTransparency = Settings.OutlineTransparency
                highlight.DepthMode = Settings.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        end
    end
end)

-- Genişletilmiş Arayüz (Yatay Düzen)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 460, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Hmz V.1 ESP & Aimbot Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- SOL SÜTUN (ESP Ayarları)
local ESPBtn = Instance.new("TextButton")
ESPBtn.Parent = MainFrame
ESPBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
ESPBtn.Position = UDim2.new(0.03, 0, 0.15, 0)
ESPBtn.Size = UDim2.new(0, 210, 0, 28)
ESPBtn.Font = Enum.Font.SourceSans
ESPBtn.Text = "ESP: ON"
ESPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPBtn.TextSize = 14

ESPBtn.MouseButton1Click:Connect(function()
    Settings.ESPEnabled = not Settings.ESPEnabled
    ESPBtn.Text = "ESP: " .. (Settings.ESPEnabled and "ON" or "OFF")
    ESPBtn.BackgroundColor3 = Settings.ESPEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
end)

local RainbowBtn = Instance.new("TextButton")
RainbowBtn.Parent = MainFrame
RainbowBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RainbowBtn.Position = UDim2.new(0.03, 0, 0.28, 0)
RainbowBtn.Size = UDim2.new(0, 210, 0, 28)
RainbowBtn.Font = Enum.Font.SourceSans
RainbowBtn.Text = "Rainbow Mode: OFF"
RainbowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RainbowBtn.TextSize = 14

RainbowBtn.MouseButton1Click:Connect(function()
    Settings.RainbowMode = not Settings.RainbowMode
    RainbowBtn.Text = "Rainbow Mode: " .. (Settings.RainbowMode and "ON" or "OFF")
    RainbowBtn.BackgroundColor3 = Settings.RainbowMode and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
end)

local TopBtn = Instance.new("TextButton")
TopBtn.Parent = MainFrame
TopBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
TopBtn.Position = UDim2.new(0.03, 0, 0.41, 0)
TopBtn.Size = UDim2.new(0, 210, 0, 28)
TopBtn.Font = Enum.Font.SourceSans
TopBtn.Text = "Always On Top: ON"
TopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TopBtn.TextSize = 14

TopBtn.MouseButton1Click:Connect(function()
    Settings.AlwaysOnTop = not Settings.AlwaysOnTop
    TopBtn.Text = "Always On Top: " .. (Settings.AlwaysOnTop and "ON" or "OFF")
    TopBtn.BackgroundColor3 = Settings.AlwaysOnTop and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
end)

local TracerBtn = Instance.new("TextButton")
TracerBtn.Parent = MainFrame
TracerBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TracerBtn.Position = UDim2.new(0.03, 0, 0.54, 0)
TracerBtn.Size = UDim2.new(0, 210, 0, 28)
TracerBtn.Font = Enum.Font.SourceSans
TracerBtn.Text = "Tracers (Lines): OFF"
TracerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TracerBtn.TextSize = 14

TracerBtn.MouseButton1Click:Connect(function()
    Settings.Tracers = not Settings.Tracers
    TracerBtn.Text = "Tracers (Lines): " .. (Settings.Tracers and "ON" or "OFF")
    TracerBtn.BackgroundColor3 = Settings.Tracers and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
end)


-- SAĞ SÜTUN (Aimbot, FOV ve Renk Paleti)
local AimbotBtn = Instance.new("TextButton")
AimbotBtn.Parent = MainFrame
AimbotBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AimbotBtn.Position = UDim2.new(0.52, 0, 0.15, 0)
AimbotBtn.Size = UDim2.new(0, 210, 0, 28)
AimbotBtn.Font = Enum.Font.SourceSans
AimbotBtn.Text = "Aimbot (RightClick): OFF"
AimbotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotBtn.TextSize = 14

AimbotBtn.MouseButton1Click:Connect(function()
    Settings.AimbotEnabled = not Settings.AimbotEnabled
    AimbotBtn.Text = "Aimbot (RightClick): " .. (Settings.AimbotEnabled and "ON" or "OFF")
    AimbotBtn.BackgroundColor3 = Settings.AimbotEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
end)

local FOVCircleBtn = Instance.new("TextButton")
FOVCircleBtn.Parent = MainFrame
FOVCircleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
FOVCircleBtn.Position = UDim2.new(0.52, 0, 0.28, 0)
FOVCircleBtn.Size = UDim2.new(0, 210, 0, 28)
FOVCircleBtn.Font = Enum.Font.SourceSans
FOVCircleBtn.Text = "FOV Circle: ON"
FOVCircleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVCircleBtn.TextSize = 14

FOVCircleBtn.MouseButton1Click:Connect(function()
    Settings.ShowFOV = not Settings.ShowFOV
    FOVCircleBtn.Text = "FOV Circle: " .. (Settings.ShowFOV and "ON" or "OFF")
    FOVCircleBtn.BackgroundColor3 = Settings.ShowFOV and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
end)

local FOVSizeBtn = Instance.new("TextButton")
FOVSizeBtn.Parent = MainFrame
FOVSizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FOVSizeBtn.Position = UDim2.new(0.52, 0, 0.41, 0)
FOVSizeBtn.Size = UDim2.new(0, 210, 0, 28)
FOVSizeBtn.Font = Enum.Font.SourceSans
FOVSizeBtn.Text = "FOV Radius: 120"
FOVSizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FOVSizeBtn.TextSize = 14

-- FOV Boyutunu Değiştirme (Tıkladıkça büyür: 80 -> 120 -> 160 -> 200 -> 80 döner)
FOVSizeBtn.MouseButton1Click:Connect(function()
    if Settings.FOVRadius == 120 then
        Settings.FOVRadius = 160
    elseif Settings.FOVRadius == 160 then
        Settings.FOVRadius = 200
    elseif Settings.FOVRadius == 200 then
        Settings.FOVRadius = 80
    else
        Settings.FOVRadius = 120
    end
    FOVSizeBtn.Text = "FOV Radius: " .. Settings.FOVRadius
end)

local ColorTitle = Instance.new("TextLabel")
ColorTitle.Parent = MainFrame
ColorTitle.BackgroundTransparency = 1
ColorTitle.Position = UDim2.new(0.52, 0, 0.52, 0)
ColorTitle.Size = UDim2.new(0, 210, 0, 20)
ColorTitle.Font = Enum.Font.SourceSansBold
ColorTitle.Text = "Glow Color Palette"
ColorTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
ColorTitle.TextSize = 13

-- Preset Color Buttons (Sağ sütun alt kısım)
local colors = {
    {Name = "Red", Color = Color3.fromRGB(255, 0, 0), Pos = UDim2.new(0.52, 0, 0.62, 0)},
    {Name = "Green", Color = Color3.fromRGB(0, 255, 0), Pos = UDim2.new(0.74, 0, 0.62, 0)},
    {Name = "Blue", Color = Color3.fromRGB(0, 150, 255), Pos = UDim2.new(0.52, 0, 0.76, 0)},
    {Name = "Pink", Color = Color3.fromRGB(255, 0, 100), Pos = UDim2.new(0.74, 0, 0.76, 0)},
    {Name = "Yellow", Color = Color3.fromRGB(255, 255, 0), Pos = UDim2.new(0.52, 0, 0.90, 0)},
    {Name = "Purple", Color = Color3.fromRGB(150, 0, 255), Pos = UDim2.new(0.74, 0, 0.90, 0)}
}

for _, data in ipairs(colors) do
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = data.Color
    btn.Position = data.Pos
    btn.Size = UDim2.new(0, 100, 0, 24)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = data.Name
    btn.TextColor3 = Color3.fromRGB(20, 20, 20)
    btn.TextSize = 12

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        Settings.RainbowMode = false
        RainbowBtn.Text = "Rainbow Mode: OFF"
        RainbowBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        Settings.FillColor = data.Color
        Settings.OutlineColor = data.Color
    end)
end

-- Insert Key Menu Toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Insert then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
