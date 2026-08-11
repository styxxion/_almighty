-- Lag Reducer
-- DESTROY visual descendants | HarvestPart & HarvestPrompt dilindungi
-- Texture, Decal, Particle, Mesh semua dihapus dari memory

local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

local isHiding = false
local destroyedCount = 0
local connection = nil

-- [ Backup store untuk restore ]
-- Karena destroy tidak bisa di-undo, restore = rejoin atau toggle off = notice saja
-- Opsi restore: simpan CFrame + clone sebelum destroy (terlalu berat)
-- Solusi: cukup hide canCollide + destroy semua child NON-essential

-- [ Whitelist: jangan destroy ini ]
local function isProtected(obj)
    if obj.Name == "HarvestPart" then return true end
    if obj.Name == "FruitSpawnLocations" then return true end
    if obj.Name == "PlantRoot" then return true end
    if obj:IsA("ProximityPrompt") then return true end
    if obj:IsA("Script") then return true end
    if obj:IsA("LocalScript") then return true end
    if obj:IsA("RemoteEvent") then return true end
    if obj:IsA("RemoteFunction") then return true end
    if obj:IsA("BindableEvent") then return true end
    if obj:IsA("IntValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") or obj:IsA("NumberValue") then return true end
    if obj:IsA("ObjectValue") then return true end
    if obj:IsA("Configuration") then return true end
    if obj:IsA("Folder") and obj.Name == "FruitSpawnLocations" then return true end
    return false
end

-- [ Yang boleh di-destroy ]
local function isDestroyable(obj)
    if isProtected(obj) then return false end
    if obj:IsA("MeshPart") then return true end
    if obj:IsA("UnionOperation") then return true end
    if obj:IsA("SpecialMesh") then return true end
    if obj:IsA("Texture") then return true end
    if obj:IsA("Decal") then return true end
    if obj:IsA("ParticleEmitter") then return true end
    if obj:IsA("Trail") then return true end
    if obj:IsA("Beam") then return true end
    if obj:IsA("Light") then return true end
    if obj:IsA("SelectionBox") then return true end
    if obj:IsA("BillboardGui") then return true end
    if obj:IsA("SurfaceGui") then return true end
    if obj:IsA("Sound") then return true end
    return false
end

-- [ Handle BasePart: jangan destroy, tapi kosongkan ]
local function stripBasePart(obj)
    if obj.Name == "HarvestPart" then return end
    if obj:IsA("BasePart") then
        obj.Transparency = 1
        obj.CanCollide = false
        obj.CastShadow = false
        obj.LocalTransparencyModifier = 1
        -- Destroy semua child visual di dalam part ini
        for _, child in ipairs(obj:GetChildren()) do
            if isDestroyable(child) then
                child:Destroy()
                destroyedCount += 1
            end
        end
    end
end

local function processPlant(plant)
    -- Kumpulkan dulu baru destroy (hindari modify saat iterasi)
    local toDestroy = {}
    local toStrip = {}

    for _, obj in ipairs(plant:GetDescendants()) do
        if isProtected(obj) then continue end
        if isDestroyable(obj) then
            table.insert(toDestroy, obj)
        elseif obj:IsA("BasePart") and obj.Name ~= "HarvestPart" then
            table.insert(toStrip, obj)
        end
    end

    -- Strip BasePart dulu
    for _, obj in ipairs(toStrip) do
        pcall(stripBasePart, obj)
    end

    -- Destroy visual objects
    for _, obj in ipairs(toDestroy) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
            destroyedCount += 1
        end
    end
end

local function scanAndProcess()
    destroyedCount = 0
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then
        warn("[GAG2] Gardens tidak ditemukan")
        return
    end
    for _, plot in ipairs(gardens:GetChildren()) do
        local plantsFolder = plot:FindFirstChild("Plants")
        if plantsFolder then
            for _, plant in ipairs(plantsFolder:GetChildren()) do
                pcall(processPlant, plant)
            end
        end
    end
end

-- [ Auto-destroy saat plant baru spawn ]
local function startAutoDestroy()
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return end
    connection = gardens.DescendantAdded:Connect(function(obj)
        if not isHiding then return end
        task.wait(0.5)
        if isProtected(obj) then return end
        if isDestroyable(obj) then
            pcall(function() obj:Destroy() end)
        elseif obj:IsA("BasePart") and obj.Name ~= "HarvestPart" then
            pcall(stripBasePart, obj)
        end
    end)
end

local function stopAutoDestroy()
    if connection then connection:Disconnect(); connection = nil end
end

-- =====================
-- [ GUI ]
-- =====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Reduce Lag"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 230, 0, 200)
Frame.Position = UDim2.new(0, 20, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", Frame)
stroke.Color = Color3.fromRGB(80, 200, 120)
stroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
Title.BorderSizePixel = 0
Title.Text = "Reduce Lag"
Title.TextColor3 = Color3.fromRGB(80, 200, 120)
Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 22)
StatusLabel.Position = UDim2.new(0, 10, 0, 44)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: OFF"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

local CounterLabel = Instance.new("TextLabel")
CounterLabel.Size = UDim2.new(1, -20, 0, 20)
CounterLabel.Position = UDim2.new(0, 10, 0, 65)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = "Destroyed: 0 objects"
CounterLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
CounterLabel.TextSize = 11
CounterLabel.Font = Enum.Font.Gotham
CounterLabel.TextXAlignment = Enum.TextXAlignment.Left
CounterLabel.Parent = Frame

local NoteLabel = Instance.new("TextLabel")
NoteLabel.Size = UDim2.new(1, -20, 0, 28)
NoteLabel.Position = UDim2.new(0, 10, 0, 86)
NoteLabel.BackgroundTransparency = 1
NoteLabel.Text = "⚠ Setelah aktif, restore\nhanya via rejoin"
NoteLabel.TextColor3 = Color3.fromRGB(200, 160, 60)
NoteLabel.TextSize = 10
NoteLabel.Font = Enum.Font.Gotham
NoteLabel.TextXAlignment = Enum.TextXAlignment.Left
NoteLabel.TextWrapped = true
NoteLabel.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 38)
ToggleBtn.Position = UDim2.new(0, 10, 0, 122)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
ToggleBtn.Text = "AKTIFKAN LAG REDUCER"
ToggleBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
ToggleBtn.TextSize = 12
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = Frame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local InfoBtn = Instance.new("TextButton")
InfoBtn.Size = UDim2.new(1, -20, 0, 28)
InfoBtn.Position = UDim2.new(0, 10, 0, 166)
InfoBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
InfoBtn.Text = "Harvest tetap aktif ✓"
InfoBtn.TextColor3 = Color3.fromRGB(80, 200, 120)
InfoBtn.TextSize = 11
InfoBtn.Font = Enum.Font.Gotham
InfoBtn.BorderSizePixel = 0
InfoBtn.Active = false
InfoBtn.Parent = Frame
Instance.new("UICorner", InfoBtn).CornerRadius = UDim.new(0, 8)

ToggleBtn.MouseButton1Click:Connect(function()
    if isHiding then return end -- sekali aktif, tidak bisa di-toggle balik
    isHiding = true
    ToggleBtn.Text = "⏳ Memproses..."
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    ToggleBtn.Active = false

    task.spawn(function()
        scanAndProcess()
        startAutoDestroy()
        ToggleBtn.Text = "✓ AKTIF — " .. destroyedCount .. " obj dihapus"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        StatusLabel.Text = "Status: ON"
        StatusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
        CounterLabel.Text = "Destroyed: " .. destroyedCount .. " objects"
    end)
end)

print("[Lag Reducer] Ready — destroy mode")
