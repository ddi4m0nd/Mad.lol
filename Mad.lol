local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Window = Library:CreateWindow({ Title = '                     $ Mad.lol | Beta $                     ', AutoShow = true, TabPadding = 15, MenuFadeTime = 0.2 })
local Tabs = { Main = Window:AddTab('Main'), Character = Window:AddTab('Character'), Visuals = Window:AddTab('Visuals'), Misc = Window:AddTab('Misc'), Players = Window:AddTab('Players'), ['UI Settings'] = Window:AddTab('UI Settings') }
local GunMods = Tabs.Main:AddRightGroupbox('Gun Mods')
local KillAura = Tabs.Main:AddRightGroupbox('Combat')

game.Players.LocalPlayer.Character.Humanoid.Health = 0

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

local LocalPlayer = game:GetService('Players').LocalPlayer
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


local lockedTarget = nil
local StickyAimEnabled = false
local HighlightEnabled = false
local TracerEnabled = false
local ViewTargetEnabled = false
local targetHitPart = "Head"
local targetToMouseTracer = true
local grabCheckEnabled = true
local koCheckEnabled = true
local friendCheckEnabled = false
local strafeEnabled = false
local strafeMode = "Orbit"
local strafeSpeed = 5
local strafeXOffset = 5
local predictMovementEnabled = false
local stompTargetEnabled = false
local lastPosition = nil
local oldPosition = nil
local Core = nil
local BodyVelocity = nil
local PredicTvalue = 1
local hiddenBulletsEnabled = false
local spectateStrafeEnabled = false
local AutoAmmoEnabled = false
local strafeWasEnabledBeforeAmmoBuy = false

local tracer = Drawing.new("Line")
tracer.Visible = false
tracer.Thickness = 1
tracer.Color = Color3.fromRGB(255, 255, 255)


function predictPosition(targetRoot, predictionMultiplier)
    if not targetRoot then return targetRoot.Position end
    if targetRoot.Velocity.Magnitude > 700 then
        return targetRoot.Position
    end
    return targetRoot.Position + (targetRoot.Velocity * predictionMultiplier)
end

local TargetingGroup = Tabs.Main:AddLeftGroupbox('Targeting')

TargetingGroup:AddToggle("StickyAim", {
    Text = "Sticky Aim",
    Default = false,
    Callback = function(Value)
        StickyAimEnabled = Value
        if not Value then
            lockedTarget = nil
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            targetHighlight.Enabled = false
            tracer.Visible = false
        end
    end
}):AddKeyPicker("StickyAimKeybind", {
    Default = "C",
    NoUI = false,
    Text = "Sticky Aim",
    Mode = "Toggle",
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        if lockedTarget then
            lockedTarget = nil
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            targetHighlight.Enabled = false
            tracer.Visible = false
        else
            local camera = workspace.CurrentCamera
            local mouseLocation = UserInputService:GetMouseLocation()
            local closestTarget, closestDistance = nil, math.huge

            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer ~= LocalPlayer and otherPlayer.Character and otherPlayer.Character:FindFirstChild(targetHitPart) then
                    local bodyEffects = otherPlayer.Character:FindFirstChild("BodyEffects")
                    local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
                    local isGrabbed = otherPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT")

                    if (not grabCheckEnabled or not isGrabbed) and
                       (not friendCheckEnabled or not LocalPlayer:IsFriendsWith(otherPlayer.UserId)) then

                        local targetPart = otherPlayer.Character[targetHitPart]
                        local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mouseLocation).Magnitude
                            if distance < closestDistance then
                                closestTarget = otherPlayer
                                closestDistance = distance
                            end
                        end
                    end
                end
            end

            if closestTarget then
                lockedTarget = closestTarget
            end
        end
    end
})

local Target = Tabs.Main:AddLeftGroupbox('Target')

maddieplsnomad = false

TargetingGroup:AddToggle("ViewTarget", {
    Text = "spectate",
    Default = false,
    Callback = function(Value)
        maddieplsnomad = Value
        if not Value then
            ViewTargetEnabled = false
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
}):AddKeyPicker("ViewTargetKeybind", {
    Default = "B",
    NoUI = false,
    Text = "spectate",
    Mode = "Toggle",
    Callback = function()
        if not maddieplsnomad or UserInputService:GetFocusedTextBox() then return end
        ViewTargetEnabled = not ViewTargetEnabled
        if ViewTargetEnabled and lockedTarget then
            workspace.CurrentCamera.CameraSubject = lockedTarget.Character
        else
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

TargetingGroup:AddDropdown("hp", {
    Text = "Hit Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    Default = "Head",
    Callback = function(Value)
        targetHitPart = Value
    end
})

Target:AddToggle("StrafeToggle", {
    Text = "Target Strafe",
    Default = false,
    Callback = function(Value)
        strafeEnabled = Value
        if not Value then
            if Core then
                Core:Destroy()
                Core = nil
            end
            if BodyVelocity then
                BodyVelocity:Destroy()
                BodyVelocity = nil
            end
            if oldPosition then
                LocalPlayer.Character.HumanoidRootPart.CFrame = oldPosition
                oldPosition = nil
            end
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
}):AddKeyPicker("StrafeKeybind", {
    Default = "N",
    NoUI = false,
    Text = "Strafe",
    Mode = "Toggle",
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        strafeEnabled = not strafeEnabled
        if not strafeEnabled then
            if Core then
                Core:Destroy()
                Core = nil
            end
            if BodyVelocity then
                BodyVelocity:Destroy()
                BodyVelocity = nil
            end
            if oldPosition then
                LocalPlayer.Character.HumanoidRootPart.CFrame = oldPosition
                oldPosition = nil
            end
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

Target:AddToggle("SpectateStrafe", {
    Text = "Spectate Strafe",
    Default = false,
    Callback = function(Value)
        spectateStrafeEnabled = Value
        if not Value then
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

Target:AddDropdown("StrafeMode", {
    Text = "Strafe Mode",
    Values = {"Orbit", "Random"},
    Default = "Orbit",
    Callback = function(Value)
        strafeMode = Value
    end
})

Target:AddSlider("StrafeSpeed", {
    Text = "Speed units",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        strafeSpeed = Value
    end
})

Target:AddSlider("StrafeXOffset", {
    Text = "z offset",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        strafeXOffset = Value
    end
})

Target:AddToggle("PredictMovement", {
    Text = "predict movement",
    Default = false,
    Callback = function(Value)
        predictMovementEnabled = Value
    end
})

Target:AddSlider("StrafePredictionDistance", {
    Text = "movement prediction",
    Default = 0.3,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        PredicTvalue = Value
    end
})

TargetingGroup:AddToggle("StompTarget", {
    Text = "Stomp Target",
    Default = false,
    Callback = function(Value)
        stompTargetEnabled = Value
    end
})

TargetingGroup:AddToggle("HiddenBullets", {
    Text = "invisible bullets",
    Default = false,
    Callback = function(Value)
        hiddenBulletsEnabled = Value
    end
})

TargetingGroup:AddToggle("AutoAmmo", {
    Text = "Auto Ammo",
    Default = false,
    Callback = function(Value)
        AutoAmmoEnabled = Value
    end
})

local function getCurrentGun()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    return nil
end

local function getAmmoCount(gunName)
    local inventory = LocalPlayer.DataFolder.Inventory
    local ammo = inventory:FindFirstChild(gunName)
    if ammo then
        return tonumber(ammo.Value) or 0
    end
    return 0
end

local function buyAmmo(gunName)
    local ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
    local AmmoMap = {
        ["[Revolver]"] = "12 [Revolver Ammo] - $55",
        ["[AUG]"] = "90 [AUG Ammo] - $87",
        ["[LMG]"] = "200 [LMG Ammo] - $328",
        ["[Rifle]"] = "5 [Rifle Ammo] - $273",
    }

    local ammoItemName = AmmoMap[gunName]
    if not ammoItemName then return end

    local ammoItem = ShopFolder:FindFirstChild(ammoItemName)
    if not ammoItem then return end

    local oldPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")

    if currentTool then
        currentTool.Parent = LocalPlayer.Backpack
    end

    LocalPlayer.Character.HumanoidRootPart.CFrame = ammoItem.Head.CFrame * CFrame.new(0, 3.2, 0)

    local clickDetector = ammoItem:FindFirstChild("ClickDetector")
    if clickDetector then
        for i = 1, 5 do
            fireclickdetector(clickDetector)
            task.wait(0)
        end
    end

    if currentTool then
        currentTool.Parent = LocalPlayer.Character
    end

    LocalPlayer.Character.HumanoidRootPart.CFrame = oldPosition
end

local function checkAmmoAndBuy()
    if not AutoAmmoEnabled then return end

    local gunName = getCurrentGun()
    if not gunName then return end

    local ammoCount = getAmmoCount(gunName)
    if ammoCount <= 0 then
        strafeWasEnabledBeforeAmmoBuy = strafeEnabled
        strafeEnabled = false
        if Core then
            Core:Destroy()
            Core = nil
        end
        if BodyVelocity then
            BodyVelocity:Destroy()
            BodyVelocity = nil
        end

        buyAmmo(gunName)

        if strafeWasEnabledBeforeAmmoBuy then
            strafeEnabled = true
        end
    end
end

getgenv().hitsounds = {
    ["Bubble"] = "rbxassetid://6534947588",
    ["Lazer"] = "rbxassetid://130791043",
    ["Pick"] = "rbxassetid://1347140027",
    ["Pop"] = "rbxassetid://198598793",
    ["Rust"] = "rbxassetid://1255040462",
    ["Sans"] = "rbxassetid://3188795283",
    ["Fart"] = "rbxassetid://130833677",
    ["Big"] = "rbxassetid://5332005053",
    ["Vine"] = "rbxassetid://5332680810",
    ["UwU"] = "rbxassetid://8679659744",
    ["Bruh"] = "rbxassetid://4578740568",
    ["Skeet"] = "rbxassetid://5633695679",
    ["Neverlose"] = "rbxassetid://6534948092",
    ["Fatality"] = "rbxassetid://6534947869",
    ["Bonk"] = "rbxassetid://5766898159",
    ["Minecraft"] = "rbxassetid://5869422451",
    ["Gamesense"] = "rbxassetid://4817809188",
    ["RIFK7"] = "rbxassetid://9102080552",
    ["Bamboo"] = "rbxassetid://3769434519",
    ["Crowbar"] = "rbxassetid://546410481",
    ["Weeb"] = "rbxassetid://6442965016",
    ["Beep"] = "rbxassetid://8177256015",
    ["Bambi"] = "rbxassetid://8437203821",
    ["Stone"] = "rbxassetid://3581383408",
    ["Old Fatality"] = "rbxassetid://6607142036",
    ["Click"] = "rbxassetid://8053704437",
    ["Ding"] = "rbxassetid://7149516994",
    ["Snow"] = "rbxassetid://6455527632",
    ["Laser"] = "rbxassetid://7837461331",
    ["Mario"] = "rbxassetid://2815207981",
    ["Steve"] = "rbxassetid://4965083997",
    ["Call of Duty"] = "rbxassetid://5952120301",
    ["Bat"] = "rbxassetid://3333907347",
    ["TF2 Critical"] = "rbxassetid://296102734",
    ["Saber"] = "rbxassetid://8415678813",
    ["Baimware"] = "rbxassetid://3124331820",
    ["Osu"] = "rbxassetid://7149255551",
    ["TF2"] = "rbxassetid://2868331684",
    ["Slime"] = "rbxassetid://6916371803",
    ["Among Us"] = "rbxassetid://5700183626",
    ["One"] = "rbxassetid://7380502345"
}
getgenv().selectedHitsound = "Bubble"
getgenv().hitsoundEnabled = false
getgenv().hitsoundVolume = 1

function playHitsound()
    if getgenv().hitsoundEnabled then
        local sound = Instance.new("Sound")
        sound.SoundId = getgenv().hitsounds[getgenv().selectedHitsound]
        sound.Volume = getgenv().hitsoundVolume
        sound.Parent = workspace
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

GunMods:AddToggle('hstoggle', {
    Text = 'stretch res',
    Default = false,
    Callback = function(state)
        getgenv().hitsoundEnabled = state
    end
})

GunMods:AddToggle('hstoggle', {
    Text = 'Hitsounds',
    Default = false,
    Callback = function(state)
        getgenv().Resolution = {
    [" "] = 0.65
}

local Camera = workspace.CurrentCamera
if getgenv().gg_scripters == nil then
    game:GetService("RunService").RenderStepped:Connect(
        function()
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[" "], 0, 0, 0, 1)
        end
    )
end
getgenv().gg_scripters = " "
    end
})

GunMods:AddDropdown('hs', {
    Text = 'Select Hitsound',
    Values = {"Bubble", "Lazer", "Pick", "Pop", "Rust", "Sans", "Fart", "Big", "Vine", "UwU", "Bruh", "Skeet", "Neverlose", "Fatality", "Bonk", "Minecraft", "Gamesense", "RIFK7", "Bamboo", "Crowbar", "Weeb", "Beep", "Bambi", "Stone", "Old Fatality", "Click", "Ding", "Snow", "Laser", "Mario", "Steve", "Call of Duty", "Bat", "TF2 Critical", "Saber", "Baimware", "Osu", "TF2", "Slime", "Among Us", "One"},
    Default = "Bubble",
    Callback = function(value)
        getgenv().selectedHitsound = value
    end
})

GunMods:AddSlider('hsvolume', {
    Text = 'Volume',
    Default = 1,
    Min = 1,
    Max = 5,
    Rounding = 2,
    Callback = function(value)
        getgenv().hitsoundVolume = value
    end
})

RunService.RenderStepped:Connect(function()
    checkAmmoAndBuy()

    if lockedTarget and lockedTarget.Character then
        local targetPart = lockedTarget.Character:FindFirstChild(targetHitPart)
        local bodyEffects = lockedTarget.Character:FindFirstChild("BodyEffects")
        local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
        local isGrabbed = lockedTarget.Character:FindFirstChild("GRABBING_CONSTRAINT")

        if ViewTargetEnabled then
            workspace.CurrentCamera.CameraSubject = lockedTarget.Character
        elseif spectateStrafeEnabled and strafeEnabled then
            workspace.CurrentCamera.CameraSubject = lockedTarget.Character:FindFirstChild("Head")
        end

        if strafeEnabled and targetPart and not isGrabbed then
            local targetRoot = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
            local targetPosition = targetRoot.Position

            if predictMovementEnabled then
                targetPosition = predictPosition(targetRoot, PredicTvalue)
            end

            if strafeMode == "Orbit" then
                local angle = tick() * strafeSpeed
                local offset = Vector3.new(math.cos(angle) * strafeXOffset, -0.1, math.sin(angle) * strafeXOffset)
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + offset, targetPosition)
            elseif strafeMode == "Random" then
                local offset = Vector3.new(math.random(-20, 20), math.random(-10, 10), math.random(-20, 20))
                local randomrotation = CFrame.Angles(
                    math.rad(math.random(0, 360)),
                    math.rad(math.random(0, 360)),
                    math.rad(math.random(0, 360))
                )
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + offset) * randomrotation
            end
        end

        local humanoid = lockedTarget.Character:FindFirstChild("Humanoid")
        if humanoid then
            if not getgenv().lastHealth[lockedTarget.Name] then
                getgenv().lastHealth[lockedTarget.Name] = humanoid.Health
            end
            if humanoid.Health < getgenv().lastHealth[lockedTarget.Name] then
                playHitsound()
            end
            getgenv().lastHealth[lockedTarget.Name] = humanoid.Health
        end

        if TracerEnabled and targetPart then
            tracer.Visible = true
            local camera = workspace.CurrentCamera
            local targetScreenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
            local endScreenPos

            if targetToMouseTracer then
                endScreenPos = UserInputService:GetMouseLocation()
            else
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local rootScreenPos, rootOnScreen = camera:WorldToViewportPoint(rootPart.Position)
                    if rootOnScreen then
                        endScreenPos = Vector2.new(rootScreenPos.X, rootScreenPos.Y)
                    end
                end
            end

            if onScreen and endScreenPos then
                tracer.From = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                tracer.To = endScreenPos
            else
                tracer.Visible = false
            end
        else
            tracer.Visible = false
        end

        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        if tool and handle and targetPart and not isKO and not isGrabbed then
            if hiddenBulletsEnabled then
                ReplicatedStorage.MainEvent:FireServer(
                    "ShootGun",
                    handle,
                    handle.CFrame.Position - Vector3.new(0, 10, 0),
                    targetPart.Position - Vector3.new(0, 10, 0),
                    targetPart,
                    Vector3.new(0, 0, -1))
            else
                ReplicatedStorage.MainEvent:FireServer(
                    "ShootGun",
                    handle,
                    handle.CFrame.Position,
                    targetPart.Position,
                    targetPart,
                    Vector3.new(0, 0, -1))
            end
        end
    else
        tracer.Visible = false
    end
end)

local killSayEnabled = false
local killSayMessages = {
    "mad.lol is a free script and u die to it..", 
    "Must be hard without mad.lol 💔", 
    "Why aim when mad.lol does it for you?",
    "Bros not on mad.lol already 😂",
    "Cant be me icl",
    "cant win a hvh? maybe try /madlolhvh",
    "if u wanna win hop in /madlolhvh",
    "hey come on if u cant win get mad . lol",
    "how to win a hvh? step 1 get mad . lol"
}

TargetingGroup:AddToggle("killsay", { 
    Text = "Kill Say", 
    Default = false,
    Callback = function(Value)
        killSayEnabled = Value
    end
})

task.spawn(function()
    while true do
        if stompTargetEnabled and lockedTarget and lockedTarget ~= LocalPlayer then
            local character = lockedTarget.Character
            if character then
                local bodyEffects = character:FindFirstChild("BodyEffects")
                local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
                local isSDeath = bodyEffects and bodyEffects:FindFirstChild("SDeath") and bodyEffects["SDeath"].Value

                if isKO and not isSDeath then
                    local upperTorso = character:FindFirstChild("UpperTorso")
                    if upperTorso then
                        local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                        if not lastPosition then
                            lastPosition = humanoidRootPart.Position
                        end
                        humanoidRootPart.CFrame = CFrame.new(upperTorso.Position + Vector3.new(0, 3, 0))
                        RunService.RenderStepped:Wait()
                    end
                elseif isSDeath and lastPosition then
                    if killSayEnabled then
                        local message = killSayMessages[math.random(1, #killSayMessages)]
                        game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
                    end
                    local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                    while (humanoidRootPart.Position - lastPosition).Magnitude > 5 do
                        humanoidRootPart.CFrame = CFrame.new(lastPosition)
                        task.wait()
                    end
                    lastPosition = nil
                end
            else
                if lastPosition then
                    local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                    while (humanoidRootPart.Position - lastPosition).Magnitude > 5 do
                        humanoidRootPart.CFrame = CFrame.new(lastPosition)
                        task.wait()
                    end
                    lastPosition = nil
                end
            end
            ReplicatedStorage.MainEvent:FireServer("Stomp")
        end
        task.wait(0)
    end
end)


local StarterGui = game:GetService("StarterGui")
local RapidFireEnabled = false
local hyperFireEnabled = false
local modifiedTools = {}

local function rapidfire(tool)
    if not tool or not tool:FindFirstChild("GunScript") or modifiedTools[tool] then return end

    for _, v in ipairs(getconnections(tool.Activated)) do
        local funcinfo = debug.getinfo(v.Function)
        for i = 1, funcinfo.nups do
            local c, n = debug.getupvalue(v.Function, i)
            if type(c) == "number" then
                debug.setupvalue(v.Function, i, 0.0000000000001)
            end
        end
    end

    modifiedTools[tool] = true
end

local function onCharacterAdded(character)
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
            rapidfire(tool)
        end
    end

    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child:FindFirstChild("Handle") then
            rapidfire(child)
        end
    end)
end

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

GunMods:AddToggle("RapidFireToggle", {
    Text = "Rapid Fire",
    Default = false,
    Callback = function(Value)
        RapidFireEnabled = Value
        if Value then
            modifiedTools = {}
            if LocalPlayer.Character then
                onCharacterAdded(LocalPlayer.Character)
            end
        end
    end
})

local function updateHyperFire()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj.Name == "ToleranceCooldown" and obj:IsA("ValueBase") then
            obj.Value = 0 
        end
    end
end

GunMods:AddToggle("HyperFireToggle", {
    Text = "Rapid Fire v2",
    Default = false,
    Callback = function(Value)
        hyperFireEnabled = Value
        updateHyperFire()
    end
})

game.DescendantAdded:Connect(function(obj)
    if obj.Name == "ToleranceCooldown" and obj:IsA("ValueBase") then
        obj.Value = hyperFireEnabled and 0 or 3
    end
end)

RunService.RenderStepped:Connect(function()
    if hyperFireEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local character = LocalPlayer.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Ammo") then
                tool:Activate()
            end
        end
    end
end)

local HBE = Tabs.Main:AddRightGroupbox('HBE')

local size = 10
local hitboxColor = Color3.new(0, 1, 1)
local visualizeHitbox = false
local hitboxExpanderEnabled = false
local Client = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

HBE:AddToggle('HitboxExpanderToggle', {
    Text = 'Hitbox Expander',
    Default = false,
    Callback = function(state)
        hitboxExpanderEnabled = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    resetCharacter(Player.Character)
                end
            end
        end
    end,
}):AddKeyPicker("FlightKeybindPicker", {
    Default = "L",
    Text = "Hitbox",
    Mode = "Toggle",
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then return end
        hitboxExpanderEnabled = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    resetCharacter(Player.Character)
                end
            end
        end
    end
})

HBE:AddSlider('HitboxSizeSlider', {
    Text = 'Hitbox Size',
    Default = 10,
    Min = 10,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        size = value
    end,
})

HBE:AddToggle('VisualizerToggle', {
    Text = 'Visualize',
    Default = false,
    Callback = function(state)
        visualizeHitbox = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    removeVisuals(Player.Character)
                end
            end
        end
    end,
}):AddColorPicker('HitboxColorPicker', {
    Text = 'Hitbox Color',
    Default = Color3.new(0, 1, 1),
    Callback = function(color)
        hitboxColor = color
    end,
})

local function removeVisuals(Character)
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if HRP then
        local outline = HRP:FindFirstChild("HitboxOutline")
        if outline then outline:Destroy() end
        local glow = HRP:FindFirstChild("HitboxGlow")
        if glow then glow:Destroy() end
    end
end

local function resetCharacter(Character)
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if HRP then
        -- Reset HRP size to default (2, 1, 2)
        HRP.Size = Vector3.new(2, 1, 2)
        HRP.Transparency = 1
        HRP.CanCollide = true
        removeVisuals(Character)
    end
end

local function handleCharacter(Character)
    if not Character or not hitboxExpanderEnabled then
        resetCharacter(Character)
        return
    end
    local HRP = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart", 5)
    if not HRP then return end

    HRP.Size = Vector3.new(size, size, size)
    HRP.Transparency = 1
    HRP.CanCollide = false

    if visualizeHitbox then
        local outline = HRP:FindFirstChild("HitboxOutline")
        if not outline then
            outline = Instance.new("BoxHandleAdornment")
            outline.Name = "HitboxOutline"
            outline.Adornee = HRP
            outline.Size = HRP.Size
            outline.Transparency = 0.8
            outline.ZIndex = 10
            outline.AlwaysOnTop = true
            outline.Color3 = hitboxColor
            outline.Parent = HRP

            local glow = Instance.new("BoxHandleAdornment")
            glow.Name = "HitboxGlow"
            glow.Adornee = HRP
            glow.Size = HRP.Size + Vector3.new(0.1, 0.1, 0.1)
            glow.Transparency = 0.9
            glow.ZIndex = 9
            glow.AlwaysOnTop = true
            glow.Color3 = hitboxColor
            glow.Parent = HRP
        else
            outline.Size = HRP.Size
            outline.Color3 = hitboxColor
            local glow = HRP:FindFirstChild("HitboxGlow")
            if glow then
                glow.Size = HRP.Size + Vector3.new(0.1, 0.1, 0.1)
                glow.Color3 = hitboxColor
            end
        end
    else
        removeVisuals(Character)
    end
end

local function handlePlayer(Player)
    if Player == Client then return end
    Player.CharacterAdded:Connect(function(Character)
        Character:WaitForChild("HumanoidRootPart")
        handleCharacter(Character)
    end)
    if Player.Character then
        handleCharacter(Player.Character)
    end
end

for _, Player in pairs(Players:GetPlayers()) do
    handlePlayer(Player)
end

Players.PlayerAdded:Connect(handlePlayer)

RunService.Heartbeat:Connect(function()
    if not hitboxExpanderEnabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= Client and Player.Character then
                resetCharacter(Player.Character)
            end
        end
        return
    end
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= Client and Player.Character then
            handleCharacter(Player.Character)
        end
    end
end)

local CamLockBox = Tabs.Main:AddRightGroupbox('Legit')

local camLockEnabled = false
local camLockTarget = nil
local smoothness = 0.5

CamLockBox:AddToggle('CamLockToggle', {
    Text = 'CamLock',
    Default = false,
    Callback = function(state)
        camLockEnabled = state
        if not state then
            camLockTarget = nil
        end
    end,
}):AddKeyPicker('CamLockKeybind', {
    Default = 'Q',
    Text = 'CamLock',
    Mode = 'Toggle',
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        if not camLockEnabled then return end

        if camLockTarget then
            camLockTarget = nil
        else
            local closestPlayer = nil
            local closestDistance = math.huge
            local mousePos = UserInputService:GetMouseLocation()

            for _, Player in pairs(Players:GetPlayers()) do
                if Player == LocalPlayer then continue end
                local character = Player.Character
                if character then
                    local HRP = character:FindFirstChild("Head")
                    if HRP then
                        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(HRP.Position)
                        if onScreen then
                            local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPlayer = Player
                            end
                        end
                    end
                end
            end

            camLockTarget = closestPlayer
        end
    end,
})

CamLockBox:AddInput('SmoothnessInput', {
    Default = '0.5',
    Numeric = true,
    Finished = false,
    Text = 'Smoothness',
    Tooltip = 'Controls how smoothly the camera follows the target (0 = instant)',
    Placeholder = 'Enter smoothness value...',
    Callback = function(Value)
        smoothness = tonumber(Value) or 0.5
    end
})

RunService.RenderStepped:Connect(function()
    if camLockEnabled and camLockTarget then
        local character = camLockTarget.Character
        if character then
            local HRP = character:FindFirstChild("HumanoidRootPart")
            if HRP then
                local camera = workspace.CurrentCamera
                local targetPosition = HRP.Position

                -- Get the current camera CFrame
                local currentCFrame = camera.CFrame

                -- Calculate the new look direction
                local lookVector = (targetPosition - currentCFrame.Position).Unit

                -- Smoothly interpolate the look direction
                local currentLookVector = currentCFrame.LookVector
                local smoothedLookVector = currentLookVector:Lerp(lookVector, smoothness)

                -- Update the camera's CFrame to face the smoothed direction
                camera.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + smoothedLookVector)
            end
        end
    end
end)

getgenv().range = 250

getgenv().whitelist = {}


getgenv().tracer = Instance.new("Part")
getgenv().tracer.Size = Vector3.new(0.2, 0.2, 0.2)
getgenv().tracer.Material = Enum.Material.Neon
getgenv().tracer.Color = Color3.new(1, 0, 0)
getgenv().tracer.Transparency = 1
getgenv().tracer.Anchored = true
getgenv().tracer.CanCollide = false
getgenv().tracer.Parent = workspace

getgenv().enabled = false
getgenv().active = false
getgenv().visualizeEnabled = false
getgenv().silentEnabled = false
getgenv().lastHealth = {}

KillAura:AddToggle('MainToggle', {
    Text = 'Kill Aura',
    Default = false,
    Callback = function(state)
        getgenv().enabled = state
        if not state then
            getgenv().active = false
            getgenv().tracer.Transparency = 1
        end
    end
}):AddKeyPicker('Keybind', {
    Default = 'K',
    Text = 'kill aura',
    Mode = 'Toggle',
    Callback = function(state)
        if not getgenv().enabled or UserInputService:GetFocusedTextBox() then return end
        getgenv().active = state
    end
})

KillAura:AddSlider("Range", {
    Text = "Range",
    Default = 250,
    Min = 10,
    Max = 250,
    Rounding = 1,
    Callback = function(value)
        getgenv().range = value
    end
})

KillAura:AddToggle('Visualizer', {
    Text = 'Visualize',
    Default = false,
    Callback = function(state)
        getgenv().visualizeEnabled = state
    end
}):AddColorPicker('VisualizerColor', {
    Text = 'Visualizer Color',
    Default = Color3.new(1, 0, 0),
    Callback = function(value)
        getgenv().tracer.Color = value
    end
})

KillAura:AddToggle('Silent', {
    Text = 'Silent',
    Default = false,
    Callback = function(state)
        getgenv().silentEnabled = state
    end
})

KillAura:AddInput('wlb', {
    Default = '',
    Numeric = false,
    Finished = false,
    Text = 'Add/Remove Player',
    Tooltip = 'Type a name or display name to add/remove from whitelist',
    Placeholder = 'Player Name',
    Callback = function(input)
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == input or player.DisplayName == input then
                if getgenv().whitelist[player.Name] then
                    getgenv().whitelist[player.Name] = nil
                    Library:Notify(player.Name .. " removed from whitelist.", 2)
                else
                    getgenv().whitelist[player.Name] = true
                    Library:Notify(player.Name .. " added to whitelist.", 2)
                end
                return
            end
        end
        Library:Notify("Player not found.", 2)
    end,
    Autocomplete = function(input)
        local suggestions = {}
        for _, player in pairs(game.Players:GetPlayers()) do
            if string.find(string.lower(player.Name), string.lower(input)) or string.find(string.lower(player.DisplayName), string.lower(input)) then
                table.insert(suggestions, player.Name .. " (" .. player.DisplayName .. ")")
            end
        end
        return suggestions
    end
})



task.spawn(function()
    while true do
        if getgenv().active and getgenv().enabled and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle") then
            if workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name) and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name):FindFirstChild("BodyEffects") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name).BodyEffects:FindFirstChild("K.O") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name).BodyEffects["K.O"].Value then
                task.wait()
            else
                local closest = math.huge
                target = nil

                for _, player in pairs(game.Players:GetPlayers()) do
                    if player ~= game.Players.LocalPlayer and not getgenv().whitelist[player.Name] and player.Character and player.Character:FindFirstChild("Head") and not player.Character:FindFirstChild("GRABBING_CONSTRAINT") then
                        if workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(player.Name) and workspace.Players:FindFirstChild(player.Name):FindFirstChild("BodyEffects") and workspace.Players:FindFirstChild(player.Name).BodyEffects:FindFirstChild("K.O") and not workspace.Players:FindFirstChild(player.Name).BodyEffects["K.O"].Value then
                            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.Head.Position).Magnitude
                            if dist < closest and dist <= getgenv().range then
                                closest = dist
                                target = player
                            end
                        end
                    end
                end

                if target and target.Character and target.Character:FindFirstChild("Head") then
                    if getgenv().visualizeEnabled then
                        getgenv().tracer.Transparency = 0
                        getgenv().tracer.Size = Vector3.new(0.2, 0.2, (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.Head.Position).Magnitude)
                        getgenv().tracer.CFrame = CFrame.lookAt(game.Players.LocalPlayer.Character.HumanoidRootPart.Position, target.Character.Head.Position) * CFrame.new(0, 0, -getgenv().tracer.Size.Z / 2)
                    else
                        getgenv().tracer.Transparency = 1
                    end

                    local humanoid = target.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        if not getgenv().lastHealth[target.Name] then
                            getgenv().lastHealth[target.Name] = humanoid.Health
                        end
                        if humanoid.Health < getgenv().lastHealth[target.Name] then
                            playHitsound()
                        end
                        getgenv().lastHealth[target.Name] = humanoid.Health
                    end

                    if getgenv().silentEnabled then
                        game.ReplicatedStorage.MainEvent:FireServer(
                            "ShootGun",
                            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle"),
                            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle").CFrame.Position - Vector3.new(0, 12, 0),
                            target.Character.Head.Position - Vector3.new(0, 12, 0),
                            target.Character.Head,
                            Vector3.new(0, 0, -1)
                    )
                    else
                        game.ReplicatedStorage.MainEvent:FireServer("ShootGun", game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle"), game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle").CFrame.Position, target.Character.Head.Position, target.Character.Head, Vector3.new(0, 0, -1))
                    end
                else
                    getgenv().tracer.Transparency = 1
                end
            end
        else
            getgenv().tracer.Transparency = 1
        end
        task.wait()
    end
end)

-- Configuration
getgenv().espEnabled = false
getgenv().espColor = Color3.new(1, 1, 1)
getgenv().nameESPEnabled = false
getgenv().nameColor = Color3.new(1, 1, 1) -- New: Name ESP color
getgenv().nameDisplayMode = "Username"
getgenv().nameTextSize = 14
getgenv().studsESPEnabled = false
getgenv().distanceColor = Color3.new(1, 1, 1)
getgenv().distanceTextSize = 14
getgenv().healthBarESP = false
getgenv().healthBarColor = Color3.new(0, 1, 0) -- New: Health bar color
getgenv().weaponESPEnabled = false
getgenv().weaponColor = Color3.new(1, 1, 1) -- New: Weapon ESP color
getgenv().armorBarESP = false
getgenv().armorBarColor = Color3.new(0, 0, 1) -- New: Armor bar color
getgenv().outlineEnabled = false
getgenv().penisESPEnabled = false
getgenv().penisColor = Color3.new(1, 0, 0) -- New: Penis ESP color

-- Font mapping
local fontMap = {
    ["SourceSans"] = 0
}

-- ESP Objects storage
local ESPObjects = {}

-- Get the game's camera
local Camera = workspace.CurrentCamera

-- Function to destroy ESP for a player
local function DestroyESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            obj:Remove()
        end
        ESPObjects[player] = nil
    end
end

-- Function to create ESP for a player
local function CreateESP(player)
    DestroyESP(player)

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = getgenv().espColor
    box.Visible = false
    box.ZIndex = 1

    local boxOutline = Drawing.new("Square")
    boxOutline.Thickness = 3
    boxOutline.Filled = false
    boxOutline.Color = Color3.new(0, 0, 0)
    boxOutline.Visible = false
    boxOutline.ZIndex = 0

    local username = Drawing.new("Text")
    username.Size = getgenv().nameTextSize
    username.Center = true
    username.Color = getgenv().nameColor
    username.Visible = false
    username.Font = fontMap["SourceSans"]
    username.Outline = getgenv().outlineEnabled
    username.OutlineColor = Color3.new(0, 0, 0)

    local distance = Drawing.new("Text")
    distance.Size = getgenv().distanceTextSize
    distance.Center = true
    distance.Color = getgenv().distanceColor
    distance.Visible = false
    distance.Font = fontMap["SourceSans"]
    distance.Outline = getgenv().outlineEnabled
    distance.OutlineColor = Color3.new(0, 0, 0)

    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = getgenv().healthBarColor
    healthBar.Visible = false
    healthBar.ZIndex = 1

    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Thickness = 3
    healthBarOutline.Filled = false
    healthBarOutline.Color = Color3.new(0, 0, 0)
    healthBarOutline.Visible = false
    healthBarOutline.ZIndex = 0

    local weapon = Drawing.new("Text")
    weapon.Size = getgenv().nameTextSize
    weapon.Center = true
    weapon.Color = getgenv().weaponColor
    weapon.Visible = false
    weapon.Font = fontMap["SourceSans"]
    weapon.Outline = getgenv().outlineEnabled
    weapon.OutlineColor = Color3.new(0, 0, 0)

    local armorBar = Drawing.new("Square")
    armorBar.Thickness = 1
    armorBar.Filled = true
    armorBar.Color = getgenv().armorBarColor
    armorBar.Visible = false
    armorBar.ZIndex = 1

    local armorBarOutline = Drawing.new("Square")
    armorBarOutline.Thickness = 3
    armorBarOutline.Filled = false
    armorBarOutline.Color = Color3.new(0, 0, 0)
    armorBarOutline.Visible = false
    armorBarOutline.ZIndex = 0

    local penisLine = Drawing.new("Line")
    penisLine.Thickness = 2
    penisLine.Color = getgenv().penisColor
    penisLine.Visible = false
    penisLine.ZIndex = 1

    ESPObjects[player] = {
        Box = box,
        BoxOutline = boxOutline,
        Username = username,
        Distance = distance,
        HealthBar = healthBar,
        HealthBarOutline = healthBarOutline,
        Weapon = weapon,
        ArmorBar = armorBar,
        ArmorBarOutline = armorBarOutline,
        PenisLine = penisLine
    }
end

-- Function to update ESP
local function UpdateESP()
    for player, objects in pairs(ESPObjects) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer and getgenv().espEnabled then
            local rootPart = character.HumanoidRootPart
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                local rootPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                local headPosition = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
                local footPosition = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

                if onScreen then
                    local boxHeight = math.abs(headPosition.Y - footPosition.Y)
                    local boxWidth = boxHeight / 2

                    -- Box ESP
                    objects.Box.Position = Vector2.new(rootPosition.X - boxWidth / 2, headPosition.Y)
                    objects.Box.Size = Vector2.new(boxWidth, boxHeight)
                    objects.Box.Color = getgenv().espColor
                    objects.Box.Visible = true

                    -- Box Outline
                    objects.BoxOutline.Position = Vector2.new(rootPosition.X - boxWidth / 2, headPosition.Y)
                    objects.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                    objects.BoxOutline.Visible = getgenv().outlineEnabled

                    -- Name ESP (Above the box)
                    if getgenv().nameESPEnabled then
                        local displayName
                        if getgenv().nameDisplayMode == "Username" then
                            displayName = player.Name
                        elseif getgenv().nameDisplayMode == "DisplayName" then
                            displayName = player.DisplayName
                        elseif getgenv().nameDisplayMode == "Username (DisplayName)" then
                            displayName = player.Name .. " (" .. player.DisplayName .. ")"
                        elseif getgenv().nameDisplayMode == "Username (DisplayName) [UserID]" then
                            displayName = player.Name .. " (" .. player.DisplayName .. ") [" .. player.UserId .. "]"
                        end

                        objects.Username.Position = Vector2.new(rootPosition.X, headPosition.Y - 15) -- Adjusted position
                        objects.Username.Text = displayName
                        objects.Username.Size = getgenv().nameTextSize
                        objects.Username.Font = fontMap["SourceSans"]
                        objects.Username.Visible = true
                        objects.Username.Color = getgenv().nameColor
                        objects.Username.Outline = getgenv().outlineEnabled
                    else
                        objects.Username.Visible = false
                    end

                    -- Distance ESP (Below the box)
                    if getgenv().studsESPEnabled then
                        local distanceText = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude) .. " studs"
                        objects.Distance.Position = Vector2.new(rootPosition.X, footPosition.Y + 5)
                        objects.Distance.Text = distanceText
                        objects.Distance.Size = getgenv().distanceTextSize
                        objects.Distance.Font = fontMap["SourceSans"]
                        objects.Distance.Visible = true
                        objects.Distance.Color = getgenv().distanceColor
                        objects.Distance.Outline = getgenv().outlineEnabled
                    else
                        objects.Distance.Visible = false
                    end

                    -- Health Bar ESP
                    if getgenv().healthBarESP then
                        local healthRatio = humanoid.Health / humanoid.MaxHealth
                        local barHeight = boxHeight * healthRatio
                        objects.HealthBar.Position = Vector2.new(rootPosition.X - boxWidth / 2 - 6, headPosition.Y + (boxHeight - barHeight))
                        objects.HealthBar.Size = Vector2.new(3, barHeight)
                        objects.HealthBar.Color = getgenv().healthBarColor
                        objects.HealthBar.Visible = true

                        -- Health Bar Outline
                        objects.HealthBarOutline.Position = Vector2.new(rootPosition.X - boxWidth / 2 - 6, headPosition.Y + (boxHeight - barHeight))
                        objects.HealthBarOutline.Size = Vector2.new(3, barHeight)
                        objects.HealthBarOutline.Visible = getgenv().outlineEnabled
                    else
                        objects.HealthBar.Visible = false
                        objects.HealthBarOutline.Visible = false
                    end

                    -- Weapon ESP
                    if getgenv().weaponESPEnabled then
                        local tool = character:FindFirstChildOfClass("Tool")
                        if tool then
                            objects.Weapon.Position = Vector2.new(rootPosition.X, footPosition.Y + 20)
                            objects.Weapon.Text = "" .. tool.Name .. ""
                            objects.Weapon.Size = getgenv().nameTextSize
                            objects.Weapon.Font = fontMap["SourceSans"]
                            objects.Weapon.Visible = true
                            objects.Weapon.Color = getgenv().weaponColor
                            objects.Weapon.Outline = getgenv().outlineEnabled
                        else
                            objects.Weapon.Visible = false
                        end
                    else
                        objects.Weapon.Visible = false
                    end

                    -- Armor Bar ESP
                    if getgenv().armorBarESP then
                        local dataFolder = player:FindFirstChild("DataFolder")
                        if dataFolder then
                            local information = dataFolder:FindFirstChild("Information")
                            if information then
                                local armorSave = information:FindFirstChild("ArmorSave")
                                if armorSave then
                                    local armorRatio = armorSave.Value / 130 -- Assuming max armor is 100
                                    local armorHeight = boxHeight * armorRatio
                                    objects.ArmorBar.Position = Vector2.new(rootPosition.X + boxWidth / 2 + 3, headPosition.Y + (boxHeight - armorHeight))
                                    objects.ArmorBar.Size = Vector2.new(3, armorHeight)
                                    objects.ArmorBar.Color = getgenv().armorBarColor
                                    objects.ArmorBar.Visible = true

                                    -- Armor Bar Outline
                                    objects.ArmorBarOutline.Position = Vector2.new(rootPosition.X + boxWidth / 2 + 3, headPosition.Y + (boxHeight - armorHeight))
                                    objects.ArmorBarOutline.Size = Vector2.new(3, armorHeight)
                                    objects.ArmorBarOutline.Visible = getgenv().outlineEnabled
                                else
                                    objects.ArmorBar.Visible = false
                                    objects.ArmorBarOutline.Visible = false
                                end
                            else
                                objects.ArmorBar.Visible = false
                                objects.ArmorBarOutline.Visible = false
                            end
                        else
                            objects.ArmorBar.Visible = false
                            objects.ArmorBarOutline.Visible = false
                        end
                    else
                        objects.ArmorBar.Visible = false
                        objects.ArmorBarOutline.Visible = false
                    end

                    -- Penis ESP
                    if getgenv().penisESPEnabled then
                        local pelvis = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
                        if pelvis then
                            local pelvisPosition = Camera:WorldToViewportPoint(pelvis.Position)
                            local lookVector = rootPart.CFrame.LookVector
                            local penisEndPosition = Camera:WorldToViewportPoint(pelvis.Position + lookVector * 2) -- Adjust length as needed

                            objects.PenisLine.From = Vector2.new(pelvisPosition.X, pelvisPosition.Y)
                            objects.PenisLine.To = Vector2.new(penisEndPosition.X, penisEndPosition.Y)
                            objects.PenisLine.Color = getgenv().penisColor
                            objects.PenisLine.Visible = true
                        else
                            objects.PenisLine.Visible = false
                        end
                    else
                        objects.PenisLine.Visible = false
                    end
                else
                    -- Hide all ESP elements if off-screen
                    objects.Box.Visible = false
                    objects.BoxOutline.Visible = false
                    objects.Username.Visible = false
                    objects.Distance.Visible = false
                    objects.HealthBar.Visible = false
                    objects.HealthBarOutline.Visible = false
                    objects.Weapon.Visible = false
                    objects.ArmorBar.Visible = false
                    objects.ArmorBarOutline.Visible = false
                    objects.PenisLine.Visible = false
                end
            end
        end
    end
end

-- Function to apply ESP settings
function applyESP()
    for _, objects in pairs(ESPObjects) do
        objects.Box.Visible = getgenv().espEnabled
        objects.BoxOutline.Visible = getgenv().outlineEnabled and getgenv().espEnabled
    end
end

-- Player Added/Removed Events
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        CreateESP(player)
    end)
end)

Players.PlayerRemoving:Connect(DestroyESP)

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

-- Update ESP on every frame
RunService.RenderStepped:Connect(UpdateESP)

-- UI for ESP Settings
local espUI = Tabs.Visuals:AddLeftGroupbox('ESP')

espUI:AddToggle("ESPEnabled", {
    Text = "Enable",
    Default = false,
    Callback = function(value)
        getgenv().espEnabled = value
        applyESP()
    end
}):AddColorPicker("ESPColor", {
    Text = "ESP Color",
    Default = getgenv().espColor,
    Callback = function(value)
        getgenv().espColor = value
        applyESP()
    end
})

espUI:AddToggle("name", {
    Text = "Names",
    Default = false,
    Callback = function(value)
        getgenv().nameESPEnabled = value
        applyESP()
    end
}):AddColorPicker("NameColor", {
    Text = "Name Color",
    Default = getgenv().nameColor,
    Callback = function(value)
        getgenv().nameColor = value
        applyESP()
    end
})

espUI:AddDropdown("NameDisplayMode", {
    Text = "Name Mode",
    Values = {"Username", "DisplayName", "Username (DisplayName)", "Username (DisplayName) [UserID]"},
    Default = "Username",
    Callback = function(value)
        getgenv().nameDisplayMode = value
        applyESP()
    end
})

espUI:AddToggle("HealthBarESP", {
    Text = "Health Bar",
    Default = false,
    Callback = function(value)
        getgenv().healthBarESP = value
        applyESP()
    end
}):AddColorPicker("HealthBarColor", {
    Text = "Health Bar Color",
    Default = getgenv().healthBarColor,
    Callback = function(value)
        getgenv().healthBarColor = value
        applyESP()
    end
})

espUI:AddToggle("StudsESPEnabled", {
    Text = "Distance",
    Default = false,
    Callback = function(value)
        getgenv().studsESPEnabled = value
        applyESP()
    end
}):AddColorPicker("DistanceColor", {
    Text = "Distance Color",
    Default = getgenv().distanceColor,
    Callback = function(value)
        getgenv().distanceColor = value
        applyESP()
    end
})

espUI:AddToggle("WeaponESPEnabled", {
    Text = "Weapon ESP",
    Default = false,
    Callback = function(value)
        getgenv().weaponESPEnabled = value
        applyESP()
    end
}):AddColorPicker("WeaponColor", {
    Text = "Weapon Color",
    Default = getgenv().weaponColor,
    Callback = function(value)
        getgenv().weaponColor = value
        applyESP()
    end
})

espUI:AddToggle("ArmorBarESP", {
    Text = "Armor Bar",
    Default = false,
    Callback = function(value)
        getgenv().armorBarESP = value
        applyESP()
    end
}):AddColorPicker("ArmorBarColor", {
    Text = "Armor Bar Color",
    Default = getgenv().armorBarColor,
    Callback = function(value)
        getgenv().armorBarColor = value
        applyESP()
    end
})

espUI:AddToggle("OutlineEnabled", {
    Text = "Outline",
    Default = false,
    Callback = function(value)
        getgenv().outlineEnabled = value
        applyESP()
    end
})

espUI:AddToggle("PenisESPEnabled", {
    Text = "Penis ESP",
    Default = false,
    Callback = function(value)
        getgenv().penisESPEnabled = value
        applyESP()
    end
}):AddColorPicker("PenisColor", {
    Text = "Penis Color",
    Default = getgenv().penisColor,
    Callback = function(value)
        getgenv().penisColor = value
        applyESP()
    end
})

local HudUi = Tabs.Visuals:AddLeftGroupbox('Hud Changer')

local defaultTextHP = " Health "
local defaultTextArmor = "                   Armor"
local defaultTextEnergy = "Dark Energy              "

local defaultColorHP = Color3.new(0.941176, 0.031373, 0.819608)
local defaultColorArmor = Color3.new(0.376471, 0.031373, 0.933333)
local defaultColorEnergy = Color3.new(0.768627, 0.039216, 0.952941)

local textHP, textArmor, textEnergy = defaultTextHP, defaultTextArmor, defaultTextEnergy
local colorHP, colorArmor, colorEnergy = defaultColorHP, defaultColorArmor, defaultColorEnergy

local toggleHP, toggleArmor, toggleEnergy = false, false, false

local function skibiditoilet()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = playerGui:WaitForChild("MainScreenGui").Bar

    if toggleHP then
        gui.HP.TextLabel.Text = textHP
        gui.HP.bar.BackgroundColor3 = colorHP
    end

    if toggleArmor then
        gui.Armor.TextLabel.Text = textArmor
        gui.Armor.bar.BackgroundColor3 = colorArmor
    end

    if toggleEnergy then
        gui.Energy.TextLabel.Text = textEnergy
        gui.Energy.bar.BackgroundColor3 = colorEnergy
    end
end

HudUi:AddToggle('ToggleHP', {
    Text = 'Customize Health',
    Default = false,
    Callback = function(state)
        toggleHP = state
        skibiditoilet()
    end
}):AddColorPicker('ColorHP', {
    Text = 'Health Color',
    Default = defaultColorHP,
    Callback = function(value)
        if toggleHP then colorHP = value skibiditoilet() end
    end
})

HudUi:AddInput('TextHP', {
    Text = 'Health Text',
    Default = defaultTextHP,
    Callback = function(value)
        if toggleHP then textHP = value skibiditoilet() end
    end
})

HudUi:AddToggle('ToggleArmor', {
    Text = 'Customize Armor',
    Default = false,
    Callback = function(state)
        toggleArmor = state
        skibiditoilet()
    end
}):AddColorPicker('ColorArmor', {
    Text = 'Armor Color',
    Default = defaultColorArmor,
    Callback = function(value)
        if toggleArmor then colorArmor = value skibiditoilet() end
    end
})

HudUi:AddInput('TextArmor', {
    Text = 'Armor Text',
    Default = defaultTextArmor,
    Callback = function(value)
        if toggleArmor then textArmor = value skibiditoilet() end
    end
})

HudUi:AddToggle('ToggleEnergy', {
    Text = 'Customize Energy',
    Default = false,
    Callback = function(state)
        toggleEnergy = state
        skibiditoilet()
    end
}):AddColorPicker('ColorEnergy', {
    Text = 'Energy Color',
    Default = defaultColorEnergy,
    Callback = function(value)
        if toggleEnergy then colorEnergy = value skibiditoilet() end
    end
})

HudUi:AddInput('TextEnergy', {
    Text = 'Energy Text',
    Default = defaultTextEnergy,
    Callback = function(value)
        if toggleEnergy then textEnergy = value skibiditoilet() end
    end
})

local player = game.Players.LocalPlayer

player.CharacterAdded:Connect(function()
    if toggleHP or toggleArmor or toggleEnergy then
        player:WaitForChild("PlayerGui")
        skibiditoilet()
    end
end)


local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Auras = Tabs.Visuals:AddRightGroupbox("Self")
utility = utility or {}

local Settings = {
    Visuals = {
        SelfESP = {
            Trail = {
                Color = Color3.fromRGB(255, 110, 0),
                Color2 = Color3.fromRGB(255, 0, 0), -- Second color for gradient
                LifeTime = 1.6,
                Width = 0.1
            },
            Aura = {
                Color = Color3.fromRGB(152, 0, 252)
            }
        }
    }
}

utility.trail_character = function(Bool)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    if Bool then
        if not humanoidRootPart:FindFirstChild("BlaBla") then
            local BlaBla = Instance.new("Trail", humanoidRootPart)
            BlaBla.Name = "BlaBla"
            humanoidRootPart.Material = Enum.Material.Neon

            local attachment0 = Instance.new("Attachment", humanoidRootPart)
            attachment0.Position = Vector3.new(0, 1, 0)

            local attachment1 = Instance.new("Attachment", humanoidRootPart)
            attachment1.Position = Vector3.new(0, -1, 0)

            BlaBla.Attachment0 = attachment0
            BlaBla.Attachment1 = attachment1
            BlaBla.Color = ColorSequence.new(Settings.Visuals.SelfESP.Trail.Color, Settings.Visuals.SelfESP.Trail.Color2) -- Gradient effect
            BlaBla.Lifetime = Settings.Visuals.SelfESP.Trail.LifeTime
            BlaBla.Transparency = NumberSequence.new(0, 0)
            BlaBla.LightEmission = 0.2
            BlaBla.Brightness = 10
            BlaBla.WidthScale = NumberSequence.new{
                NumberSequenceKeypoint.new(0, Settings.Visuals.SelfESP.Trail.Width),
                NumberSequenceKeypoint.new(1, 0)
            }
        end
    else
        for _, child in ipairs(humanoidRootPart:GetChildren()) do
            if child:IsA("Trail") and child.Name == 'BlaBla' then
                child:Destroy()
            end
        end
    end
end

local function onCharacterAdded(character)
    if getgenv().trailEnabled then
        utility.trail_character(true)
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

Auras:AddToggle("TrailToggle", {
    Text = "Trail",
    Default = false,
    Callback = function(state)
        getgenv().trailEnabled = state
        utility.trail_character(state)
    end
}):AddColorPicker("TrailColor", {
    Text = "Trail Color",
    Default = Settings.Visuals.SelfESP.Trail.Color,
    Callback = function(color)
        Settings.Visuals.SelfESP.Trail.Color = color
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
}):AddColorPicker("TrailColor2", {
    Text = "Trail Color 2",
    Default = Settings.Visuals.SelfESP.Trail.Color2,
    Callback = function(color)
        Settings.Visuals.SelfESP.Trail.Color2 = color
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
})

Auras:AddSlider("TrailLifetime", {
    Text = "Trail Lifetime",
    Default = 1.6,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        Settings.Visuals.SelfESP.Trail.LifeTime = value
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
})

local HitEffectModule = {
    Locals = {
        HitEffect = {
            Type = {}
        }
    }
}

local Attachment = Instance.new("Attachment")
HitEffectModule.Locals.HitEffect.Type["Skibidi RedRizz"] = Attachment
local swirl = Instance.new("ParticleEmitter", Attachment)
swirl.Name = "swirl"
swirl.Lifetime = NumberRange.new(2)
swirl.SpreadAngle = Vector2.new(-360, 360)
swirl.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1)})
swirl.LightEmission = 10
swirl.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
swirl.VelocitySpread = -360
swirl.Squash = NumberSequence.new(0)
swirl.Speed = NumberRange.new(0.01)
swirl.Size = NumberSequence.new(7)
swirl.ZOffset = -1
swirl.ShapeInOut = Enum.ParticleEmitterShapeInOut.InAndOut
swirl.Rate = 40
swirl.LockedToPart = true
swirl.Texture = "rbxassetid://10558425570"
swirl.RotSpeed = NumberRange.new(200)
swirl.Orientation = Enum.ParticleOrientation.VelocityPerpendicular

local Bolts = Instance.new("ParticleEmitter", Attachment)
Bolts.Name = "Bolts"
Bolts.Lifetime = NumberRange.new(0.333)
Bolts.LockedToPart = true
Bolts.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.88), NumberSequenceKeypoint.new(0.055, 0.98),
    NumberSequenceKeypoint.new(0.111, 0.17), NumberSequenceKeypoint.new(0.166, 0.39),
    NumberSequenceKeypoint.new(0.222, 0.12), NumberSequenceKeypoint.new(0.277, 0.92),
    NumberSequenceKeypoint.new(0.333, 0.41), NumberSequenceKeypoint.new(0.388, 0.21),
    NumberSequenceKeypoint.new(0.444, 0.78), NumberSequenceKeypoint.new(0.499, 0.23),
    NumberSequenceKeypoint.new(0.555, 0.78), NumberSequenceKeypoint.new(0.610, 0.81),
    NumberSequenceKeypoint.new(0.666, 0.91), NumberSequenceKeypoint.new(0.721, 0.87),
    NumberSequenceKeypoint.new(0.777, 0.41), NumberSequenceKeypoint.new(0.832, 0.30),
    NumberSequenceKeypoint.new(0.888, 0.16), NumberSequenceKeypoint.new(0.943, 0.39),
    NumberSequenceKeypoint.new(0.999, 0.70), NumberSequenceKeypoint.new(1, 1)
})
Bolts.LightEmission = 1
Bolts.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
Bolts.Speed = NumberRange.new(0)
Bolts.Size = NumberSequence.new(4.8)
Bolts.Rate = 12
Bolts.Texture = "rbxassetid://1084955012"
Bolts.Rotation = NumberRange.new(-180, 180)

local Bubble = Instance.new("ParticleEmitter", Attachment)
Bubble.Name = "Bubble"
Bubble.Lifetime = NumberRange.new(1)
Bubble.LockedToPart = true
Bubble.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.7), NumberSequenceKeypoint.new(1, 1)})
Bubble.LightEmission = 1
Bubble.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
Bubble.Speed = NumberRange.new(0)
Bubble.Size = NumberSequence.new(4)
Bubble.Rate = 6
Bubble.Texture = "rbxassetid://1084955488"
Bubble.Rotation = NumberRange.new(-180, 180)

local function applyAura(auraName)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    Attachment.Parent = humanoidRootPart

    if getgenv().auraEnabled then
        swirl.Enabled = auraName == "Skibidi RedRizz"
        Bolts.Enabled = auraName == "Bolts"
        Bubble.Enabled = auraName == "Bubble"
        humanoidRootPart.Material = Enum.Material.Neon
    else
        swirl.Enabled = false
        Bolts.Enabled = false
        Bubble.Enabled = false
    end
end

local function onCharacterAdded(character)
    if getgenv().auraEnabled then
        applyAura(getgenv().selectedAura or "Skibidi RedRizz")
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

Auras:AddToggle("AuraToggle", {
    Text = "Auras",
    Default = false,
    Callback = function(state)
        getgenv().auraEnabled = state
        applyAura(getgenv().selectedAura or "Skibidi RedRizz")
    end
}):AddColorPicker("AuraColor", {
    Text = "Aura Color",
    Default = Settings.Visuals.SelfESP.Aura.Color,
    Callback = function(color)
        Settings.Visuals.SelfESP.Aura.Color = color
        swirl.Color = ColorSequence.new(color)
        Bolts.Color = ColorSequence.new(color)
        Bubble.Color = ColorSequence.new(color)
        if getgenv().auraEnabled then
            applyAura(getgenv().selectedAura or "Skibidi RedRizz")
        end
    end
})

Auras:AddDropdown("AuraType", {
    Text = "Select Aura",
    Values = {"Skibidi RedRizz", "Bolts", "Bubble"},
    Default = "Bubble",
    Callback = function(selected)
        getgenv().selectedAura = selected
        if getgenv().auraEnabled then
            applyAura(selected)
        end
    end
})

local targetstuffyh = Tabs.Visuals:AddLeftGroupbox('target visuals')

targetstuffyh:AddToggle("TracerToggle", {
    Text = "Draw Tracer",
    Default = false,
    Callback = function(Value)
        TracerEnabled = Value
        if not Value then
            tracer.Visible = false
        end
    end
}):AddColorPicker('HitboxColorPicker', {
    Text = '',
    Default = Color3.new(0, 1, 1),
    Callback = function(color)
        tracer.Color = color
    end,
})

targetstuffyh:AddDropdown("TracerMode", {
    Text = "Tracer Mode",
    Values = {"Mouse", "HumanoidRootPart"},
    Default = "Mouse",
    Callback = function(Value)
        targetToMouseTracer = (Value == "Mouse")
    end
})

getgenv().envt = Tabs.Visuals:AddRightGroupbox("Environment")

getgenv().Lighting = game:GetService("Lighting")

-- Get current game values as defaults
getgenv().DefaultFogStart = Lighting.FogStart
getgenv().DefaultFogEnd = Lighting.FogEnd
getgenv().DefaultFogColor = Lighting.FogColor
getgenv().DefaultAmbient = Lighting.Ambient
getgenv().DefaultTechnology = Lighting.Technology.Name

envt:AddToggle('FogToggle', {
    Text = 'Fog Changer',
    Default = false,

    Callback = function(Value)
        if Value then
            Lighting.FogEnd = getgenv().FogEnd or DefaultFogEnd
            Lighting.FogStart = getgenv().FogStart or DefaultFogStart
        else
            Lighting.FogEnd = DefaultFogEnd
            Lighting.FogStart = DefaultFogStart
            Lighting.FogColor = DefaultFogColor
        end
    end
}):AddColorPicker('FogColor', {
    Default = DefaultFogColor,
    Title = 'Fog Color',

    Callback = function(Value)
        Lighting.FogColor = Value
    end
})

envt:AddSlider('FogStart', {
    Text = 'Fog Start',
    Default = DefaultFogStart,
    Min = 0,
    Max = 1000,
    Rounding = 1,

    Callback = function(Value)
        getgenv().FogStart = Value
        Lighting.FogStart = Value
    end
})

envt:AddSlider('FogEnd', {
    Text = 'Fog End',
    Default = DefaultFogEnd,
    Min = 10,
    Max = 10000,
    Rounding = 1,

    Callback = function(Value)
        getgenv().FogEnd = Value
        Lighting.FogEnd = Value
    end
})

envt:AddToggle('AmbientToggle', {
    Text = 'Ambient',
    Default = false,

    Callback = function(Value)
        if Value then
            Lighting.Ambient = getgenv().AmbientColor or DefaultAmbient
        else
            Lighting.Ambient = DefaultAmbient
        end
    end
}):AddColorPicker('AmbientColor', {
    Default = DefaultAmbient,
    Title = 'Ambient Color',

    Callback = function(Value)
        getgenv().AmbientColor = Value
        Lighting.Ambient = Value
    end
})

envt:AddDropdown('LightingTech', {
    Text = 'Technology',
    Values = {'Voxel', 'Compatibility', 'ShadowMap', 'Future'},
    Default = table.find({'Voxel', 'Compatibility', 'ShadowMap', 'Future'}, DefaultTechnology) or 1,

    Callback = function(Value)
        Lighting.Technology = Enum.Technology[Value]
    end
})


getgenv().walkSpeedEnabled, getgenv().jumpPowerEnabled, getgenv().cframeSpeedEnabled = false, false, false
getgenv().walkSpeedKeybindActive, getgenv().cframeSpeedKeybindActive = false, false
getgenv().walkSpeed, getgenv().jumpPower, getgenv().cframeSpeed = 16, 50, 10

local uhhh = Tabs.Character:AddLeftGroupbox('Movement')

uhhh:AddToggle('CFrameSpeedToggle', {
    Text = 'cframe',
    Default = false,
    Callback = function(state)
        getgenv().cframeSpeedEnabled = state
        if not state then getgenv().cframeSpeedKeybindActive = false end
    end,
}):AddKeyPicker('CFrameSpeedKeybind', {
    Default = 'T',
    Text = 'Cframe',
    Mode = 'Toggle',
    Callback = function(state)
        if game:GetService("UserInputService"):GetFocusedTextBox() then return end
        if getgenv().cframeSpeedEnabled then getgenv().cframeSpeedKeybindActive = state end
    end,
})

uhhh:AddToggle('WalkSpeedToggle', {
    Text = 'WalkSpeed',
    Default = false,
    Callback = function(state)
        getgenv().walkSpeedEnabled = state
        if not state then getgenv().walkSpeedKeybindActive = false end
    end,
}):AddKeyPicker('WalkSpeedKeybind', {
    Default = 'T',
    Text = 'Velocity',
    Mode = 'Toggle',
    Callback = function(state)
        if game:GetService("UserInputService"):GetFocusedTextBox() then return end
        if getgenv().walkSpeedEnabled then getgenv().walkSpeedKeybindActive = state end
    end,
})

uhhh:AddToggle('JumpPowerToggle', {
    Text = 'JumpPower',
    Default = false,
    Callback = function(state)
        getgenv().jumpPowerEnabled = state
    end,
})

uhhh:AddSlider('WalkSpeedSlider', {
    Text = 'WalkSpeed',
    Default = 16,
    Min = 16,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        getgenv().walkSpeed = value
    end,
})

uhhh:AddSlider('JumpPowerSlider', {
    Text = 'JumpPower',
    Default = 50,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        getgenv().jumpPower = value
    end,
})

uhhh:AddSlider('CFrameSpeedSlider', {
    Text = 'Speed',
    Default = 10,
    Min = 1,
    Max = 200,
    Rounding = 1,
    Callback = function(value)
        getgenv().cframeSpeed = value
    end,
})

game:GetService('RunService').RenderStepped:Connect(function()
    local player = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChild('Humanoid')
    if not humanoid then return end
    
    humanoid.WalkSpeed = getgenv().walkSpeedEnabled and getgenv().walkSpeedKeybindActive and getgenv().walkSpeed or 16
    humanoid.JumpPower = getgenv().jumpPowerEnabled and getgenv().jumpPower or 50
end)

task.spawn(function()
    while task.wait(0) do
        local player = game.Players.LocalPlayer
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if getgenv().cframeSpeedEnabled and getgenv().cframeSpeedKeybindActive and character and humanoid and humanoid.MoveDirection.Magnitude > 0 then
            character:TranslateBy(humanoid.MoveDirection * getgenv().cframeSpeed * task.wait() * 3)
        end
    end
end)


getgenv().FlightKeybind = Enum.KeyCode.X
getgenv().FlySpeed = 50
getgenv().FlightEnabled = false
getgenv().Flying = false

local function CreateCore()
    if workspace:FindFirstChild("Core") then workspace.Core:Destroy() end
    local Core = Instance.new("Part")
    Core.Name = "Core"
    Core.Size = Vector3.new(0.05, 0.05, 0.05)
    Core.CanCollide = false
    Core.Transparency = 1
    Core.Parent = workspace
    local Weld = Instance.new("Weld", Core)
    Weld.Part0 = Core
    Weld.Part1 = LocalPlayer.Character.HumanoidRootPart
    Weld.C0 = CFrame.new(0, 0, 0)
    return Core
end

local function StartFly()
    if getgenv().Flying then return end
    getgenv().Flying = true
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
    local Core = CreateCore()
    local BV = Instance.new("BodyVelocity", Core)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Velocity = Vector3.zero
    local BG = Instance.new("BodyGyro", Core)
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.P = 9e4
    BG.CFrame = Core.CFrame
    RunService.RenderStepped:Connect(function()
        if not getgenv().Flying then return end
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        BV.Velocity = moveDirection * getgenv().FlySpeed
        BG.CFrame = camera.CFrame
    end)
end

local function StopFly()
    if not getgenv().Flying then return end
    getgenv().Flying = false
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    if workspace:FindFirstChild("Core") then workspace.Core:Destroy() end
end

uhhh:AddToggle("FlightToggle", {
    Text = "Flight",
    Default = false,
    Callback = function(state)
        getgenv().FlightEnabled = state
        if not state then StopFly() end
    end
}):AddKeyPicker("FlightKeybindPicker", {
    Default = "X",
    Text = "Flight",
    Mode = "Toggle",
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then return end
        if state and getgenv().FlightEnabled then
            StartFly()
        else
            StopFly()
        end
    end
})

uhhh:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 5000,
    Rounding = 0,
    Callback = function(value)
        getgenv().FlySpeed = value
    end
})

getgenv().SpinbotEnabled = false
getgenv().SpinSpeed = 10

local function toggleSpinbot(state)
    if state then
        if not getgenv().SpinConnection then
            getgenv().SpinConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and not getgenv().Flying then
                    LocalPlayer.Character.Humanoid.AutoRotate = false
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(getgenv().SpinSpeed), 0)
                end
            end)
        end
    else
        if getgenv().SpinConnection then
            getgenv().SpinConnection:Disconnect()
            getgenv().SpinConnection = nil
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().SpinbotEnabled then
        toggleSpinbot(true)
    end
end)

uhhh:AddToggle('SpinbotToggle', {
    Text = 'Spinbot',
    Default = false,
    Callback = function(state)
        getgenv().SpinbotEnabled = state
        toggleSpinbot(state)
    end,
}):AddKeyPicker('SpinbotKeybind', {
    Default = 'N',
    Text = 'Spinbot',
    Mode = 'Toggle',
    Callback = function(state)
        if not UserInputService:GetFocusedTextBox() and getgenv().SpinbotEnabled then
            toggleSpinbot(state)
        end
    end,
})

uhhh:AddSlider('SpinSpeedSlider', {
    Text = 'Spin Speed',
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Callback = function(value)
        getgenv().SpinSpeed = value
    end,
})

local AnimationSpeed = 1

local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://10714340543"

local animationTrack
local isPlaying = false
local flossEnabled = false

local function loadAnimationTrack(character)
    local humanoid = character:WaitForChild("Humanoid")
    animationTrack = humanoid:LoadAnimation(animation)
    animationTrack.Looped = true
    animationTrack.Priority = Enum.AnimationPriority.Action
    
    if flossEnabled then
        task.wait(0.6)
        animationTrack:Play()
        animationTrack:AdjustSpeed(AnimationSpeed)
        isPlaying = true
    end
end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
    loadAnimationTrack(character)
end)

if game:GetService("Players").LocalPlayer.Character then
    loadAnimationTrack(game:GetService("Players").LocalPlayer.Character)
end

local stutz = Tabs.Character:AddRightGroupbox('Misc')

stutz:AddToggle("FlossToggle", {
    Text = "floss",
    Default = false,
    Callback = function(state)
        flossEnabled = state
        if state and animationTrack then
            animationTrack:Play()
            animationTrack:AdjustSpeed(AnimationSpeed)
            isPlaying = true
        elseif not state and animationTrack then
            animationTrack:Stop()
            isPlaying = false
        end
    end
}):AddKeyPicker("FlossKeybindPicker", {
    Default = "V",
    Text = "Floss",
    Mode = "Toggle",
    Callback = function(key)
        if UserInputService:GetFocusedTextBox() then return end
        if flossEnabled and animationTrack then
            if isPlaying then
                animationTrack:Stop()
            else
                animationTrack:Play()
                animationTrack:AdjustSpeed(AnimationSpeed)
            end
            isPlaying = not isPlaying
        end
    end
})

stutz:AddToggle("NoClipToggle", {
    Text = "NoClip",
    Default = false,
    Callback = function(state)
        noClipEnabled = state
    end
}):AddKeyPicker("NoClipKeybindPicker", {
    Default = "J",
    Text = "NoClip",
    Mode = "Toggle",
    Callback = function(state)
        if noClipEnabled then
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Name:match("Arm") and not part.Name:match("Leg") then
                        part.CanCollide = state
                    end
                end
            end
        end
    end
})


DesyncBox = Tabs.Character:AddRightGroupbox("Anti Aim")

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

desync_setback = Instance.new("Part")
desync_setback.Name = "Desync Setback"
desync_setback.Parent = workspace
desync_setback.Size = Vector3.new(2, 2, 1)
desync_setback.CanCollide = false
desync_setback.Anchored = true
desync_setback.Transparency = 1

desync = {
    enabled = false,
    mode = "Void",
    teleportPosition = Vector3.new(0, 0, 0),
    old_position = nil,
    voidSpamActive = false,
    toggleEnabled = false
}

function resetCamera()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        end
    end
end

function toggleDesync(state)
    desync.enabled = state
    if desync.enabled then
        workspace.CurrentCamera.CameraSubject = desync_setback
        Library:Notify("Desync Enabled '" .. desync.mode .. "' Mad.lol $", 2)
    else
        resetCamera()
        Library:Notify("Desync Disabled '" .. desync.mode .. "' Mad.lol  $", 2)
    end
end

function setDesyncMode(mode)
    desync.mode = mode
end

DesyncBox:AddToggle('DesyncToggle', {
    Text = 'Anti Aim',
    Default = false,
    Callback = function(state)
        desync.toggleEnabled = state
        if not state then
            toggleDesync(false)
        end
    end,
}):AddKeyPicker('DesyncKeybind', {
    Default = 'V',
    Text = 'Desync',
    Mode = 'Toggle',
    Callback = function(state)
        if not desync.toggleEnabled or UserInputService:GetFocusedTextBox() then return end
        toggleDesync(not desync.enabled)
    end,
})

DesyncBox:AddDropdown('DesyncMethodDropdown', {
    Values = {"Destroy Cheaters", "Underground", "Void Spam", "Void"},
    Default = "Void",
    Multi = false,
    Text = 'Method',
    Callback = function(selected)
        setDesyncMode(selected)
    end
})

RunService.Heartbeat:Connect(function()
    if desync.enabled and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            desync.old_position = rootPart.CFrame

            if desync.mode == "Destroy Cheaters" then
                desync.teleportPosition = Vector3.new(11223344556677889900, 1, 1)

            elseif desync.mode == "Underground" then
                desync.teleportPosition = rootPart.Position - Vector3.new(0, 12, 0)

            elseif desync.mode == "Void Spam" then
                desync.teleportPosition = math.random(1, 2) == 1 and desync.old_position.Position or Vector3.new(
                    math.random(10000, 50000),
                    math.random(10000, 50000),
                    math.random(10000, 50000)
                )

            elseif desync.mode == "Void" then
                desync.teleportPosition = Vector3.new(
                    rootPart.Position.X + math.random(-444444, 444444),
                    rootPart.Position.Y + math.random(-444444, 444444),
                    rootPart.Position.Z + math.random(-44444, 44444)
                )
            end

            if desync.mode ~= "Rotation" then
                rootPart.CFrame = CFrame.new(desync.teleportPosition)
                workspace.CurrentCamera.CameraSubject = desync_setback

                RunService.RenderStepped:Wait()

                desync_setback.CFrame = desync.old_position * CFrame.new(0, rootPart.Size.Y / 2 + 0.5, 0)
                rootPart.CFrame = desync.old_position
            end
        end
    end
end)

local antifling = nil

stutz:AddToggle("AntiflingToggle", {
    Text = "Antifling",
    Default = false,
    Callback = function(state)
        if state then
            antifling = game:GetService("RunService").Stepped:Connect(function()
                for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                    if player ~= game.Players.LocalPlayer and player.Character then
                        for _, v in pairs(player.Character:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end
                        end
                    end
                end
            end)
        else
            if antifling then
                antifling:Disconnect()
                antifling = nil
            end
        end
    end
})


getgenv().RemoveShootAnimationsEnabled = false
getgenv().ShootAnimationIds = {
    ["rbxassetid://2807049953"] = true, 
    ["rbxassetid://2809413000"] = true, 
    ["rbxassetid://2809419094"] = true,  
    ["rbxassetid://507768375"] = true,
    ["rbxassetid://507755388"] = true,
    ["rbxassetid://2807049953"] = true,
    ["rbxassetid://2877910736"] = true 
}

getgenv().StopAnimationTracks = function(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            if getgenv().ShootAnimationIds[track.Animation.AnimationId] then
                track:Stop()
            end
        end
    end
end

getgenv().MonitorCharacter = function(character)
    character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("AnimationTrack") and getgenv().RemoveShootAnimationsEnabled then
            if getgenv().ShootAnimationIds[descendant.Animation.AnimationId] then
                descendant:Stop()
            end
        end
    end)
end

getgenv().MonitorPlayers = function()
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        local character = player.Character or player.CharacterAdded:Wait()
        getgenv().StopAnimationTracks(character)
        getgenv().MonitorCharacter(character)

        player.CharacterAdded:Connect(function(newCharacter)
            getgenv().StopAnimationTracks(newCharacter)
            getgenv().MonitorCharacter(newCharacter)
        end)
    end

    game:GetService("Players").PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            getgenv().StopAnimationTracks(character)
            getgenv().MonitorCharacter(character)
        end)
    end)
end

getgenv().MonitorAnimations = function()
    game:GetService("RunService").RenderStepped:Connect(function()
        if getgenv().RemoveShootAnimationsEnabled then
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                local character = player.Character
                if character then
                    getgenv().StopAnimationTracks(character)
                end
            end
        end
    end)
end

GunMods:AddToggle("AntiflingToggle", {
    Text = "remove shoot animations",
    Default = false,
    Callback = function(enabled)
        getgenv().RemoveShootAnimationsEnabled = enabled
        if enabled then
            getgenv().MonitorPlayers()
            task.spawn(getgenv().MonitorAnimations)
        end
    end
})


getgenv().Test = false
getgenv().SoundId = "6899466638"
getgenv().ToolEnabled = false

getgenv().CreateTool = function()
    getgenv().Tool = Instance.new("Tool")
    getgenv().Tool.RequiresHandle = false
    getgenv().Tool.Name = "[Kick]"
    getgenv().Tool.TextureId = "rbxassetid://483225199"
    getgenv().Animation = Instance.new("Animation")
    getgenv().Animation.AnimationId = "rbxassetid://2788306916"
    getgenv().Tool.Activated:Connect(function()
        getgenv().Test = true
        getgenv().Player = game.Players.LocalPlayer
        getgenv().Character = getgenv().Player.Character or getgenv().Player.CharacterAdded:Wait()
        getgenv().Humanoid = getgenv().Character:FindFirstChild("Humanoid")
        if getgenv().Humanoid then
            getgenv().AnimationTrack = getgenv().Humanoid:LoadAnimation(getgenv().Animation)
            getgenv().AnimationTrack:AdjustSpeed(3.4)
            getgenv().AnimationTrack:Play()
        end
        task.wait(0.6)
        getgenv().Boombox = game.Players.LocalPlayer.Backpack:FindFirstChild("[Boombox]")
        if getgenv().Boombox then
            getgenv().Boombox.Parent = game.Players.LocalPlayer.Character
            game:GetService("ReplicatedStorage").MainEvent:FireServer("Boombox", tonumber(getgenv().SoundId))
            getgenv().Boombox.RequiresHandle = false
            getgenv().Boombox.Parent = game.Players.LocalPlayer.Backpack
            task.wait(1)
            game:GetService("ReplicatedStorage").MainEvent:FireServer("BoomboxStop")
        else
            getgenv().Sound = Instance.new("Sound", workspace)
            getgenv().Sound.SoundId = "rbxassetid://" .. getgenv().SoundId
            getgenv().Sound:Play()
            task.wait(1)
            getgenv().Sound:Stop()
        end
        wait(1.4)
        getgenv().Test = false
    end)
    getgenv().Tool.Parent = game.Players.LocalPlayer:WaitForChild("Backpack")
end

getgenv().RemoveTool = function()
    getgenv().Player = game.Players.LocalPlayer
    getgenv().Tool = getgenv().Player.Backpack:FindFirstChild("[Kick]") or getgenv().Player.Character:FindFirstChild("[Kick]")
    if getgenv().Tool then getgenv().Tool:Destroy() end
end

game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().Test then
        getgenv().Character = game.Players.LocalPlayer.Character
        if not getgenv().Character then return end
        getgenv().HumanoidRootPart = getgenv().Character:FindFirstChild("HumanoidRootPart")
        if not getgenv().HumanoidRootPart then return end
        getgenv().originalVelocity = getgenv().HumanoidRootPart.Velocity
        getgenv().HumanoidRootPart.Velocity = Vector3.new(getgenv().HumanoidRootPart.CFrame.LookVector.X * 800, 800, getgenv().HumanoidRootPart.CFrame.LookVector.Z * 800)
        game:GetService("RunService").RenderStepped:Wait()
        getgenv().HumanoidRootPart.Velocity = getgenv().originalVelocity
    end
end)

local stuffs = Tabs.Misc:AddRightGroupbox("Stuff")

stuffs:AddToggle("ToolToggle", {
    Text = "Pqnd4 kick",
    Default = false,
    Callback = function(state)
        getgenv().ToolEnabled = state
        if state then getgenv().CreateTool() else getgenv().RemoveTool() end
    end
})

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().ToolEnabled then task.wait(1) getgenv().CreateTool() end
end)

local Modifications = Tabs.Misc:AddRightGroupbox("Modifications")

local antiStompActive = false
local flashbackActive = false
local lastPosition = nil

local function startAntiStomp()
    local RunService = game:GetService("RunService")

    local function checkAndKill()
        local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = chr:WaitForChild("Humanoid", 5)
        local bodyEffects = chr:WaitForChild("BodyEffects", 5)

        if not bodyEffects or not hum then
            warn("BodyEffects or Humanoid not found in the character!")
            return
        end

        local koValue = bodyEffects:WaitForChild("K.O", 5)
        if not koValue then
            warn("K.O value not found!")
            return
        end

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not antiStompActive then
                connection:Disconnect()
                return
            end

            if koValue.Value == true and hum.Health > 0 then
                if flashbackActive then
                    lastPosition = chr:GetPrimaryPartCFrame()
                end
                hum.Health = 0
            end
        end)
    end

    checkAndKill()

    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if antiStompActive then
            checkAndKill()

            if flashbackActive and lastPosition then
                local rootPart = newCharacter:WaitForChild("HumanoidRootPart", 5)
                if rootPart then
                    while (rootPart.Position - lastPosition.Position).Magnitude > 5 do
                        rootPart.CFrame = lastPosition
                        task.wait()
                    end
                end
                lastPosition = nil
            end
        end
    end)
end

Modifications:AddToggle('AntiStomp', {
    Text = 'Anti Stomp',
    Default = false,
    Callback = function(state)
        antiStompActive = state
        if state then
            startAntiStomp()
        end
    end,
})

Modifications:AddToggle('Flashback', {
    Text = 'Flashback',
    Default = false,
    Callback = function(state)
        flashbackActive = state
    end,
})

getgenv().XZQW_ENABLED = false
getgenv().HIDE_ANIMATIONS = false
getgenv().YRWL_Connection___ = {}
getgenv().BlockedAnimations = {
    "rbxassetid://2788289281",
    "rbxassetid://507766388",
    "rbxassetid://2788292075",
    "rbxassetid://278829075",
    "rbxassetid://4798175381",
    "rbxassetid://2953512033",
    "rbxassetid://2788309982",
    "rbxassetid://2788312709",
    "rbxassetid://2788313790",
    "rbxassetid://2788316350",
    "rbxassetid://2788315673",
    "rbxassetid://2788314837"
}


ReplicatedStorage:WaitForChild("ClientAnimations").Block.AnimationId = "rbxassetid://0"

local function startAutoBlock()
    table.insert(getgenv().YRWL_Connection___, RunService.Stepped:Connect(function()
        if getgenv().XZQW_ENABLED then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("BodyEffects") then
                local bodyEffects = character.BodyEffects
                if bodyEffects:FindFirstChild("Block") then
                    bodyEffects.Block:Destroy()
                end
                local tool = character:FindFirstChildWhichIsA("Tool")
                if tool and tool:FindFirstChild("Ammo") then
                    ReplicatedStorage.MainEvent:FireServer("Block", false)
                else
                    ReplicatedStorage.MainEvent:FireServer("Block", true)
                    wait()
                    ReplicatedStorage.MainEvent:FireServer("Block", false)
                end
            end
        end
    end))
end

local function stopAutoBlock()
    for _, connection in ipairs(getgenv().YRWL_Connection___) do
        connection:Disconnect()
    end
    table.clear(getgenv().YRWL_Connection___)
end

local function startHidingAnimations()
    RunService:BindToRenderStep("Hide - Block", 0, function()
        if getgenv().HIDE_ANIMATIONS then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    for _, animationTrack in pairs(humanoid:GetPlayingAnimationTracks()) do
                        if table.find(getgenv().BlockedAnimations, animationTrack.Animation.AnimationId) then
                            animationTrack:Stop()
                        end
                    end
                end
            end
        end
    end)
end

local function stopHidingAnimations()
    RunService:UnbindFromRenderStep("Hide - Block")
end

local RightGroupbox = Tabs.Character:AddRightGroupbox('Auto Block Settings')

RightGroupbox:AddToggle('AutoBlock', {
    Text = 'God Block',
    Default = false,

    Callback = function(state)
        getgenv().XZQW_ENABLED = state
        if state then
            startAutoBlock()
        else
            stopAutoBlock()
        end
    end,
})

local Depbox = RightGroupbox:AddDependencyBox()

Depbox:AddToggle('HideAnimations', {
    Text = 'Hide Animations',
    Default = false,

    Callback = function(state)
        getgenv().HIDE_ANIMATIONS = state
        if state then
            startHidingAnimations()
        else
            stopHidingAnimations()
        end
    end,
})

Depbox:SetupDependencies({
    { Toggles.AutoBlock, true }
})

CASH_AURA_ENABLED = false
COOLDOWN = 0.2
CASH_AURA_RANGE = 17

function GetCash()
    local Found = {}
    local Drop = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop")
    
    if Drop then
        for _, v in pairs(Drop:GetChildren()) do 
            if v.Name == "MoneyDrop" then 
                local Pos = v:GetAttribute("OriginalPos") or v.Position
                
                if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                   (Pos - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= CASH_AURA_RANGE then
                    table.insert(Found, v)
                end
            end
        end
    end
    
    return Found
end

function CashAura()
    while CASH_AURA_ENABLED do
        local Cash = GetCash()
        
        for _, v in pairs(Cash) do
            local clickDetector = v:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
            end
        end
        
        task.wait(COOLDOWN)
    end
end

Modifications:AddToggle('Cash_Aura_Toggle', {
    Text = 'Cash Aura',
    Default = false,
    Callback = function(Value)
        CASH_AURA_ENABLED = Value
        if CASH_AURA_ENABLED then
            task.spawn(CashAura)
        end
    end
})

local autoReloadEnabled = false
local reloadMethod = "Normal"

function startAutoReload()
    _G.Connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not autoReloadEnabled then
            _G.Connection:Disconnect()
            return
        end

        local tool = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        local ammo = tool and tool:FindFirstChild("Ammo")
        if ammo and ammo.Value <= (reloadMethod == "Rifle" and 1 or 0) then
            game:GetService("ReplicatedStorage").MainEvent:FireServer("Reload", tool)
            task.wait(3.7)
        end
    end)
end

Modifications:AddToggle('AntiStomp', {
    Text = 'Auto Reload',
    Default = false,

    Callback = function(state)
        autoReloadEnabled = state
        _G.AutoReloadEnabled = state
        if state then
            startAutoReload()
        end
    end,
})

Modifications:AddDropdown('MyDropdown', {
    Values = { 'Normal', 'Rifle'},
    Default = "Normal",
    Multi = false,

    Text = 'Reload Method',

    Callback = function(selected)
        reloadMethod = selected
    end
})



local AutoBuy = Tabs.Misc:AddLeftGroupbox("Shop")
local Workspace = game:GetService("Workspace")

local ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
local SelectedItem, Debounce = nil, false
local AutoBuyOnRespawn = false
local AmmoBuyCount = 0

local ShopItems = {
    "[Taco] - $2",
    "[Hamburger] - $5",
    "[Revolver] - $1421",
    "12 [Revolver Ammo] - $55",
    "90 [AUG Ammo] - $87",
    "[AUG] - $2131",
    "[Rifle] - $1694",
    "[LMG] - $4098",
    "200 [LMG Ammo] - $328",
}

AutoBuy:AddDropdown('Shop_Dropdown', {
    Values = ShopItems,
    Default = 1,
    Multi = false,
    Text = 'Select an Item',
    Callback = function(Value)
        SelectedItem = Value
    end
})

local function GetCharacterRoot()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function BuyItem(ItemName)
    if not ItemName or Debounce then return end
    Debounce = true

    local wasDesyncEnabled = desync.enabled
    if wasDesyncEnabled then
        toggleDesync(false)
        task.wait(0.1)
    end

    local RootPart = GetCharacterRoot()
    if not RootPart then 
        Library:Notify("[ERROR] No HumanoidRootPart found!", 3)
        Debounce = false
        return
    end

    local ItemModel = ShopFolder:FindFirstChild(ItemName)
    if ItemModel then
        local ClickDetector = ItemModel:FindFirstChildOfClass("ClickDetector")
        if ClickDetector then
            local OriginalPosition = RootPart.CFrame

            RootPart.CFrame = CFrame.new(ItemModel.Head.Position + Vector3.new(0, 3, 0))
            task.wait(0.2)

            fireclickdetector(ClickDetector)

            Library:Notify("Purchased: " .. ItemName, 3)

            RootPart.CFrame = OriginalPosition
        else
            Library:Notify("[ERROR] ClickDetector not found in " .. ItemName, 3)
        end
    else
        Library:Notify("[ERROR] Item not found: " .. ItemName, 3)
    end

    if wasDesyncEnabled then
        task.wait(0.2)
        toggleDesync(true)
    end

    Debounce = false
end

local function BuyAmmo()
    if not SelectedItem or Debounce then return end

    local AmmoMap = {
        ["[Revolver] - $1421"] = "12 [Revolver Ammo] - $55",
        ["[AUG] - $2131"] = "90 [AUG Ammo] - $87",
        ["[LMG] - $4098"] = "200 [LMG Ammo] - $328",
        ["[Rifle] - $1694"] = "5 [Rifle Ammo] - $273",
    }

    local AmmoItem = AmmoMap[SelectedItem]
    if AmmoItem then
        BuyItem(AmmoItem)
    else
        Library:Notify("[ERROR] No ammo available.", 3)
    end
end

local function AutoBuyOnRespawnHandler()
    if not AutoBuyOnRespawn or not SelectedItem then return end

    BuyItem(SelectedItem)

    if AmmoBuyCount < 3 then
        for i = 1, 3 do
            BuyAmmo()
            task.wait(0.5)
        end
        AmmoBuyCount = 3
    end
end

AutoBuy:AddToggle('AutoBuyOnRespawn', {
    Text = 'Auto Buy on Respawn',
    Default = false,
    Callback = function(state)
        AutoBuyOnRespawn = state
        AmmoBuyCount = 0
    end
})

local buy = AutoBuy:AddButton({
    Text = 'Buy Item',
    Func = function()
        BuyItem(SelectedItem)
    end,
    DoubleClick = false,
    Tooltip = 'Buys the selected item'
})

buy:AddButton({
    Text = 'Buy Ammo',
    Func = function()
        BuyAmmo()
    end,
    DoubleClick = false,
    Tooltip = 'Buys ammo for the selected weapon'
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
    AutoBuyOnRespawnHandler()
end)

Modifications:AddToggle('AntiVoid', {
    Text = 'Anti Void',
    Default = false,

    Callback = function(immatouchyoumaddie)
		if immatouchyoumaddie then
			workspace.FallenPartsDestroyHeight = -math.huge
		else
			Workspace.FallenPartsDestroyHeight = -50
		end
    end,
})

getgenv().autoArmorEnabled = false
getgenv().autoFArmorEnabled = false
getgenv().armorThreshold = 75
getgenv().fArmorThreshold = 75

local player = game:GetService("Players").LocalPlayer
local dataFolder = player:WaitForChild("DataFolder")
local armorInfo = dataFolder:WaitForChild("Information"):FindFirstChild("ArmorSave") or nil
local fireArmorInfo = dataFolder:WaitForChild("Information"):FindFirstChild("FireArmorSave") or nil
local armorShop = workspace.Ignored.Shop["[High-Medium Armor] - $2513"]
local fireArmorShop = workspace.Ignored.Shop["[Fire Armor] - $2623"]
local armorClickDetector = armorShop.ClickDetector
local fireArmorClickDetector = fireArmorShop.ClickDetector

local function canBuyArmor()
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health <= 1 then return false end
    local bodyEffects = character:FindFirstChild("BodyEffects")
    local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
    if isKO then return false end
    return true
end

local function teleportAndBuy(shop, clickDetector)
    local character = player.Character
    if not character or not character.PrimaryPart then return end

    local originalPosition = character.PrimaryPart.CFrame
    task.wait(0.1)

    character:SetPrimaryPartCFrame(shop.Head.CFrame * CFrame.new(0, 3.1, 0))
    task.wait(0.2)

    fireclickdetector(clickDetector)
    task.wait(0.1)

    character:SetPrimaryPartCFrame(originalPosition)
    task.wait(0.1)
end

local function buyArmor()
    if armorInfo and getgenv().autoArmorEnabled and tonumber(armorInfo.Value) < getgenv().armorThreshold and canBuyArmor() then
        local wasDesyncEnabled = desync.enabled
        if wasDesyncEnabled then
            toggleDesync(false)
        end

        teleportAndBuy(armorShop, armorClickDetector)

        if wasDesyncEnabled then
            toggleDesync(true)
        end
    end
end

local function buyFireArmor()
    if fireArmorInfo and getgenv().autoFArmorEnabled and tonumber(fireArmorInfo.Value) < getgenv().fArmorThreshold and canBuyArmor() then
        local wasDesyncEnabled = desync.enabled
        if wasDesyncEnabled then
            toggleDesync(false)
        end

        teleportAndBuy(fireArmorShop, fireArmorClickDetector)

        if wasDesyncEnabled then
            toggleDesync(true)
        end
    end
end

local function checkArmor()
    while task.wait(0.1) do
        if armorInfo then
            buyArmor()
        end
        if fireArmorInfo then
            buyFireArmor()
        end
    end
end

player.CharacterAdded:Connect(function()
    task.wait(1.4)
    checkArmor()
end)

task.spawn(checkArmor)

Modifications:AddToggle('AutoArmorToggle', {
    Text = 'Auto Armor',
    Default = false,
    Callback = function(state)
        getgenv().autoArmorEnabled = state
    end,
})

Modifications:AddSlider('ArmorThresholdSlider', {
    Text = 'Armor Threshold',
    Default = 75,
    Min = 1,
    Max = 130,
    Rounding = 0,
    Callback = function(value)
        getgenv().armorThreshold = value
    end,
})

Modifications:AddToggle('AutoFArmorToggle', {
    Text = 'Auto Fire Armor',
    Default = false,
    Callback = function(state)
        getgenv().autoFArmorEnabled = state
    end,
})

Modifications:AddSlider('FArmorThresholdSlider', {
    Text = 'Fire Armor Threshold',
    Default = 75,
    Min = 1,
    Max = 130,
    Rounding = 0,
    Callback = function(value)
        getgenv().fArmorThreshold = value
    end,
})

Modifications:AddToggle("AntiSitToggle", {
    Text = "Anti Sit",
    Default = false,
    Callback = function(state)
        getgenv().antiSitEnabled = state
        for _, seat in ipairs(workspace:GetDescendants()) do
            if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
                seat.CanTouch = not state
            end
        end

        workspace.DescendantAdded:Connect(function(seat)
            if getgenv().antiSitEnabled and (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
                seat.CanTouch = false
            end
        end)
    end
})

getgenv().AntiRPGDesyncEnabled, getgenv().GrenadeDetectionEnabled, getgenv().AntiRPGDesyncLoop = false, false, nil
local RunService, Workspace, LocalPlayer = game:GetService("RunService"), game.Workspace, game.Players.LocalPlayer

local function IsThreatNear(threatName)
    local Threat = Workspace:FindFirstChild("Ignored") and Workspace.Ignored:FindFirstChild(threatName)
    local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    return Threat and HRP and (Threat.Position - HRP.Position).Magnitude < 16
end

local function StartThreatDetection()
    if getgenv().AntiRPGDesyncLoop then return end

    getgenv().AntiRPGDesyncLoop = RunService.PostSimulation:Connect(function()
        local HRP, Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not HRP or not Humanoid then return end

        local RPGThreat = Workspace.Ignored:FindFirstChild("Model") and Workspace.Ignored.Model:FindFirstChild("Launcher")
        local GrenadeThreat = IsThreatNear("Handle")

        if (getgenv().AntiRPGDesyncEnabled and RPGThreat or getgenv().GrenadeDetectionEnabled and GrenadeThreat) then
            local Offset = Vector3.new(math.random(-100, 100), math.random(50, 150), math.random(-100, 100))
            Humanoid.CameraOffset = -Offset
            local OldCFrame = HRP.CFrame
            HRP.CFrame = CFrame.new(HRP.CFrame.Position + Offset)
            RunService.RenderStepped:Wait()
            HRP.CFrame = OldCFrame
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if getgenv().AntiRPGDesyncEnabled or getgenv().GrenadeDetectionEnabled then StartThreatDetection() end
    end)
end

local function StopThreatDetection()
    if getgenv().AntiRPGDesyncLoop then
        getgenv().AntiRPGDesyncLoop:Disconnect()
        getgenv().AntiRPGDesyncLoop = nil
    end
end

Modifications:AddToggle('RPGDetection', {
    Text = 'RPG detection',
    Default = false,
    Callback = function(state)
        getgenv().AntiRPGDesyncEnabled = state
        if state or getgenv().GrenadeDetectionEnabled then StartThreatDetection() else StopThreatDetection() end
    end,
})

Modifications:AddToggle('GrenadeDetection', {
    Text = 'grenade detection',
    Default = false,
    Callback = function(state)
        getgenv().GrenadeDetectionEnabled = state
        if state or getgenv().AntiRPGDesyncEnabled then StartThreatDetection() else StopThreatDetection() end
    end,
})

local webhook = Modifications:AddButton('Redeem Codes', function()
    local codes = {
        "RUBY", "DACARNIVAL",
       "THANKSGIVING24", "SHRIMP", "VIP", "2025", "BLOSSOM", "VALENTINES24", "ShortCake", "Beary"
   }
   local mainEvent = game:GetService("ReplicatedStorage"):WaitForChild("MainEvent") or nil

   for _, code in pairs(codes) do
       mainEvent:FireServer("EnterPromoCode", code)
       Library:Notify("Trying code: " .. code .. " mad.lol | Private", 5)
       task.wait(4.2)
   end
end)

webhook:AddButton('Force Reset', function()
    game.Players.LocalPlayer.Character.Humanoid.Health = 0
end)

Modifications:AddButton('Chat Spy', function()
    enabled = true --chat "/spy" to toggle!
    spyOnMyself = true --if true will check your messages too
    public = false --if true will chat the logs publicly (fun, risky)
    publicItalics = true --if true will use /me to stand out
    privateProperties = { --customize private logs
        Color = Color3.fromRGB(0,255,255); 
        Font = Enum.Font.SourceSansBold;
        TextSize = 18;
    }
    
    
    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
    local saymsg = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
    local getmsg = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("OnMessageDoneFiltering")
    local instance = (_G.chatSpyInstance or 0) + 1
    _G.chatSpyInstance = instance
    
    local function onChatted(p,msg)
        if _G.chatSpyInstance == instance then
            if p==player and msg:lower():sub(1,4)=="/spy" then
                enabled = not enabled
                wait(0.3)
                privateProperties.Text = "{SPY "..(enabled and "EN" or "DIS").."ABLED}"
                StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
            elseif enabled and (spyOnMyself==true or p~=player) then
                msg = msg:gsub("[\n\r]",''):gsub("\t",' '):gsub("[ ]+",' ')
                local hidden = true
                local conn = getmsg.OnClientEvent:Connect(function(packet,channel)
                    if packet.SpeakerUserId==p.UserId and packet.Message==msg:sub(#msg-#packet.Message+1) and (channel=="All" or (channel=="Team" and public==false and Players[packet.FromSpeaker].Team==player.Team)) then
                        hidden = false
                    end
                end)
                wait(1)
                conn:Disconnect()
                if hidden and enabled then
                    if public then
                        saymsg:FireServer((publicItalics and "/me " or '').."{SPY} [".. p.Name .."]: "..msg,"All")
                    else
                        privateProperties.Text = "{SPY} [".. p.Name .."]: "..msg
                        StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
                    end
                end
            end
        end
    end
    
    for _,p in ipairs(Players:GetPlayers()) do
        p.Chatted:Connect(function(msg) onChatted(p,msg) end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.Chatted:Connect(function(msg) onChatted(p,msg) end)
    end)
    privateProperties.Text = "{SPY "..(enabled and "EN" or "DIS").."ABLED}"
    StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
    if not player.PlayerGui:FindFirstChild("Chat") then wait(3) end
    local chatFrame = player.PlayerGui.Chat.Frame
    chatFrame.ChatChannelParentFrame.Visible = true
    chatFrame.ChatBarParentFrame.Position = chatFrame.ChatChannelParentFrame.Position+UDim2.new(UDim.new(),chatFrame.ChatChannelParentFrame.Size.Y)
    
end)


local flashbackBox = Tabs.Misc:AddRightGroupbox("Detection")
local antiModEnabled, checkModFriendsEnabled, groupCheckEnabled = false, false, false
local antiModMethod = "Notify"


local modList = {
    163721789, 15427717, 201454243, 822999, 63794379, 17260230, 28357488,
    93101606, 8195210, 89473551, 16917269, 85989579, 1553950697, 476537893,
    155627580, 31163456, 7200829, 25717070, 201454243, 15427717, 63794379,
    16138978, 60660789, 17260230, 16138978, 1161411094, 9125623, 11319153,
    34758833, 194109750, 35616559, 1257271138, 28885841, 23558830, 25717070,
    4255947062, 29242182, 2395613299, 3314981799, 3390225662, 2459178,
    2846299656, 2967502742, 7001683347, 7312775547, 328566086, 170526279,
    99356639, 352087139, 6074834798, 2212830051, 3944434729, 5136267958,
    84570351, 542488819, 1830168970, 3950637598, 1962396833
}

local groupIDs = {10604500, 17215700}

local function detectModerators()
    while antiModEnabled do
        task.wait(1)
        for _, player in ipairs(Players:GetPlayers()) do
            if table.find(modList, player.UserId) then
                local message = "⚠️ MODERATOR DETECTED: " .. player.DisplayName .. " (" .. player.Name .. ")"
                if antiModMethod == "Notify" then
                    Library:Notify(message, 3)
                else
                    game.Players.LocalPlayer:Kick("🚨 " .. message)
                end
            end

            if groupCheckEnabled then
                for _, groupID in ipairs(groupIDs) do
                    local success, isInGroup = pcall(function() return player:IsInGroup(groupID) end)
                    if success and isInGroup then
                        local roleName = "Unknown Role"
                        pcall(function()
                            roleName = player:GetRoleInGroup(groupID)
                        end)

                        local groupMessage = "⚠️ [" .. roleName .. "] JOINED: " .. player.DisplayName .. " (" .. player.Name .. ")"
                        if antiModMethod == "Notify" then
                            Library:Notify(groupMessage, 3)
                        else
                            game.Players.LocalPlayer:Kick("🚨 " .. groupMessage)
                        end
                    end
                end
            end
        end
    end
end

local function checkFriendsWithMods()
    while checkModFriendsEnabled do
        task.wait(1)
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                for _, friend in pairs(player:GetFriendsAsync():GetCurrentPage()) do
                    if table.find(modList, friend.Id) then
                        local friendMessage = "⚠️ " .. player.DisplayName .. " (" .. player.Name .. ") is friends with a Moderator!"
                        Library:Notify(friendMessage, 4)
                        break
                    end
                end
            end)
        end
    end
end

local AntiModToggle = flashbackBox:AddToggle("AntiModToggle", {
    Text = "Mod Detection",
    Default = false,
    Callback = function(Value)
        antiModEnabled = Value
        Library:Notify(antiModEnabled and "✅ Anti-Mod Enabled" or "⚠️ Anti-Mod Disabled", 3)
        if antiModEnabled then task.spawn(detectModerators) end
    end
})

local AntiModDepbox = flashbackBox:AddDependencyBox()
AntiModDepbox:SetupDependencies({ { AntiModToggle, true } })

AntiModDepbox:AddDropdown("AntiModMethod", {
    Values = {"Notify", "Kick"},
    Default = "Notify",
    Multi = false,
    Text = "Anti-Mod Method",
    Callback = function(Value)
        antiModMethod = Value
        Library:Notify("ℹ️ Anti-Mod Method set to: " .. antiModMethod, 3)
    end
})

AntiModDepbox:AddToggle("CheckModFriends", {
    Text = "Friended Checking",
    Tooltip = "Detects if any player is friends with a Moderator",
    Default = false,
    Callback = function(Value)
        checkModFriendsEnabled = Value
        Library:Notify(checkModFriendsEnabled and "✅ Checking for Mod Friends Enabled" or "⚠️ Checking for Mod Friends Disabled", 3)
        if checkModFriendsEnabled then task.spawn(checkFriendsWithMods) end
    end
})

local GroupCheckDepbox = AntiModDepbox:AddDependencyBox()
GroupCheckDepbox:SetupDependencies({ { AntiModToggle, true } })

GroupCheckDepbox:AddToggle("GroupCheck", {
    Text = "Group Role Checking",
    Tooltip = "Detects if any player is in the restricted groups",
    Default = false,
    Callback = function(Value)
        groupCheckEnabled = Value
        Library:Notify(groupCheckEnabled and "✅ Group Membership Check Enabled" or "⚠️ Group Membership Check Disabled", 3)
        if groupCheckEnabled then task.spawn(detectModerators) end
    end
})

local LeftGroupBox = Tabs.Misc:AddLeftGroupbox("Animation")

local KeepOnDeath = false

local AnimationOptions = {
    ["Idle1"] = "http://www.roblox.com/asset/?id=180435571",
    ["Idle2"] = "http://www.roblox.com/asset/?id=180435792",
    ["Walk"] = "http://www.roblox.com/asset/?id=180426354",
    ["Run"] = "http://www.roblox.com/asset/?id=180426354",
    ["Jump"] = "http://www.roblox.com/asset/?id=125750702",
    ["Climb"] = "http://www.roblox.com/asset/?id=180436334",
    ["Fall"] = "http://www.roblox.com/asset/?id=180436148"
}

local AnimationSets = {
    ["Default"] = {
        idle1 = "http://www.roblox.com/asset/?id=180435571",
        idle2 = "http://www.roblox.com/asset/?id=180435792",
        walk = "http://www.roblox.com/asset/?id=180426354",
        run = "http://www.roblox.com/asset/?id=180426354",
        jump = "http://www.roblox.com/asset/?id=125750702",
        climb = "http://www.roblox.com/asset/?id=180436334",
        fall = "http://www.roblox.com/asset/?id=180436148"
    },
    ["Ninja"] = {
        idle1 = "http://www.roblox.com/asset/?id=656117400",
        idle2 = "http://www.roblox.com/asset/?id=656118341",
        walk = "http://www.roblox.com/asset/?id=656121766",
        run = "http://www.roblox.com/asset/?id=656118852",
        jump = "http://www.roblox.com/asset/?id=656117878",
        climb = "http://www.roblox.com/asset/?id=656114359",
        fall = "http://www.roblox.com/asset/?id=656115606"
    },
    ["Superhero"] = {
        idle1 = "http://www.roblox.com/asset/?id=616111295",
        idle2 = "http://www.roblox.com/asset/?id=616113536",
        walk = "http://www.roblox.com/asset/?id=616122287",
        run = "http://www.roblox.com/asset/?id=616117076",
        jump = "http://www.roblox.com/asset/?id=616115533",
        climb = "http://www.roblox.com/asset/?id=616104706",
        fall = "http://www.roblox.com/asset/?id=616108001"
    },
    ["Robot"] = {
        idle1 = "http://www.roblox.com/asset/?id=616088211",
        idle2 = "http://www.roblox.com/asset/?id=616089559",
        walk = "http://www.roblox.com/asset/?id=616095330",
        run = "http://www.roblox.com/asset/?id=616091570",
        jump = "http://www.roblox.com/asset/?id=616090535",
        climb = "http://www.roblox.com/asset/?id=616086039",
        fall = "http://www.roblox.com/asset/?id=616087089"
    },
    ["Cartoon"] = {
        idle1 = "http://www.roblox.com/asset/?id=742637544",
        idle2 = "http://www.roblox.com/asset/?id=742638445",
        walk = "http://www.roblox.com/asset/?id=742640026",
        run = "http://www.roblox.com/asset/?id=742638842",
        jump = "http://www.roblox.com/asset/?id=742637942",
        climb = "http://www.roblox.com/asset/?id=742636889",
        fall = "http://www.roblox.com/asset/?id=742637151"
    },
    ["Catwalk"] = {
        idle1 = "http://www.roblox.com/asset/?id=133806214992291",
        idle2 = "http://www.roblox.com/asset/?id=94970088341563",
        walk = "http://www.roblox.com/asset/?id=109168724482748",
        run = "http://www.roblox.com/asset/?id=81024476153754",
        jump = "http://www.roblox.com/asset/?id=116936326516985",
        climb = "http://www.roblox.com/asset/?id=119377220967554",
        fall = "http://www.roblox.com/asset/?id=92294537340807"
    },
    ["Zombie"] = {
        idle1 = "http://www.roblox.com/asset/?id=616158929",
        idle2 = "http://www.roblox.com/asset/?id=616160636",
        walk = "http://www.roblox.com/asset/?id=616168032",
        run = "http://www.roblox.com/asset/?id=616163682",
        jump = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall = "http://www.roblox.com/asset/?id=616157476"
    },
    ["Mage"] = {
        idle1 = "http://www.roblox.com/asset/?id=707742142",
        idle2 = "http://www.roblox.com/asset/?id=707855907",
        walk = "http://www.roblox.com/asset/?id=707897309",
        run = "http://www.roblox.com/asset/?id=707861613",
        jump = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=707826056",
        fall = "http://www.roblox.com/asset/?id=707829716"
    },
    ["Pirate"] = {
        idle1 = "http://www.roblox.com/asset/?id=750785693",
        idle2 = "http://www.roblox.com/asset/?id=750782770",
        walk = "http://www.roblox.com/asset/?id=750785693",
        run = "http://www.roblox.com/asset/?id=750782770",
        jump = "http://www.roblox.com/asset/?id=750782770",
        climb = "http://www.roblox.com/asset/?id=750782770",
        fall = "http://www.roblox.com/asset/?id=750782770"
    },
    ["Knight"] = {
        idle1 = "http://www.roblox.com/asset/?id=657595757",
        idle2 = "http://www.roblox.com/asset/?id=657568135",
        walk = "http://www.roblox.com/asset/?id=657552124",
        run = "http://www.roblox.com/asset/?id=657564596",
        jump = "http://www.roblox.com/asset/?id=657560148",
        climb = "http://www.roblox.com/asset/?id=657556206",
        fall = "http://www.roblox.com/asset/?id=657552124"
    },
    ["Vampire"] = {
        idle1 = "http://www.roblox.com/asset/?id=1083465857",
        idle2 = "http://www.roblox.com/asset/?id=1083465857",
        walk = "http://www.roblox.com/asset/?id=1083465857",
        run = "http://www.roblox.com/asset/?id=1083465857",
        jump = "http://www.roblox.com/asset/?id=1083465857",
        climb = "http://www.roblox.com/asset/?id=1083465857",
        fall = "http://www.roblox.com/asset/?id=1083465857"
    },
    ["Bubbly"] = {
        idle1 = "http://www.roblox.com/asset/?id=910004836",
        idle2 = "http://www.roblox.com/asset/?id=910009958",
        walk = "http://www.roblox.com/asset/?id=910034870",
        run = "http://www.roblox.com/asset/?id=910025107",
        jump = "http://www.roblox.com/asset/?id=910016857",
        climb = "http://www.roblox.com/asset/?id=910009958",
        fall = "http://www.roblox.com/asset/?id=910009958"
    },
    ["Elder"] = {
        idle1 = "http://www.roblox.com/asset/?id=845386501",
        idle2 = "http://www.roblox.com/asset/?id=845397899",
        walk = "http://www.roblox.com/asset/?id=845403856",
        run = "http://www.roblox.com/asset/?id=845386501",
        jump = "http://www.roblox.com/asset/?id=845386501",
        climb = "http://www.roblox.com/asset/?id=845386501",
        fall = "http://www.roblox.com/asset/?id=845386501"
    },
    ["Toy"] = {
        idle1 = "http://www.roblox.com/asset/?id=782841498",
        idle2 = "http://www.roblox.com/asset/?id=782841498",
        walk = "http://www.roblox.com/asset/?id=782841498",
        run = "http://www.roblox.com/asset/?id=782841498",
        jump = "http://www.roblox.com/asset/?id=782841498",
        climb = "http://www.roblox.com/asset/?id=782841498",
        fall = "http://www.roblox.com/asset/?id=782841498"
    }
}

local function applyCustomAnimations(character)
    if not character then return end

    local Animate = character:FindFirstChild("Animate")
    if not Animate then return end

    local ClonedAnimate = Animate:Clone()

    ClonedAnimate.idle.Animation1.AnimationId = AnimationOptions["Idle1"]
    ClonedAnimate.idle.Animation2.AnimationId = AnimationOptions["Idle2"]
    ClonedAnimate.walk.WalkAnim.AnimationId = AnimationOptions["Walk"]
    ClonedAnimate.run.RunAnim.AnimationId = AnimationOptions["Run"]
    ClonedAnimate.jump.JumpAnim.AnimationId = AnimationOptions["Jump"]
    ClonedAnimate.climb.ClimbAnim.AnimationId = AnimationOptions["Climb"]
    ClonedAnimate.fall.FallAnim.AnimationId = AnimationOptions["Fall"]

    Animate:Destroy()
    ClonedAnimate.Parent = character
end

LocalPlayer.CharacterAdded:Connect(function(character)
    if KeepOnDeath then
        task.wait(1)
        applyCustomAnimations(character)
    end
end)

local animationNames = {"Default", "Ninja", "Superhero", "Robot", "Cartoon", "Catwalk", "Zombie", "Mage", "Pirate", "Knight", "Vampire", "Bubbly", "Elder", "Toy"}

LeftGroupBox:AddDropdown("Idle1Dropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Idle1",
    Callback = function(Value)
        AnimationOptions["Idle1"] = AnimationSets[Value].idle1
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("Idle2Dropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Idle2",
    Callback = function(Value)
        AnimationOptions["Idle2"] = AnimationSets[Value].idle2
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("WalkDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Walk",
    Callback = function(Value)
        AnimationOptions["Walk"] = AnimationSets[Value].walk
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("RunDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Run",
    Callback = function(Value)
        AnimationOptions["Run"] = AnimationSets[Value].run
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("JumpDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Jump",
    Callback = function(Value)
        AnimationOptions["Jump"] = AnimationSets[Value].jump
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("ClimbDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Climb",
    Callback = function(Value)
        AnimationOptions["Climb"] = AnimationSets[Value].climb
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("FallDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Fall",
    Callback = function(Value)
        AnimationOptions["Fall"] = AnimationSets[Value].fall
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddToggle("MyToggle", {
    Text = "Keep On Death",
    Default = false,
    Tooltip = "Keeps the animation after respawning",
    Callback = function(Value)
        KeepOnDeath = Value
    end
})

getgenv().SelectedTarget = nil
getgenv().SelectedTeleportType = "unsafe"
getgenv().PlayerList = {}
getgenv().groupIDs = {10604500, 17215700}
getgenv().autoKillEnabled = false
getgenv().orbitStompEnabled = false
getgenv().lastPosition = nil
getgenv().strafeEnabled = false
getgenv().AutoAmmoEnabled = false
getgenv().oldPosition = nil
getgenv().invisiblePart = nil
getgenv().isActionRunning = false -- To track if an action is running

function updatePlayerList()
    getgenv().PlayerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(getgenv().PlayerList, player.Name)
    end
    if getgenv().TargetDropdown then
        getgenv().TargetDropdown:SetValues(getgenv().PlayerList)
    end
end

updatePlayerList()

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

function knockTarget(targetPlayer)
    local character = targetPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local bodyEffects = character:FindFirstChild("BodyEffects")
    
    if not bodyEffects or not humanoid then
        warn("BodyEffects or Humanoid not found in the character!")
        return
    end
    
    local koValue = bodyEffects:WaitForChild("K.O", 5)
    if not koValue then
        warn("K.O value not found!")
        return
    end
    
    local oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    task.spawn(function()
        while not koValue.Value and getgenv().isActionRunning do
            local targetPosition = character.HumanoidRootPart.Position
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, -20, 0))
            
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool and tool:FindFirstChild("Ammo") then
                ReplicatedStorage.MainEvent:FireServer("ShootGun", tool:FindFirstChild("Handle"), tool:FindFirstChild("Handle").CFrame.Position, character.Head.Position, character.Head, Vector3.new(0, 0, -1))
            end
            
            task.wait()
        end
        
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(oldPosition)
    end)
end


function bringTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    if not getgenv().character then return end
    
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    if not getgenv().bodyEffects or not getgenv().humanoid then return end
    
    getgenv().koValue = getgenv().bodyEffects:FindFirstChild("K.O")
    if not getgenv().koValue then return end

    getgenv().localCharacter = LocalPlayer.Character
    if not getgenv().localCharacter then return end

    getgenv().humanoidRootPart = getgenv().localCharacter:FindFirstChild("HumanoidRootPart")
    if not getgenv().humanoidRootPart then return end
    
    getgenv().oldPosition = getgenv().humanoidRootPart.Position
    getgenv().isActionRunning = true

    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character:FindFirstChild("HumanoidRootPart") and getgenv().character.HumanoidRootPart.Position or nil
            if getgenv().targetPosition then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, -20, 0))
            end
            
            getgenv().tool = getgenv().localCharacter:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                game:GetService("ReplicatedStorage").MainEvent:FireServer(
                    "ShootGun",
                    getgenv().tool:FindFirstChild("Handle"),
                    getgenv().tool:FindFirstChild("Handle").CFrame.Position,
                    getgenv().character.Head.Position,
                    getgenv().character.Head,
                    Vector3.new(0, 0, -1)
                )
            end

            task.wait()
        end
        
        repeat
            if getgenv().koValue.Value then
                getgenv().isActionRunning = false
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
                return
            end

            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                game:GetService("RunService").RenderStepped:Wait()
            end
            
            game:GetService("ReplicatedStorage"):WaitForChild("MainEvent"):FireServer("Grabbing", false)
            task.wait(0.1)
        until getgenv().character:FindFirstChild("GRABBING_CONSTRAINT")
        task.wait(0.2)

        getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function stompTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    
    if not getgenv().bodyEffects or not getgenv().humanoid then
        warn("BodyEffects or Humanoid not found in the character!")
        return
    end
    
    getgenv().koValue = getgenv().bodyEffects:WaitForChild("K.O", 5)
    getgenv().sDeathValue = getgenv().bodyEffects:WaitForChild("SDeath", 5)
    if not getgenv().koValue or not getgenv().sDeathValue then
        warn("K.O or SDeath value not found!")
        return
    end
    
    getgenv().oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character.HumanoidRootPart.Position
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, -20, 0))
            
            getgenv().tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                ReplicatedStorage.MainEvent:FireServer("ShootGun", getgenv().tool:FindFirstChild("Handle"), getgenv().tool:FindFirstChild("Handle").CFrame.Position, getgenv().character.Head.Position, getgenv().character.Head, Vector3.new(0, 0, -1))
            end
            
            task.wait()
        end
        
        while not getgenv().sDeathValue.Value and getgenv().isActionRunning do
            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                RunService.RenderStepped:Wait()
            end
            ReplicatedStorage.MainEvent:FireServer("Stomp")
            task.wait()
        end
        
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function voidTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    if not getgenv().character then return end
    
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    if not getgenv().bodyEffects or not getgenv().humanoid then return end
    
    getgenv().koValue = getgenv().bodyEffects:FindFirstChild("K.O")
    if not getgenv().koValue then return end

    getgenv().localCharacter = LocalPlayer.Character
    if not getgenv().localCharacter then return end

    getgenv().humanoidRootPart = getgenv().localCharacter:FindFirstChild("HumanoidRootPart")
    if not getgenv().humanoidRootPart then return end
    
    getgenv().oldPosition = getgenv().humanoidRootPart.Position
    getgenv().isActionRunning = true

    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character:FindFirstChild("HumanoidRootPart") and getgenv().character.HumanoidRootPart.Position or nil
            if getgenv().targetPosition then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, -20, 0))
            end
            
            getgenv().tool = getgenv().localCharacter:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                game:GetService("ReplicatedStorage").MainEvent:FireServer(
                    "ShootGun",
                    getgenv().tool:FindFirstChild("Handle"),
                    getgenv().tool:FindFirstChild("Handle").CFrame.Position,
                    getgenv().character.Head.Position,
                    getgenv().character.Head,
                    Vector3.new(0, 0, -1)
                )
            end

            task.wait()
        end
        
        repeat
            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                game:GetService("RunService").RenderStepped:Wait()
            end
            
            game:GetService("ReplicatedStorage"):WaitForChild("MainEvent"):FireServer("Grabbing", false)
            task.wait(0.2)
        until getgenv().character:FindFirstChild("GRABBING_CONSTRAINT")

        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1000, 10000, -1000)
        task.wait(0.3)
        game:GetService("ReplicatedStorage"):WaitForChild("MainEvent"):FireServer("Grabbing", false)
        task.wait(0.2)
        getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function stopAllActions()
    getgenv().isActionRunning = false
    if getgenv().oldPosition then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end
    Library:Notify("All actions stopped.", 5)
end

getgenv().Services = {
    Players = game:GetService("Players"),
    LocalPlayer = game:GetService("Players").LocalPlayer
}

getgenv().PlayerInfo = Tabs.Players:AddLeftGroupbox('Player Info')

PlayerInfo:AddToggle('view', {
    Text = 'View',
    Default = false,
    Callback = function(state)
        if state and getgenv().SelectedTarget then
            local targetPlayer = Services.Players:FindFirstChild(getgenv().SelectedTarget)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Humanoid
            end
        else
            workspace.CurrentCamera.CameraSubject = Services.LocalPlayer.Character.Humanoid
        end
    end,
})

PlayerInfo:AddButton('Teleport', function()
    local targetPlayer = Services.Players:FindFirstChild(getgenv().SelectedTarget)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Services.LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
    end
end)

PlayerInfo:AddDropdown('teleportType', {
    Values = { 'safe', 'unsafe' },
    Default = 'unsafe',
    Multi = false,
    Text = 'Teleport Type',
    Callback = function(value)
        getgenv().SelectedTeleportType = value
    end,
})

getgenv().TargetDropdown = PlayerInfo:AddDropdown('yepyep', {
    SpecialType = 'Player',
    Text = 'Select a Player',
    Tooltip = 'Select a player to perform actions on.',
    Callback = function(value)
        getgenv().SelectedTarget = value
    end,
})

PlayerInfo:AddInput('playerSearch', {
    Text = 'Search Player',
    Tooltip = 'Type to search for a player.',
    Callback = function(value)
        local matches = {}
        value = string.lower(value)

        for _, player in ipairs(Services.Players:GetPlayers()) do
            local playerName = string.lower(player.Name)
            local displayName = string.lower(player.DisplayName)

            if string.find(playerName, value) or string.find(displayName, value) then
                table.insert(matches, player.Name) -- Use actual username
            end
        end

        options.yepyep:SetValue(matches)

        if #matches == 1 then
            Options.myPlayerDropdown:SetValue(matches[1])
            getgenv().SelectedTarget = matches[1]
        end
    end,
})


getgenv().PlayerActions = Tabs.Players:AddRightGroupbox('Player Actions')

getgenv().PlayerActions:AddDropdown('actionType', {
    Values = { 'Knock', 'Bring', 'Stomp', 'Void' },
    Default = 'Knock',
    Multi = false,
    Text = 'action',
    Callback = function(value)
        getgenv().SelectedAction = value
    end,
})

getgenv().PlayerActions:AddButton('Execute Action', function()
    local targetPlayer = Players:FindFirstChild(getgenv().SelectedTarget)
    if targetPlayer and targetPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if tool and tool:FindFirstChild("Ammo") then
            getgenv().isActionRunning = true
            getgenv().oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
            
            if getgenv().SelectedAction == "Knock" then
                knockTarget(targetPlayer)
            elseif getgenv().SelectedAction == "Bring" then
                bringTarget(targetPlayer)
            elseif getgenv().SelectedAction == "Stomp" then
                stompTarget(targetPlayer)
            elseif getgenv().SelectedAction == "Void" then
                voidTarget(targetPlayer)
            end
        else
            Library:Notify("Equip a tool to use this function. | Mad.lol", 5)
        end
    end
end)

PlayerActions:AddToggle("AutoKill", {
    Text = "Auto Kill",
    Default = false,
    Callback = function(State)
        getgenv().autoKillEnabled = State
        while getgenv().autoKillEnabled and getgenv().SelectedTarget do
            local targetPlayer = Players:FindFirstChild(getgenv().SelectedTarget)
            if targetPlayer and targetPlayer.Character then
                stompTarget(targetPlayer)
            end
            task.wait()
        end
    end
})

getgenv().PlayerActions:AddButton('Stop', function()
    stopAllActions()
end)

getgenv().AllPlayerActions = Tabs.Players:AddRightGroupbox('All Player Actions')

getgenv().ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
getgenv().OriginalPosition = nil
getgenv().KillAllEnabled = false
getgenv().StompAllEnabled = false
getgenv().CurrentTarget = nil

getgenv().BuyItem = function(itemName)
    -- Unequip all tools before buying
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LocalPlayer.Backpack
        end
    end

    for _, item in pairs(getgenv().ShopFolder:GetChildren()) do
        if item.Name == itemName then
            local itemHead = item:FindFirstChild("Head")
            if itemHead then
                LocalPlayer.Character.HumanoidRootPart.CFrame = itemHead.CFrame + Vector3.new(0, 3.2, 0)
                task.wait(0.1) -- Reduced wait time for faster execution
                fireclickdetector(item:FindFirstChild("ClickDetector"))
            end
            break
        end
    end
end

getgenv().EquipLMG = function()
    -- Check for LMG in both Backpack and Character
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool.Name == "[LMG]" then
            tool.Parent = LocalPlayer.Character
            return tool
        end
    end
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool.Name == "[LMG]" then
            return tool
        end
    end
    return nil
end

getgenv().ShootPlayer = function(target, tool)
    if not tool:FindFirstChild("Handle") then return end
    local targetHead = target.Character:FindFirstChild("Head")
    if not targetHead then return end
    ReplicatedStorage.MainEvent:FireServer("ShootGun", tool.Handle, tool.Handle.CFrame.Position, targetHead.Position, targetHead, Vector3.new(0, 0, -1))
end

getgenv().IsKnockedOut = function(target)
    local bodyEffects = target.Character:FindFirstChild("BodyEffects")
    if not bodyEffects then return false end
    local koValue = bodyEffects:FindFirstChild("K.O")
    return koValue and koValue.Value
end

getgenv().HasForcefield = function(target)
    return target.Character and target.Character:FindFirstChild("ForceField")
end

getgenv().IsGrabbing = function(target)
    return target.Character and target.Character:FindFirstChild("GRABBING_CONSTRAINT")
end

getgenv().IsTooFar = function(target)
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude
    return distance > 10000
end

getgenv().KillAllPlayers = function()
    getgenv().OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame

    -- Unequip all tools before buying
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LocalPlayer.Backpack
        end
    end

    while not (LocalPlayer.Backpack:FindFirstChild("[LMG]") or LocalPlayer.Character:FindFirstChild("[LMG]")) do
        getgenv().BuyItem("[LMG] - $4098")
        task.wait(0.2) -- Reduced wait time for faster execution
    end

    for i = 1, 5 do
        getgenv().BuyItem("200 [LMG Ammo] - $328")
        task.wait(0) -- Reduced wait time for faster execution
    end

    local lmgTool = getgenv().EquipLMG()
    if not lmgTool then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if getgenv().HasForcefield(player) or getgenv().IsKnockedOut(player) or getgenv().IsGrabbing(player) or getgenv().IsTooFar(player) then
                continue
            end

            getgenv().CurrentTarget = player
            workspace.CurrentCamera.CameraSubject = player.Character.Humanoid

            while not getgenv().IsKnockedOut(player) and getgenv().KillAllEnabled do
                LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame - Vector3.new(0, 20, 0)
                getgenv().ShootPlayer(player, lmgTool)
                task.wait(0) -- Reduced wait time for faster execution
            end

            if not getgenv().KillAllEnabled then break end
        end
    end

    if getgenv().OriginalPosition then
        LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().OriginalPosition
    end

    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    getgenv().CurrentTarget = nil

    if getgenv().StompAllEnabled then
        getgenv().StompAllPlayers()
    end
end

getgenv().StompAllPlayers = function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local bodyEffects = character:FindFirstChild("BodyEffects")

            if not bodyEffects or not humanoid then
                continue
            end

            local koValue = bodyEffects:FindFirstChild("K.O")
            local sDeathValue = bodyEffects:FindFirstChild("SDeath")

            if not koValue or not sDeathValue then
                continue
            end

            if koValue.Value and not sDeathValue.Value then
                while not sDeathValue.Value and getgenv().StompAllEnabled do
                    if not koValue.Value or getgenv().IsGrabbing(player) then
                        break -- Stop stomping if K.O is lost or player is grabbed
                    end

                    local upperTorso = character:FindFirstChild("UpperTorso")
                    if upperTorso then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(upperTorso.Position + Vector3.new(0, 3, 0))
                        RunService.RenderStepped:Wait()
                    end
                    ReplicatedStorage.MainEvent:FireServer("Stomp")
                    task.wait(0) -- Reduced wait time for faster execution
                end
            end
        end
    end
end

getgenv().AllPlayerActions:AddToggle("KillAllToggle", {
    Text = "Kill All",
    Default = false,
    Callback = function(value)
        getgenv().KillAllEnabled = value
        if value then
            getgenv().KillAllPlayers()
        else
            if getgenv().OriginalPosition then
                LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().OriginalPosition
            end
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
})

getgenv().AllPlayerActions:AddToggle("StompAllToggle", {
    Text = "Stomp All",
    Default = false,
    Callback = function(value)
        getgenv().StompAllEnabled = value
        if value and not getgenv().KillAllEnabled then
            getgenv().StompAllPlayers()
        end
    end
})

getgenv().serenity = {}
getgenv().AutoShootEnabled = false

function isPlayerInSerenity(playerName)
    for _, name in pairs(getgenv().serenity) do
        if name == playerName then
            return true
        end
    end
    return false
end

function findPlayerByName(playerName)
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player.Name:lower() == playerName:lower() then
            return player
        end
    end
    return nil
end

function togglePlayerInSerenity(playerName)
    local player = findPlayerByName(playerName)
    
    if not player then
        Library:Notify("Player not found in the game!", 5)
        return
    end

    if isPlayerInSerenity(playerName) then
        for i, name in pairs(getgenv().serenity) do
            if name == playerName then
                table.remove(getgenv().serenity, i)
                break
            end
        end
        Library:Notify(playerName .. " has been removed from Serenity Mode", 5)
    else
        table.insert(getgenv().serenity, playerName)
        Library:Notify(playerName .. " has been added to Serenity Mode", 5)
    end
end

function autoEquipTool()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return nil end

    local bestTool = nil

    -- Prioritize tools named "Rifle" or "Aug"
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
            local toolName = tool.Name:lower()
            if toolName == "rifle" or toolName == "aug" then
                bestTool = tool
                break
            elseif not bestTool then
                bestTool = tool -- Fallback if no prioritized tool is found
            end
        end
    end

    if bestTool then
        bestTool.Parent = player.Character -- Equip the tool
        Library:Notify("Equipped tool: " .. bestTool.Name, 3)
        
        -- Wait until the tool is fully equipped
        repeat task.wait() until player.Character:FindFirstChildOfClass("Tool") == bestTool

        return bestTool
    end

    Library:Notify("No tool with Ammo found!", 3)
    return nil
end

getgenv().ShootPlayer = function(target, tool)
    if not tool or not tool:FindFirstChild("Handle") then return end
    local targetHead = target.Character and target.Character:FindFirstChild("Head")
    if not targetHead then return end
    
    -- Fire the shot
    game:GetService("ReplicatedStorage").MainEvent:FireServer("ShootGun", tool.Handle, tool.Handle.CFrame.Position, targetHead.Position, targetHead, Vector3.new(0, 0, -1))
end

getgenv().playerTextBox = AllPlayerActions:AddInput('PlayerTextBox', {
    Text = 'Serenity Mode',
    Tooltip = 'This will add a player to a table and if they go near you, it will automatically shoot them.',
    Default = '',
    Finished = true,
    Callback = function(Value)
        if Value and Value ~= "" then
            togglePlayerInSerenity(Value)
        end
    end
})

getgenv().autoShootToggle = AllPlayerActions:AddToggle('AutoShootToggle', {
    Text = 'Auto Shoot',
    Tooltip = 'Automatically shoots players in the Serenity table within 250 studs',
    Default = false,
    Callback = function(Value)
        getgenv().AutoShootEnabled = Value

        if Value then
            while getgenv().AutoShootEnabled do
                local character = game.Players.LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                if rootPart then
                    for _, targetPlayerName in pairs(getgenv().serenity) do
                        local targetPlayer = game:GetService("Players"):FindFirstChild(targetPlayerName)
                        if targetPlayer and targetPlayer.Character then
                            local targetHead = targetPlayer.Character:FindFirstChild("Head")
                            if targetHead then
                                local distance = (rootPart.Position - targetHead.Position).Magnitude
                                
                                if distance <= 250 then
                                    local tool = character:FindFirstChildOfClass("Tool")

                                    if not tool then
                                        tool = autoEquipTool()
                                    end

                                    if tool then
                                        getgenv().ShootPlayer(targetPlayer, tool)
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0)
            end
        end
    end
})


MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle('KeybindListToggle', {
    Text = 'Show Keybind List',
    Default = false,
    Callback = function(state)
        Library.KeybindFrame.Visible = state
    end
})

getgenv().vu = game:GetService("VirtualUser")
getgenv().isAntiAfkEnabled = false
getgenv().antiAfkConnection = nil

MenuGroup:AddToggle('AntiAFKToggle', {
    Text = 'Anti-AFK',
    Default = false,
    Callback = function(state)
        getgenv().isAntiAfkEnabled = state
        if getgenv().isAntiAfkEnabled then
            getgenv().antiAfkConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                getgenv().vu:CaptureController()
                getgenv().vu:ClickButton2(Vector2.new())
            end)
        else
            if getgenv().antiAfkConnection then
                getgenv().antiAfkConnection:Disconnect()
                getgenv().antiAfkConnection = nil
            end
        end
    end
})


MenuGroup:AddButton('Copy Job ID', function()
    setclipboard(game.JobId)
end)

MenuGroup:AddButton('Copy JS Join Script', function()
    local jsScript = 'Roblox.GameLauncher.joinGameInstance(' .. game.PlaceId .. ', "' .. game.JobId .. '")'
    setclipboard(jsScript)
end)

MenuGroup:AddInput('JobIdInput', {
    Default = '',
    Numeric = false,
    Finished = true,
    Text = '..JobId..',
    Tooltip = 'Enter a Job ID to join a specific server',
    Placeholder = 'Enter Job ID here',
    Callback = function(Value)
        game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, Value, game:GetService('Players').LocalPlayer)
    end
})


MenuGroup:AddButton('Rejoin Server', function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
end)



ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MaddieHack')
SaveManager:SetFolder('MaddieHack/configs')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

Library:SetWatermarkVisibility(true)

local StatsService = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60
local StartTime = tick()

local function getExecutor()
    if syn then return "Synapse X"
    elseif secure_call then return "ScriptWare"
    elseif identifyexecutor then return identifyexecutor()
    else return "Unknown" end
end

local function getGameName(placeId)
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(placeId).Name
    end)
    return success and result or "Unknown Game"
end

local WatermarkConnection = RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    local Ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
    local Executor = getExecutor()
    local Uptime = math.floor(tick() - StartTime)
    local UptimeFormatted = string.format("%02d:%02d", math.floor(Uptime / 60), Uptime % 60)
    local GameName = getGameName(game.PlaceId)

    Library:SetWatermark(("[ Mad.lol ] | $ Beta $ |  %s | %s (%d) | Uptime: %s | FPS %d | %d ms"):format(
        Executor, GameName, game.PlaceId, UptimeFormatted, math.floor(FPS), Ping
    ))
end)


Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    print('Unloaded!')
    Library.Unloaded = true
end)
