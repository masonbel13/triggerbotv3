local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

-- Tạo folder lưu config
local dataFolder = player:WaitForChild("PlayerGui"):FindFirstChild("TriggerbotData")
if not dataFolder then
    dataFolder = Instance.new("Folder")
    dataFolder.Name = "TriggerbotData"
    dataFolder.Parent = player:WaitForChild("PlayerGui")
end

local function saveConfig(config)
    local json = HttpService:JSONEncode(config)
    local savedValue = dataFolder:FindFirstChild("ConfigJson")
    if not savedValue then
        savedValue = Instance.new("StringValue")
        savedValue.Name = "ConfigJson"
        savedValue.Parent = dataFolder
    end
    savedValue.Value = json
end

local function loadConfig()
    local savedValue = dataFolder:FindFirstChild("ConfigJson")
    if savedValue and savedValue.Value ~= "" then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(savedValue.Value)
        end)
        if success and type(decoded) == "table" then
            return decoded
        end
    end
    return nil
end

-- Config mặc định
local TriggerbotConfig = {
    Enabled = false,
    Delay = 0.1,
    Prediction = 0.1,
    WallCheck = true, -- Thêm tùy chọn Wall Check
}

-- Tải config đã lưu
local savedConfig = loadConfig()
if savedConfig then
    for k, v in pairs(savedConfig) do
        if TriggerbotConfig[k] ~= nil and typeof(v) == typeof(TriggerbotConfig[k]) then
            TriggerbotConfig[k] = v
        end
    end
end

-- GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false

-- Nút mở/đóng menu
local menuToggleBtn = Instance.new("TextButton", gui)
menuToggleBtn.Size = UDim2.new(0, 30, 0, 30)
menuToggleBtn.Position = UDim2.new(0, 10, 0.65, 0)
menuToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menuToggleBtn.TextColor3 = Color3.new(1, 1, 1)
menuToggleBtn.Text = "+"
menuToggleBtn.Font = Enum.Font.SourceSansBold
menuToggleBtn.TextSize = 22
menuToggleBtn.ZIndex = 10

-- Menu chính (cao hơn để chứa WallCheck)
local menuFrame = Instance.new("Frame", gui)
menuFrame.Size = UDim2.new(0, 180, 0, 150)
menuFrame.Position = UDim2.new(0, 10, 0.7, 0)
menuFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
menuFrame.BorderColor3 = Color3.new(1, 1, 1)
menuFrame.BorderSizePixel = 1
menuFrame.Visible = false

local function createLabel(text, parent, posY)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(0, 160, 0, 25)
    label.Position = UDim2.new(0, 10, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function createTextBox(defaultText, parent, posY)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(0, 160, 0, 25)
    box.Position = UDim2.new(0, 10, 0, posY + 25)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Text = tostring(defaultText)
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.SourceSans
    box.TextSize = 16
    box.PlaceholderText = "Nhập giá trị"
    box.TextXAlignment = Enum.TextXAlignment.Left
    return box
end

local delayLabel = createLabel("Delay (s):", menuFrame, 5)
local delayInput = createTextBox(TriggerbotConfig.Delay, menuFrame, 5)

local predictionLabel = createLabel("Prediction (s):", menuFrame, 55)
local predictionInput = createTextBox(TriggerbotConfig.Prediction, menuFrame, 55)

-- Nút bật/tắt Wall Check
local wallCheckBtn = Instance.new("TextButton", menuFrame)
wallCheckBtn.Size = UDim2.new(0, 160, 0, 25)
wallCheckBtn.Position = UDim2.new(0, 10, 0, 105)
wallCheckBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
wallCheckBtn.TextColor3 = Color3.new(1, 1, 1)
wallCheckBtn.Text = TriggerbotConfig.WallCheck and "WallCheck: ON" or "WallCheck: OFF"
wallCheckBtn.Font = Enum.Font.SourceSansBold
wallCheckBtn.TextSize = 16
wallCheckBtn.MouseButton1Click:Connect(function()
    TriggerbotConfig.WallCheck = not TriggerbotConfig.WallCheck
    wallCheckBtn.Text = TriggerbotConfig.WallCheck and "WallCheck: ON" or "WallCheck: OFF"
    trySave()
end)

-- Nút bật/tắt Triggerbot
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 80, 0, 35)
toggleBtn.Position = UDim2.new(0, 10, 0.6, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Text = TriggerbotConfig.Enabled and "Triggerbot ON" or "Triggerbot OFF"
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 16
toggleBtn.ZIndex = 10

menuToggleBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = not menuFrame.Visible
    menuToggleBtn.Text = menuFrame.Visible and "-" or "+"
end)

local function trySave()
    saveConfig({
        Delay = TriggerbotConfig.Delay,
        Prediction = TriggerbotConfig.Prediction,
        Enabled = TriggerbotConfig.Enabled,
        WallCheck = TriggerbotConfig.WallCheck
    })
end

delayInput.FocusLost:Connect(function(enter)
    if enter then
        local val = tonumber(delayInput.Text)
        if val and val >= 0 then
            TriggerbotConfig.Delay = val
            delayInput.Text = tostring(val)
            trySave()
        else
            delayInput.Text = tostring(TriggerbotConfig.Delay)
        end
    end
end)

predictionInput.FocusLost:Connect(function(enter)
    if enter then
        local val = tonumber(predictionInput.Text)
        if val and val >= 0 then
            TriggerbotConfig.Prediction = val
            predictionInput.Text = tostring(val)
            trySave()
        else
            predictionInput.Text = tostring(TriggerbotConfig.Prediction)
        end
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    TriggerbotConfig.Enabled = not TriggerbotConfig.Enabled
    toggleBtn.Text = TriggerbotConfig.Enabled and "Triggerbot ON" or "Triggerbot OFF"
    trySave()
end)

-- Auto save loop
local lastSavedConfig = HttpService:JSONEncode(TriggerbotConfig)
task.spawn(function()
    while task.wait(2) do
        local currentConfigJson = HttpService:JSONEncode(TriggerbotConfig)
        if currentConfigJson ~= lastSavedConfig then
            saveConfig(TriggerbotConfig)
            lastSavedConfig = currentConfigJson
        end
    end
end)

local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(menuToggleBtn)
makeDraggable(menuFrame)
makeDraggable(toggleBtn)

-- Kiểm tra kẻ địch
local function isEnemy(character)
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 and Players:GetPlayerFromCharacter(character) ~= player then
        return true
    end
    return false
end

local lastShot = 0
local function doMouseClick()
    VirtualUser:CaptureController()
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    VirtualUser:Button1Down(center)
    task.wait(0.05)
    VirtualUser:Button1Up(center)
end

-- Triggerbot loop
RunService.RenderStepped:Connect(function()
    if not TriggerbotConfig.Enabled then return end
    if tick() - lastShot < TriggerbotConfig.Delay then return end

    -- Chặn khi cầm Knife
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool and string.find(tool.Name:lower(), "knife") then
        return
    end

    local centerX, centerY = camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
    local ray = camera:ViewportPointToRay(centerX, centerY)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { char }
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
    if raycastResult and raycastResult.Instance then
        local targetChar = raycastResult.Instance:FindFirstAncestorOfClass("Model")
        if isEnemy(targetChar) then
            local hrp = targetChar:FindFirstChild("HumanoidRootPart")
            if hrp then
                local predictedPos = hrp.Position + (hrp.Velocity * TriggerbotConfig.Prediction)
                local direction = (predictedPos - camera.CFrame.Position).Unit * 1000

                -- Nếu bật WallCheck thì raycast lại để kiểm tra đường đạn
                if TriggerbotConfig.WallCheck then
                    local predictedRaycast = workspace:Raycast(camera.CFrame.Position, direction, raycastParams)
                    if predictedRaycast and predictedRaycast.Instance and predictedRaycast.Instance:IsDescendantOf(targetChar) then
                        doMouseClick()
                        lastShot = tick()
                    end
                else
                    -- Không cần check tường
                    doMouseClick()
                    lastShot = tick()
                end
            end
        end
    end
end)
