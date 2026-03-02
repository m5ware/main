local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "M5WARE",
    LoadingTitle = "m5ware",
    LoadingSubtitle = "by pavel # forward # betto",
    ConfigurationSaving = { Enabled = true, FolderName = "M5WARE_RPG", FileName = "Config" },
    Discord = { Enabled = false },
    KeySystem = false
})

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local RageTab = Window:CreateTab("Rage", 4483362458)
local CarTab = Window:CreateTab("Car Spam", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local GunTab = Window:CreateTab("Gun", 4483362458)
local VisualTab = Window:CreateTab("Visual", 4483362458)

local rpgClickEnabled = false
local stingerClickEnabled = false
local javelinClickEnabled = false
local swastikaEnabled = false
local silentAimEnabled = false
local rpgHolding = false
local fireDelay = 0.005
local minDistance = 15
local horizontalSpread = 12
local verticalSpread = 12
local fovRadius = 100
local rocketSystem = nil
local events = nil
local rockets = nil
local isGuiActive = false

local ppoEnabled = false
local ppoLength = 50
local ppoStep = 2
local ppoDelay = 0.05

local rpgSpamEnabled = false
local rpgSpamDelay = 0.05

local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Radius = fovRadius
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Transparency = 1
fovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    if silentAimEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = fovRadius
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

local swastikaOffsets = {}
for v = -3, 3 do table.insert(swastikaOffsets, {h = 0, v = v}) end
for h = -3, -1 do table.insert(swastikaOffsets, {h = h, v = 0}) end
for h = 1, 3 do table.insert(swastikaOffsets, {h = h, v = 0}) end
for h = 1, 3 do table.insert(swastikaOffsets, {h = h, v = 3}) end
for v = -3, -1 do table.insert(swastikaOffsets, {h = 3, v = v}) end
for h = -3, -1 do table.insert(swastikaOffsets, {h = h, v = -3}) end
for v = 1, 3 do table.insert(swastikaOffsets, {h = -3, v = v}) end

local function initSystem()
    if not rocketSystem then
        rocketSystem = ReplicatedStorage:FindFirstChild("RocketSystem")
        if not rocketSystem then return false end
        events = rocketSystem:FindFirstChild("Events")
        if not events then return false end
        rockets = rocketSystem:FindFirstChild("Rockets")
    end
    return true
end

local function getWeapon(weaponName)
    local keywords = {
        RPG = {"rpg", "rocket", "launcher", "rpg-7", "rpg7"},
        Stinger = {"stinger", "fim-92", "fim92"},
        Javelin = {"javelin", "fgm-148", "fgm148"}
    }
    
    local function matches(name, kwList)
        name = name:lower()
        for _, kw in ipairs(kwList) do
            if name:find(kw, 1, true) then return true end
        end
        return false
    end

    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and matches(tool.Name, keywords[weaponName] or {}) then
                return tool
            end
        end
    end
    
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and matches(tool.Name, keywords[weaponName] or {}) then
                return tool
            end
        end
    end
    
    return nil
end

local function getRPG()
    return getWeapon("RPG")
end

local function getStinger()
    return getWeapon("Stinger")
end

local function getJavelin()
    return getWeapon("Javelin")
end

local function getTargetPos()
    local mouse = LocalPlayer:GetMouse()
    local camera = Workspace.CurrentCamera
    local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character or Workspace}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
    if result then return result.Position, result.Instance end
    return ray.Origin + ray.Direction * 10000, nil
end

local function getNearestInFOV()
    local mousePos = UserInputService:GetMouseLocation()
    local nearest = nil
    local minDist = fovRadius
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character.Humanoid and player.Character.Humanoid.Health > 0 then
            local head = player.Character.Head
            local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = head
                end
            end
        end
    end
    return nearest
end

local function fireRocket(pos, weapon, targetPart)
    if not initSystem() or isGuiActive then return end
    
    local fireEvent = events:FindFirstChild("FireRocket")
    local rocketHitEvent = events:FindFirstChild("RocketHit")
    local rocketReloadedFX = events:FindFirstChild("RocketReloadedFX")
    
    if fireEvent then
        task.spawn(function()
            pcall(function()
                local direction = (pos - LocalPlayer.Character.HumanoidRootPart.Position).Unit
                local args = {
                    [1] = {
                        Direction = direction,
                        Settings = {
                            expShake = {
                                fadeInTime = 0.05,
                                magnitude = 3,
                                rotInfluence = Vector3.new(0.4, 0, 0.4),
                                fadeOutTime = 0.5,
                                roughness = 3,
                                posInfluence = Vector3.new(1, 1, 0)
                            },
                            gravity = Vector3.new(0, -20, 0),
                            HelicopterDamage = 450,
                            FireRate = 15,
                            VehicleDamage = 350,
                            ExpName = "RPG",
                            RocketAmount = 1,
                            ExpRadius = 12,
                            BoatDamage = 300,
                            TankDamage = 300,
                            Acceleration = 8,
                            ShieldDamage = 170,
                            Distance = 4000,
                            PlaneDamage = 500,
                            GunshipDamage = 170,
                            velocity = 200,
                            ExplosionDamage = 120
                        },
                        Origin = LocalPlayer.Character.HumanoidRootPart.Position,
                        RocketModel = rockets and rockets:FindFirstChild("RPG Rocket"),
                        Vehicle = weapon,
                        PlrFired = LocalPlayer,
                        Weapon = weapon
                    }
                }
                fireEvent:InvokeServer(unpack(args))
            end)
        end)
    end
    
    if rocketHitEvent and targetPart then
        task.spawn(function()
            pcall(function()
                local hitArgs = {
                    [1] = {
                        Normal = Vector3.new(0, 1, 0),
                        Player = LocalPlayer,
                        Label = LocalPlayer.Name .. "Rocket" .. math.random(1, 9999),
                        HitPart = targetPart,
                        Vehicle = weapon,
                        Position = pos,
                        Weapon = weapon
                    }
                }
                rocketHitEvent:FireServer(unpack(hitArgs))
            end)
        end)
    end
    
    if rocketReloadedFX then
        task.spawn(function()
            pcall(function()
                local reloadArgs = {
                    [1] = weapon,
                    [2] = false
                }
                rocketReloadedFX:FireServer(unpack(reloadArgs))
            end)
        end)
    end
end

local function fireStinger(pos, weapon, targetPart)
    if not initSystem() or isGuiActive then return end
    
    local fireEvent = events:FindFirstChild("FireRocket")
    local rocketHitEvent = events:FindFirstChild("RocketHit")
    
    if fireEvent then
        task.spawn(function()
            pcall(function()
                local direction = (pos - LocalPlayer.Character.HumanoidRootPart.Position).Unit
                local args = {
                    [1] = {
                        Direction = direction,
                        Settings = {
                            expShake = {
                                fadeInTime = 0.05,
                                magnitude = 3,
                                rotInfluence = Vector3.new(0.4, 0, 0.4),
                                fadeOutTime = 0.5,
                                roughness = 3,
                                posInfluence = Vector3.new(1, 1, 0)
                            },
                            gravity = Vector3.new(0, -20, 0),
                            HelicopterDamage = 450,
                            FireRate = 15,
                            VehicleDamage = 350,
                            ExpName = "RPG",
                            RocketAmount = 1,
                            ExpRadius = 12,
                            BoatDamage = 300,
                            TankDamage = 300,
                            Acceleration = 8,
                            ShieldDamage = 170,
                            Distance = 4000,
                            PlaneDamage = 500,
                            GunshipDamage = 170,
                            velocity = 200,
                            ExplosionDamage = 120
                        },
                        Origin = LocalPlayer.Character.HumanoidRootPart.Position,
                        RocketModel = rockets and rockets:FindFirstChild("Stinger Rocket"),
                        Vehicle = weapon,
                        PlrFired = LocalPlayer,
                        Weapon = weapon
                    }
                }
                fireEvent:InvokeServer(unpack(args))
            end)
        end)
    end
    
    if rocketHitEvent and targetPart then
        task.spawn(function()
            pcall(function()
                local hitArgs = {
                    [1] = {
                        Normal = Vector3.new(0, 1, 0),
                        Player = LocalPlayer,
                        Label = LocalPlayer.Name .. "Stinger" .. math.random(1, 9999),
                        HitPart = targetPart,
                        Vehicle = weapon,
                        Position = pos,
                        Weapon = weapon
                    }
                }
                rocketHitEvent:FireServer(unpack(hitArgs))
            end)
        end)
    end
end

local function fireJavelin(pos, weapon, targetPart)
    if not initSystem() or isGuiActive then return end
    
    local fireEvent = events:FindFirstChild("FireRocket")
    local rocketHitEvent = events:FindFirstChild("RocketHit")
    
    if fireEvent then
        task.spawn(function()
            pcall(function()
                local direction = (pos - LocalPlayer.Character.HumanoidRootPart.Position).Unit
                local args = {
                    [1] = {
                        Direction = direction,
                        Settings = {
                            expShake = {
                                fadeInTime = 0.05,
                                magnitude = 3,
                                rotInfluence = Vector3.new(0.4, 0, 0.4),
                                fadeOutTime = 0.5,
                                roughness = 3,
                                posInfluence = Vector3.new(1, 1, 0)
                            },
                            gravity = Vector3.new(0, -20, 0),
                            HelicopterDamage = 450,
                            FireRate = 15,
                            VehicleDamage = 350,
                            ExpName = "RPG",
                            RocketAmount = 1,
                            ExpRadius = 12,
                            BoatDamage = 300,
                            TankDamage = 300,
                            Acceleration = 8,
                            ShieldDamage = 170,
                            Distance = 4000,
                            PlaneDamage = 500,
                            GunshipDamage = 170,
                            velocity = 200,
                            ExplosionDamage = 120
                        },
                        Origin = LocalPlayer.Character.HumanoidRootPart.Position,
                        RocketModel = rockets and rockets:FindFirstChild("Javelin Rocket"),
                        Vehicle = weapon,
                        PlrFired = LocalPlayer,
                        Weapon = weapon
                    }
                }
                fireEvent:InvokeServer(unpack(args))
            end)
        end)
    end
    
    if rocketHitEvent and targetPart then
        task.spawn(function()
            pcall(function()
                local hitArgs = {
                    [1] = {
                        Normal = Vector3.new(0, 1, 0),
                        Player = LocalPlayer,
                        Label = LocalPlayer.Name .. "Javelin" .. math.random(1, 9999),
                        HitPart = targetPart,
                        Vehicle = weapon,
                        Position = pos,
                        Weapon = weapon
                    }
                }
                rocketHitEvent:FireServer(unpack(hitArgs))
            end)
        end)
    end
end

local function rpgSpamAttack()
    if not rpgSpamEnabled then return end
    
    local weapon = getRPG()
    if not weapon then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            
            if player.Character.Humanoid and player.Character.Humanoid.Health > 0 then
                local targetPos = hrp.Position + Vector3.new(0, 2.5, 0)
                
                local spread = Vector3.new(
                    math.random(-3, 3),
                    math.random(0, 5),
                    math.random(-3, 3)
                )
                
                local finalPos = targetPos + spread
                
                task.spawn(function()
                    fireRocket(finalPos, weapon, hrp)
                end)
            end
        end
    end
end

task.spawn(function()
    while task.wait(rpgSpamDelay) do
        if rpgSpamEnabled then
            rpgSpamAttack()
        end
    end
end)

local function ppoLine()
    if not ppoEnabled or isGuiActive then return end
    local weapon = getRPG()
    if not weapon then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos, hitPart
    if silentAimEnabled then
        local targetHead = getNearestInFOV()
        if targetHead then
            targetPos = targetHead.Position
            hitPart = targetHead
        else
            targetPos, hitPart = getTargetPos()
        end
    else
        targetPos, hitPart = getTargetPos()
    end
    
    local dist = (targetPos - char.HumanoidRootPart.Position).Magnitude
    if dist < minDistance then return end
    
    local camera = Workspace.CurrentCamera
    local dir = (targetPos - camera.CFrame.Position).Unit
    
    for i = 0, ppoLength do
        local finalPos = targetPos + dir * (i * ppoStep) + Vector3.new(0, 0.5, 0)
        
        task.spawn(function()
            fireRocket(finalPos, weapon, hitPart)
        end)
        
        task.wait(ppoDelay)
    end
end

task.spawn(function()
    while task.wait(ppoDelay) do
        if not isGuiActive and rpgHolding and ppoEnabled then
            task.spawn(ppoLine)
        end
    end
end)

local function fireRPG()
    local weapon = getRPG() 
    if not weapon then return end
    local char = LocalPlayer.Character 
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos, hitPart
    if silentAimEnabled then
        local targetHead = getNearestInFOV()
        if targetHead then
            targetPos = targetHead.Position
            hitPart = targetHead
        else
            targetPos, hitPart = getTargetPos()
        end
    else
        targetPos, hitPart = getTargetPos()
    end
    
    local dist = (targetPos - char.HumanoidRootPart.Position).Magnitude
    if dist < minDistance then return end
    
    fireRocket(targetPos, weapon, hitPart)
end

local function fireStingerClick()
    local weapon = getStinger() 
    if not weapon then return end
    local char = LocalPlayer.Character 
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos, hitPart
    if silentAimEnabled then
        local targetHead = getNearestInFOV()
        if targetHead then
            targetPos = targetHead.Position
            hitPart = targetHead
        else
            targetPos, hitPart = getTargetPos()
        end
    else
        targetPos, hitPart = getTargetPos()
    end
    
    local dist = (targetPos - char.HumanoidRootPart.Position).Magnitude
    if dist < minDistance then return end
    
    fireStinger(targetPos, weapon, hitPart)
end

local function fireJavelinClick()
    local weapon = getJavelin() 
    if not weapon then return end
    local char = LocalPlayer.Character 
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos, hitPart
    if silentAimEnabled then
        local targetHead = getNearestInFOV()
        if targetHead then
            targetPos = targetHead.Position
            hitPart = targetHead
        else
            targetPos, hitPart = getTargetPos()
        end
    else
        targetPos, hitPart = getTargetPos()
    end
    
    local dist = (targetPos - char.HumanoidRootPart.Position).Magnitude
    if dist < minDistance then return end
    
    fireJavelin(targetPos, weapon, hitPart)
end

local function fireSwastikaBurst()
    local weapon = getRPG() 
    if not weapon then return end
    local char = LocalPlayer.Character 
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPos, hitPart
    if silentAimEnabled then
        local targetHead = getNearestInFOV()
        if targetHead then
            targetPos = targetHead.Position
            hitPart = targetHead
        else
            targetPos, hitPart = getTargetPos()
        end
    else
        targetPos, hitPart = getTargetPos()
    end
    
    local dist = (targetPos - char.HumanoidRootPart.Position).Magnitude 
    if dist < minDistance then return end
    local dir = (targetPos - char.HumanoidRootPart.Position).Unit
    local up = Vector3.new(0,1,0) 
    local right = dir:Cross(up).Unit
    for _, offset in ipairs(swastikaOffsets) do
        local finalPos = targetPos + (right * offset.h * horizontalSpread + up * offset.v * verticalSpread)
        task.spawn(function() fireRocket(finalPos, weapon, hitPart) end)
        task.wait(0.01)
    end
end

task.spawn(function()
    while task.wait(fireDelay) do
        if not isGuiActive and rpgHolding then
            if rpgClickEnabled then
                task.spawn(fireRPG)
            elseif stingerClickEnabled then
                task.spawn(fireStingerClick)
            elseif javelinClickEnabled then
                task.spawn(fireJavelinClick)
            elseif swastikaEnabled then
                task.spawn(fireSwastikaBurst)
                task.wait(0.35)
            end
        end
    end
end)


RageTab:CreateSection("Main")

RageTab:CreateToggle({
    Name = "RPG Click", 
    Callback = function(v) 
        rpgClickEnabled = v and initSystem() 
        if v then 
            stingerClickEnabled = false
            javelinClickEnabled = false
            swastikaEnabled = false 
            ppoEnabled = false
            rpgSpamEnabled = false
        end 
    end
})

RageTab:CreateToggle({
    Name = "Stinger Click", 
    Callback = function(v) 
        stingerClickEnabled = v and initSystem() 
        if v then 
            rpgClickEnabled = false
            javelinClickEnabled = false
            swastikaEnabled = false 
            ppoEnabled = false
            rpgSpamEnabled = false
        end 
    end
})

RageTab:CreateToggle({
    Name = "Javelin Click", 
    Callback = function(v) 
        javelinClickEnabled = v and initSystem() 
        if v then 
            rpgClickEnabled = false
            stingerClickEnabled = false
            swastikaEnabled = false 
            ppoEnabled = false
            rpgSpamEnabled = false
        end 
    end
})

RageTab:CreateToggle({
    Name = "RPG Swastika", 
    Callback = function(v) 
        swastikaEnabled = v and initSystem() 
        if v then 
            rpgClickEnabled = false 
            stingerClickEnabled = false
            javelinClickEnabled = false
            ppoEnabled = false
            rpgSpamEnabled = false
        end 
    end
})


RageTab:CreateSection("PPO Mode")

RageTab:CreateToggle({
    Name = "PPO",
    CurrentValue = false,
    Callback = function(v)
        ppoEnabled = v and initSystem()
        if v then
            rpgClickEnabled = false
            stingerClickEnabled = false
            javelinClickEnabled = false
            swastikaEnabled = false
            rpgSpamEnabled = false
        end
    end
})

RageTab:CreateSlider({
    Name = "PPo line",
    Range = {10, 200},
    Increment = 5,
    Suffix = "rockets",
    CurrentValue = 50,
    Callback = function(v)
        ppoLength = v
    end
})

RageTab:CreateSlider({
    Name = "PPO Rocket",
    Range = {1, 10},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 2,
    Callback = function(v)
        ppoStep = v
    end
})

RageTab:CreateSection("RPG Spam")

RageTab:CreateToggle({
    Name = "RPG Spam",
    CurrentValue = false,
    Callback = function(v)
        rpgSpamEnabled = v and initSystem()
        if v then
            rpgClickEnabled = false
            stingerClickEnabled = false
            javelinClickEnabled = false
            swastikaEnabled = false
            ppoEnabled = false
        end
    end
})

RageTab:CreateSlider({
    Name = "Spam Delay",
    Range = {0.01, 0.5},
    Increment = 0.01,
    Suffix = "seconds",
    CurrentValue = 0.05,
    Callback = function(v)
        rpgSpamDelay = v
    end
})

RageTab:CreateSection("Silent Aim")

RageTab:CreateToggle({
    Name = "Silent Aim", 
    Callback = function(v) 
        silentAimEnabled = v 
    end
})

RageTab:CreateSlider({
    Name = "FOV Radius", 
    Range = {50, 500}, 
    Increment = 10, 
    Suffix = " px", 
    CurrentValue = 100, 
    Callback = function(v) 
        fovRadius = v 
    end
})

RageTab:CreateSection("Settings")

RageTab:CreateSlider({
    Name = "Fire Rate", 
    Range = {0.005, 0.2}, 
    Increment = 0.005, 
    Suffix = "s", 
    CurrentValue = 0.005, 
    Callback = function(v) 
        fireDelay = v 
    end
})

RageTab:CreateSlider({
    Name = "Min Distance", 
    Range = {10, 50}, 
    Increment = 1, 
    Suffix = " studs", 
    CurrentValue = 15, 
    Callback = function(v) 
        minDistance = v 
    end
})

RageTab:CreateSlider({
    Name = "Swastika Spread", 
    Range = {5, 25}, 
    Increment = 1, 
    CurrentValue = 12, 
    Callback = function(v) 
        horizontalSpread = v 
        verticalSpread = v 
    end
})


RageTab:CreateSection("cash")

local crashEquipEnabled = false
local crashThreads = {}
local rpgReference = nil
local equipEventArgs = nil
local fireRocketEvent = nil
local rocketHitEvent = nil

local rocketSystem = ReplicatedStorage:FindFirstChild("RocketSystem")
local events = rocketSystem and rocketSystem:FindFirstChild("Events")
local rockets = rocketSystem and rocketSystem:FindFirstChild("Rockets")

local function cleanupSRPG()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:match("^SRPG") or obj.Name:match("^srpg") or obj.Name:match("RPG%-7") or obj.Name:match("Rocket") or obj.Name:find("SRPG", 1, true) then
            pcall(function() obj:Destroy() end)
        end
    end
end

local function megaCleanupSRPG()
    for pass = 1, 10 do
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name:match("^SRPG") or obj.Name:match("^srpg") or obj.Name:match("RPG%-7") or obj.Name:match("Rocket") or obj.Name:find("SRPG", 1, true) then
                pcall(function() obj:Destroy() end)
            end
        end
        task.wait(0.05)
    end
end

local function getRPG()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("rpg") or tool.Name:lower():find("rocket")) then
                return tool
            end
        end
    end
    return nil
end

local function buildEquipArgs()
    if equipEventArgs then return equipEventArgs end
    local rpg = rpgReference or getRPG()
    if not rpg then return nil end
    
    rpgReference = rpg
    equipEventArgs = {
        rpg,
        {
            Ammo = 1,
            Mode = "RPG",
            FireRate = 15,
            Distance = 4000,
            Bullets = 1,
            MinSpread = 0.56,
            MaxSpread = 40,
            VRecoil = {40, 45},
            HRecoil = {18, 25}
        }
    }
    return equipEventArgs
end

local function crashLoop()
    local equipEvent = ReplicatedStorage:WaitForChild("ACS_Engine"):WaitForChild("Events"):WaitForChild("Equip")
    
    while crashEquipEnabled do
        local rpg = rpgReference or getRPG()
        if rpg then
            rpgReference = rpg
            local eArgs = buildEquipArgs()
            if eArgs then
                for i = 1, 30 do
                    pcall(function() equipEvent:FireServer(unpack(eArgs)) end)
                end
            end
            
            if fireRocketEvent then
                for i = 1, 5 do
                    pcall(function() fireRocketEvent:InvokeServer({}) end)
                end
            end
            
            if rocketHitEvent then
                for i = 1, 5 do
                    pcall(function() rocketHitEvent:FireServer({}) end)
                end
            end
        end
        task.wait(0.05)
    end
end

RageTab:CreateToggle({
    Name = "Enable Crash",
    CurrentValue = false,
    Callback = function(v)
        crashEquipEnabled = v
        
        if v then
            if events then
                fireRocketEvent = events:FindFirstChild("FireRocket")
                rocketHitEvent = events:FindFirstChild("RocketHit")
            end
            
            for i = 1, 3 do
                local thread = task.spawn(crashLoop)
                table.insert(crashThreads, thread)
            end
        else
            for _, thread in ipairs(crashThreads) do
                if thread and coroutine.status(thread) ~= "dead" then
                    task.cancel(thread)
                end
            end
            crashThreads = {}
            rpgReference = nil
            equipEventArgs = nil
            
            -- Mega cleanup when crash is disabled
            megaCleanupSRPG()
        end
    end
})

RageTab:CreateButton({
    Name = "anti lag",
    Callback = function()
        if not crashEquipEnabled then
            cleanupSRPG()
        end
    end
})

RageTab:CreateButton({
    Name = "optimization",
    Callback = function()
        if not crashEquipEnabled then
            megaCleanupSRPG()
        end
    end
})


local carSettings = {
    Enabled = false,
    SelectedCar = "Katyusha",
    Delay = 0.05,
    BurstAmount = 5,
    InstaHit = true,
    FastPitch = true
}

local carHolding = false

local carList = {
    "Katyusha"
}

local function getVehicle(carName)
    local vehWorkspace = workspace:FindFirstChild("Game Systems") and workspace["Game Systems"]:FindFirstChild("Vehicle Workspace")
    if not vehWorkspace then return nil end
    
    if carName == "Katyusha" then
        return vehWorkspace:FindFirstChild("Katyusha")
    end
    
    return nil
end

local function fireCarWeapon()
    if not carSettings.Enabled then return end
    if not carHolding then return end
    
    local vehicle = getVehicle(carSettings.SelectedCar)
    if not vehicle then return end
    
    pcall(function()
        if carSettings.SelectedCar == "Katyusha" then
            local weapon = vehicle.Misc.Turrets:FindFirstChild("Katyusha Weapons"):FindFirstChild("Rocket Launcher")
            local origin = weapon.Rockets.Rocket1.Position
            local targetPos = Mouse.Hit.p
            local hitPart = Mouse.Target or workspace.Terrain
            
            for i = 1, carSettings.BurstAmount do
                task.spawn(function()
                    local rocketLabel = "VoidNuke_" .. math.random(1e6)
                    ReplicatedStorage.RocketSystem.Events.FireRocket:InvokeServer({
                        ["Rocket"] = weapon.Rockets.Rocket1,
                        ["Direction"] = (targetPos - origin).Unit,
                        ["Settings"] = {
                            ["velocity"] = 3000,
                            ["ExpRadius"] = 28,
                            ["ExplosionDamage"] = 200,
                            ["gravity"] = Vector3.new(0, 0, 0),
                            ["RocketAmount"] = 1,
                            ["ShootStraight"] = true
                        },
                        ["Origin"] = origin,
                        ["PlrFired"] = LocalPlayer,
                        ["Vehicle"] = vehicle,
                        ["RocketModel"] = ReplicatedStorage.RocketSystem.Rockets:FindFirstChild("Katyusha Rocket"),
                        ["Weapon"] = weapon
                    })
                    
                    if carSettings.InstaHit then
                        ReplicatedStorage.RocketSystem.Events.RocketHit:FireServer({
                            ["Normal"] = Vector3.new(0, 1, 0),
                            ["HitPart"] = hitPart,
                            ["Label"] = rocketLabel,
                            ["Player"] = LocalPlayer,
                            ["Position"] = targetPos,
                            ["Vehicle"] = vehicle,
                            ["Weapon"] = weapon
                        })
                    end
                end)
            end
            
            if carSettings.FastPitch then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local vehicleRemotes = remotes:FindFirstChild("VehicleRemotes")
                    if vehicleRemotes then
                        vehicleRemotes.ChangePitch:FireServer(0.35)
                    end
                end
            end
        end
    end)
end

task.spawn(function()
    while task.wait(carSettings.Delay) do
        if carSettings.Enabled and carHolding then
            fireCarWeapon()
        end
    end
end)

Mouse.Button1Down:Connect(function()
    if carSettings.Enabled then
        carHolding = true
    end
end)

Mouse.Button1Up:Connect(function()
    carHolding = false
end)

CarTab:CreateSection("Car Spam Settings")

CarTab:CreateToggle({
    Name = "Enable Car Spam",
    CurrentValue = false,
    Callback = function(v)
        carSettings.Enabled = v
    end
})

CarTab:CreateDropdown({
    Name = "Select Car",
    Options = carList,
    CurrentOption = "Katyusha",
    MultipleOptions = false,
    Callback = function(option)
        carSettings.SelectedCar = option
    end
})

CarTab:CreateSlider({
    Name = "Fire Delay",
    Range = {0.01, 0.5},
    Increment = 0.01,
    Suffix = "sec",
    CurrentValue = 0.05,
    Callback = function(v)
        carSettings.Delay = v
    end
})

CarTab:CreateSlider({
    Name = "Burst Amount",
    Range = {1, 25},
    Increment = 1,
    Suffix = "rockets",
    CurrentValue = 5,
    Callback = function(v)
        carSettings.BurstAmount = v
    end
})

CarTab:CreateToggle({
    Name = "Insta Hit",
    CurrentValue = true,
    Callback = function(v)
        carSettings.InstaHit = v
    end
})

CarTab:CreateToggle({
    Name = "Fast Pitch",
    CurrentValue = true,
    Callback = function(v)
        carSettings.FastPitch = v
    end
})


local fastApEnabled = false
local fastApConnection = nil

local function toggleFastAp(enabled)
    fastApEnabled = enabled
    if fastApConnection then
        fastApConnection:Disconnect()
        fastApConnection = nil
    end
    if enabled then
        fastApConnection = RunService.Heartbeat:Connect(function()
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj.Name == "RevivePart" then
                    local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and prompt.HoldDuration ~= 0 then
                        prompt.HoldDuration = 0
                    end
                end
            end
        end)
    end
end

MiscTab:CreateToggle({
    Name = "Fast AP (Fast Revive)",
    CurrentValue = false,
    Callback = function(v)
        toggleFastAp(v)
    end
})

local Ammos = nil

local function toggleInfiniteAmmo(enabled)
    if enabled then
        Ammos = {}
        local gunsFolder = ReplicatedStorage:FindFirstChild("Configurations")
        if gunsFolder then
            local acsGuns = gunsFolder:FindFirstChild("ACS_Guns")
            if acsGuns then
                for _, gun in ipairs(acsGuns:GetChildren()) do
                    if gun:FindFirstChild("Ammo") then
                        Ammos[gun.Name] = gun.Ammo.Value
                        gun.Ammo.Value = math.huge
                    end
                end
            end
        end
    else
        if Ammos then
            local gunsFolder = ReplicatedStorage:FindFirstChild("Configurations")
            if gunsFolder then
                local acsGuns = gunsFolder:FindFirstChild("ACS_Guns")
                if acsGuns then
                    for name, val in pairs(Ammos) do
                        local gun = acsGuns:FindFirstChild(name)
                        if gun and gun:FindFirstChild("Ammo") then
                            gun.Ammo.Value = val
                        end
                    end
                end
            end
            Ammos = nil
        end
    end
end

MiscTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Callback = function(v)
        toggleInfiniteAmmo(v)
    end
})

local function removeFallDamage()
    local freefall = ReplicatedStorage:FindFirstChild("Freefall")
    if freefall then
        freefall:Destroy()
    end
    local acsEngine = ReplicatedStorage:FindFirstChild("ACS_Engine")
    if acsEngine then
        local events = acsEngine:FindFirstChild("Events")
        if events then
            local fdmq = events:FindFirstChild("FDMG")
            if fdmq then
                fdmq:Destroy()
            end
        end
    end
end

MiscTab:CreateButton({
    Name = "No Fall Damage",
    Callback = function()
        removeFallDamage()
    end
})

MiscTab:CreateButton({
    Name = "Autofarm Drone",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Ktulhucc/Autofarm-Drone-War-tycoon/main/AutofarmDrone", true))()
    end
})

MiscTab:CreateButton({
    Name = "Anti Lag",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/pixeHvh/antilagsforkentslaky/refs/heads/main/eee", true))()
    end
})

MiscTab:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end
})

MiscTab:CreateButton({
    Name = "Anti God Mode",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/m5ware/scripts/refs/heads/main/WarTycoon/Drone/Farm/fling/m5are.lua"))()
    end
})

local chamsEnabled = false
local chamsConnection = nil

local function toggleChams(enabled)
    chamsEnabled = enabled
    local player = LocalPlayer
    local grayColor = Color3.fromRGB(128, 128, 128)
    local transparency = 0.5
    local function applyChams(char)
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and (part.Name == "Left Arm" or part.Name == "Right Arm") then
                    part.Color = grayColor
                    part.Transparency = transparency
                    part.Material = "Neon"
                end
            end
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                for _, part in ipairs(tool:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Color = grayColor
                        part.Transparency = transparency
                        part.Material = "Neon"
                    end
                end
            end
        end
    end
    applyChams(player.Character)
    if enabled then
        if chamsConnection then
            chamsConnection:Disconnect()
        end
        chamsConnection = player.CharacterAdded:Connect(applyChams)
    else
        if chamsConnection then
            chamsConnection:Disconnect()
            chamsConnection = nil
        end
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") and (part.Name == "Left Arm" or part.Name == "Right Arm") then
                    part.Color = Color3.fromRGB(163, 162, 165)
                    part.Transparency = 0
                    part.Material = "Plastic"
                end
            end
        end
    end
end

MiscTab:CreateToggle({
    Name = "Chams (Transparent Arms)",
    CurrentValue = false,
    Callback = function(v)
        toggleChams(v)
    end
})


getgenv().WarTycoon = false
getgenv().WeaponOnHands = false
getgenv().WeaponModifyMethod = "Attribute"
getgenv().bulletSpeedValue = 10000

local function findSettingsModuleForWeapon(weapon, property)
    if not (weapon and weapon:IsA("Tool")) then
        return nil
    end
    local function moduleSupportsProperty(moduleScript)
        local success, module = pcall(require, moduleScript)
        if success and type(module) == "table" and module[property] ~= nil then
            return true
        end
        return false
    end
    for _, moduleScript in ipairs(weapon:GetDescendants()) do
        if moduleScript:IsA("ModuleScript") and moduleSupportsProperty(moduleScript) then
            return moduleScript
        end
    end
    local weaponName = weapon.Name
    local searchFolders = {}
    local configurations = ReplicatedStorage:FindFirstChild("Configurations")
    if configurations then
        table.insert(searchFolders, configurations)
    end
    local acsFolder = ReplicatedStorage:FindFirstChild("ACS_Guns", true)
    if acsFolder then
        table.insert(searchFolders, acsFolder)
    end
    table.insert(searchFolders, ReplicatedStorage)
    for _, container in ipairs(searchFolders) do
        if typeof(container) == "Instance" then
            local candidate = container:FindFirstChild(weaponName, true)
            if candidate then
                if candidate:IsA("ModuleScript") and moduleSupportsProperty(candidate) then
                    return candidate
                end
                for _, moduleScript in ipairs(candidate:GetDescendants()) do
                    if moduleScript:IsA("ModuleScript") and moduleSupportsProperty(moduleScript) then
                        return moduleScript
                    end
                end
            end
        end
    end
    return nil
end

local function modifyWeaponSettings(property, value)
    local player = Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    local character = player.Character or player.CharacterAdded:Wait()
    local function applyAttribute(weapon)
        if weapon and weapon:IsA("Tool") then
            pcall(function()
                weapon:SetAttribute(property, value)
            end)
        end
    end
    local function applyRequireModule(weapon)
        local settingsModule = findSettingsModuleForWeapon(weapon, property)
        if settingsModule then
            local success, module = pcall(require, settingsModule)
            if success and type(module) == "table" and module[property] ~= nil then
                module[property] = value
            end
        end
    end
    local function processWeapon(weapon)
        if not (weapon and weapon:IsA("Tool")) then
            return
        end
        if (getgenv().WeaponModifyMethod or "Attribute") == "Attribute" then
            applyAttribute(weapon)
        else
            applyRequireModule(weapon)
        end
    end
    local handledEquippedWeapon = false
    if getgenv().WeaponOnHands then
        local toolInHand = character:FindFirstChildOfClass("Tool")
        if toolInHand then
            processWeapon(toolInHand)
            handledEquippedWeapon = true
        end
    end
    if not handledEquippedWeapon then
        for _, item in ipairs(backpack:GetChildren()) do
            processWeapon(item)
        end
        local equippedTool = character:FindFirstChildOfClass("Tool")
        if equippedTool and equippedTool.Parent ~= backpack then
            processWeapon(equippedTool)
        end
    end
end

local function infiniteAmmoACS()
    modifyWeaponSettings("Ammo", math.huge)
end

local function noRecoilNoSpread()
    if getgenv().WeaponModifyMethod == "Attribute" then
        modifyWeaponSettings("VRecoil", Vector2.new(0, 0))
        modifyWeaponSettings("HRecoil", Vector2.new(0, 0))
    else
        modifyWeaponSettings("VRecoil", {0, 0})
        modifyWeaponSettings("HRecoil", {0, 0})
    end
    modifyWeaponSettings("MinSpread", 0)
    modifyWeaponSettings("MaxSpread", 0)
    modifyWeaponSettings("RecoilPunch", 0)
    modifyWeaponSettings("AimRecoilReduction", 0)
end

local function infiniteBulletDistance()
    modifyWeaponSettings("Distance", 25000)
end

local function changeBulletSpeed(speed)
    modifyWeaponSettings("BSpeed", speed)
    modifyWeaponSettings("MuzzleVelocity", speed)
end

local function changeFireRate(rate)
    modifyWeaponSettings("FireRate", rate)
    modifyWeaponSettings("ShootRate", rate)
end

local function multiBullets(count)
    modifyWeaponSettings("Bullets", count)
end

local function changeFireMode(mode)
    modifyWeaponSettings("Mode", mode)
end

GunTab:CreateSection("ACS Methods")

GunTab:CreateToggle({
    Name = "War Tycoon Mode",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().WarTycoon = Value
    end,
})

GunTab:CreateToggle({
    Name = "Weapon In Hands Only",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().WeaponOnHands = Value
    end,
})

GunTab:CreateDropdown({
    Name = "Modify Method",
    Options = {"Attribute", "Require"},
    CurrentOption = "Attribute",
    Callback = function(Option)
        getgenv().WeaponModifyMethod = Option
    end,
})

GunTab:CreateSection("ACS Functions")

GunTab:CreateButton({
    Name = "Infinite Ammo",
    Callback = function()
        infiniteAmmoACS()
    end,
})

GunTab:CreateButton({
    Name = "No Recoil/No Spread",
    Callback = function()
        noRecoilNoSpread()
    end,
})

GunTab:CreateButton({
    Name = "Infinite Bullet Distance",
    Callback = function()
        infiniteBulletDistance()
    end,
})

GunTab:CreateInput({
    Name = "Bullet Speed",
    PlaceholderText = "Enter bullet speed...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local speed = tonumber(Text)
        if speed then
            getgenv().bulletSpeedValue = speed
        end
    end,
})

GunTab:CreateButton({
    Name = "Change Bullet Speed",
    Callback = function()
        changeBulletSpeed(getgenv().bulletSpeedValue or 10000)
    end,
})

GunTab:CreateInput({
    Name = "Fire Rate",
    PlaceholderText = "Enter fire rate...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local rate = tonumber(Text)
        if rate then
            getgenv().fireRateValue = rate
        end
    end,
})

GunTab:CreateButton({
    Name = "Change Fire Rate",
    Callback = function()
        local rate = getgenv().fireRateValue or 8888
        changeFireRate(rate)
    end,
})

GunTab:CreateInput({
    Name = "Multi Bullets Count",
    PlaceholderText = "Enter bullet count...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local count = tonumber(Text)
        if count then
            getgenv().multiBulletsValue = count
        end
    end,
})

GunTab:CreateButton({
    Name = "Multi Bullets",
    Callback = function()
        local count = getgenv().multiBulletsValue or 50
        multiBullets(count)
    end,
})

GunTab:CreateInput({
    Name = "Fire Mode",
    PlaceholderText = "Enter fire mode...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        getgenv().fireModeValue = Text
    end,
})

GunTab:CreateButton({
    Name = "Change Fire Mode",
    Callback = function()
        local mode = getgenv().fireModeValue or "Auto"
        changeFireMode(mode)
    end,
})


local espEnabled = false
local espTeamCheck = false
local espColor = Color3.new(1, 0, 0)
local selfChamsEnabled = false
local rainbowChamsEnabled = false
local selfChamsColor = Color3.fromRGB(255, 255, 255)
local enemyChamsEnabled = false
local chamsOccludedColor = {Color3.fromRGB(128, 0, 128), 0.7}
local chamsVisibleColor = {Color3.fromRGB(255, 0, 255), 0.3}
local adornmentsCache = {}
local ignoreNames = {["HumanoidRootPart"] = true}

local nebulaThemeColor = Color3.fromRGB(173, 216, 230)
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalFogStart = Lighting.FogStart
local originalFogEnd = Lighting.FogEnd
local originalFogColor = Lighting.FogColor

local skyboxes = {}
local Visuals = {}

function Visuals:NewSky(Data)
    local Name = Data.Name
    skyboxes[Name] = {
        SkyboxBk = Data.SkyboxBk,
        SkyboxDn = Data.SkyboxDn,
        SkyboxFt = Data.SkyboxFt,
        SkyboxLf = Data.SkyboxLf,
        SkyboxRt = Data.SkyboxRt,
        SkyboxUp = Data.SkyboxUp,
        MoonTextureId = Data.Moon or "rbxasset://sky/moon.jpg",
        SunTextureId = Data.Sun or "rbxasset://sky/sun.jpg"
    }
end

function Visuals:SwitchSkybox(Name)
    local OldSky = Lighting:FindFirstChildOfClass("Sky")
    if OldSky then OldSky:Destroy() end
    local Sky = Instance.new("Sky", Lighting)
    for Index, Value in pairs(skyboxes[Name]) do
        Sky[Index] = Value
    end
end

if Lighting:FindFirstChildOfClass("Sky") then
    local OldSky = Lighting:FindFirstChildOfClass("Sky")
    Visuals:NewSky({
        Name = "Game's Default Sky",
        SkyboxBk = OldSky.SkyboxBk,
        SkyboxDn = OldSky.SkyboxDn,
        SkyboxFt = OldSky.SkyboxFt,
        SkyboxLf = OldSky.SkyboxLf,
        SkyboxRt = OldSky.SkyboxRt,
        SkyboxUp = OldSky.SkyboxUp
    })
end

Visuals:NewSky({
    Name = "Sunset",
    SkyboxBk = "rbxassetid://600830446",
    SkyboxDn = "rbxassetid://600831635",
    SkyboxFt = "rbxassetid://600832720",
    SkyboxLf = "rbxassetid://600886090",
    SkyboxRt = "rbxassetid://600833862",
    SkyboxUp = "rbxassetid://600835177"
})

Visuals:NewSky({
    Name = "Arctic",
    SkyboxBk = "http://www.roblox.com/asset/?id=225469390",
    SkyboxDn = "http://www.roblox.com/asset/?id=225469395",
    SkyboxFt = "http://www.roblox.com/asset/?id=225469403",
    SkyboxLf = "http://www.roblox.com/asset/?id=225469450",
    SkyboxRt = "http://www.roblox.com/asset/?id=225469471",
    SkyboxUp = "http://www.roblox.com/asset/?id=225469481"
})

Visuals:NewSky({
    Name = "Space",
    SkyboxBk = "http://www.roblox.com/asset/?id=166509999",
    SkyboxDn = "http://www.roblox.com/asset/?id=166510057",
    SkyboxFt = "http://www.roblox.com/asset/?id=166510116",
    SkyboxLf = "http://www.roblox.com/asset/?id=166510092",
    SkyboxRt = "http://www.roblox.com/asset/?id=166510131",
    SkyboxUp = "http://www.roblox.com/asset/?id=166510114"
})

Visuals:NewSky({
    Name = "Roblox Default",
    SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex",
    SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex",
    SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex",
    SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex",
    SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex",
    SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
})

local function HSVToRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return Color3.new(r + m, g + m, b + m)
end

local originalProperties = {}

local function applySelfChams(char)
    if not char then return end
    originalProperties = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            originalProperties[part] = {
                Color = part.Color,
                Material = part.Material
            }
            part.Material = Enum.Material.ForceField
            part.Color = selfChamsColor
        end
    end
end

local function restoreSelfChams()
    for part, props in pairs(originalProperties) do
        if part and part.Parent then
            part.Color = props.Color
            part.Material = props.Material
        end
    end
    originalProperties = {}
end

local function updateSelfChams()
    if not selfChamsEnabled then return end
    for part, _ in pairs(originalProperties) do
        if part and part.Parent then
            if rainbowChamsEnabled then
                local hue = (tick() * 120) % 360
                part.Color = HSVToRGB(hue, 1, 1)
            else
                part.Color = selfChamsColor
            end
        end
    end
end

RunService.RenderStepped:Connect(updateSelfChams)

LocalPlayer.CharacterAdded:Connect(function(char)
    if selfChamsEnabled then
        task.wait(1)
        applySelfChams(char)
    end
end)

local function CreateAdornment(part, isHead, vis)
    local adorn
    if isHead then
        adorn = Instance.new("CylinderHandleAdornment")
        adorn.Height = vis == 1 and 0.87 or 1.02
        adorn.Radius = vis == 1 and 0.5 or 0.65
    else
        adorn = Instance.new("BoxHandleAdornment")
        local offset = vis == 1 and -0.05 or 0.05
        adorn.Size = part.Size + Vector3.new(offset, offset, offset)
    end
    adorn.Adornee = part
    adorn.Parent = part
    adorn.ZIndex = vis == 1 and 2 or 1
    adorn.AlwaysOnTop = vis == 1
    adorn.Visible = false
    return adorn
end

local function IsEnemy(player)
    if espTeamCheck then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

local function ApplyChams(player)
    if player ~= LocalPlayer and player.Character then
        for _, part in pairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") and not ignoreNames[part.Name] then
                if not adornmentsCache[part] then
                    adornmentsCache[part] = {
                        CreateAdornment(part, part.Name=="Head", 1),
                        CreateAdornment(part, part.Name=="Head", 2)
                    }
                end
                local ad = adornmentsCache[part]
                local visible = enemyChamsEnabled and IsEnemy(player)
                ad[1].Visible = visible
                ad[1].Color3 = chamsOccludedColor[1]
                ad[1].Transparency = chamsOccludedColor[2]
                ad[2].Visible = visible
                ad[2].AlwaysOnTop = true
                ad[2].ZIndex = 9e9
                ad[2].Color3 = chamsVisibleColor[1]
                ad[2].Transparency = chamsVisibleColor[2]
            end
        end
    end
end

local function UpdateAllChams()
    for _, player in pairs(Players:GetPlayers()) do
        ApplyChams(player)
    end
end

local function applyNebulaTheme(state)
    if state then
        local b = Instance.new("BloomEffect", Lighting)
        b.Intensity, b.Size, b.Threshold, b.Name = 0.7, 24, 1, "NebulaBloom"
        local c = Instance.new("ColorCorrectionEffect", Lighting)
        c.Saturation, c.Contrast, c.TintColor, c.Name = 0.5, 0.2, nebulaThemeColor, "NebulaColorCorrection"
        local a = Instance.new("Atmosphere", Lighting)
        a.Density, a.Offset, a.Glare, a.Haze, a.Color, a.Decay, a.Name = 0.4, 0.25, 1, 2, nebulaThemeColor, Color3.fromRGB(25, 25, 112), "NebulaAtmosphere"
        Lighting.Ambient, Lighting.OutdoorAmbient = nebulaThemeColor, nebulaThemeColor
        Lighting.FogStart, Lighting.FogEnd = 100, 500
        Lighting.FogColor = nebulaThemeColor
    else
        for _, v in pairs({"NebulaBloom", "NebulaColorCorrection", "NebulaAtmosphere"}) do
            local obj = Lighting:FindFirstChild(v)
            if obj then obj:Destroy() end
        end
        Lighting.Ambient, Lighting.OutdoorAmbient = originalAmbient, originalOutdoorAmbient
        Lighting.FogStart, Lighting.FogEnd = originalFogStart, originalFogEnd
        Lighting.FogColor = originalFogColor
    end
end

local ESP = nil

local function loadExunysESP()
    if not _G.ExunysESPLoaded then
        local success = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/FakeAngles/PasteWare-v2/refs/heads/main/ExLib.lua"))()
        end)
        if success then
            ESP = getgenv().ExunysDeveloperESP
            return true
        else
            return false
        end
    end
    return true
end

VisualTab:CreateSection("ESP Features")

VisualTab:CreateButton({
    Name = "Load Exunys ESP",
    Callback = function()
        loadExunysESP()
    end
})

VisualTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(Value)
        if ESP then
            if Value and not ESP.Loaded and ESP.Load then
                pcall(function()
                    ESP:Load()
                end)
            end
            pcall(function()
                ESP.Settings.Enabled = Value
                if ESP.UpdateConfiguration then
                    ESP.UpdateConfiguration(ESP.DeveloperSettings, ESP.Settings, ESP.Properties)
                end
            end)
        end
    end
})

VisualTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(Value)
        if ESP then
            pcall(function()
                ESP.Settings.TeamCheck = Value
                if ESP.UpdateConfiguration then
                    ESP.UpdateConfiguration(ESP.DeveloperSettings, ESP.Settings, ESP.Properties)
                end
            end)
        end
    end
})

VisualTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.new(1,0,0),
    Callback = function(Color)
        if ESP then
            pcall(function()
                ESP.Properties.ESP.Color = Color
                if ESP.UpdateConfiguration then
                    ESP.UpdateConfiguration(ESP.DeveloperSettings, ESP.Settings, ESP.Properties)
                end
            end)
        end
    end
})

VisualTab:CreateSection("Self Chams")

VisualTab:CreateToggle({
    Name = "Self Chams",
    CurrentValue = false,
    Callback = function(Value)
        selfChamsEnabled = Value
        if Value then
            if LocalPlayer.Character then
                applySelfChams(LocalPlayer.Character)
            end
        else
            restoreSelfChams()
        end
    end
})

VisualTab:CreateToggle({
    Name = "Rainbow Self Chams",
    CurrentValue = false,
    Callback = function(Value)
        rainbowChamsEnabled = Value
    end
})

VisualTab:CreateColorPicker({
    Name = "Self Chams Color",
    Color = selfChamsColor,
    Callback = function(Color)
        selfChamsColor = Color
    end
})

VisualTab:CreateSection("Enemy Chams")

VisualTab:CreateToggle({
    Name = "Enemy Chams",
    CurrentValue = false,
    Callback = function(Value)
        enemyChamsEnabled = Value
        UpdateAllChams()
    end
})

VisualTab:CreateColorPicker({
    Name = "Chams Occluded Color",
    Color = chamsOccludedColor[1],
    Callback = function(Color)
        chamsOccludedColor[1] = Color
        UpdateAllChams()
    end
})

VisualTab:CreateColorPicker({
    Name = "Chams Visible Color",
    Color = chamsVisibleColor[1],
    Callback = function(Color)
        chamsVisibleColor[1] = Color
        UpdateAllChams()
    end
})

VisualTab:CreateSlider({
    Name = "Occluded Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = chamsOccludedColor[2],
    Callback = function(Value)
        chamsOccludedColor[2] = Value
        UpdateAllChams()
    end
})

VisualTab:CreateSlider({
    Name = "Visible Transparency",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = chamsVisibleColor[2],
    Callback = function(Value)
        chamsVisibleColor[2] = Value
        UpdateAllChams()
    end
})

VisualTab:CreateSection("World Visuals")

VisualTab:CreateToggle({
    Name = "Nebula Theme",
    CurrentValue = false,
    Callback = function(Value)
        applyNebulaTheme(Value)
    end
})

VisualTab:CreateColorPicker({
    Name = "Nebula Color",
    Color = nebulaThemeColor,
    Callback = function(Color)
        nebulaThemeColor = Color
    end
})

VisualTab:CreateSection("Skybox")

local SkyboxNames = {}
for Name, _ in pairs(skyboxes) do
    table.insert(SkyboxNames, Name)
end

VisualTab:CreateDropdown({
    Name = "Skybox Selector",
    Options = SkyboxNames,
    CurrentOption = "Game's Default Sky",
    Callback = function(Option)
        if skyboxes[Option] then
            Visuals:SwitchSkybox(Option)
        end
    end
})

local function TrackPlayer(player)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        if adornmentsCache[player] then
            for _, ad in pairs(adornmentsCache[player]) do
                ad.Visible = enemyChamsEnabled and IsEnemy(player)
            end
        end
    end)
end

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        TrackPlayer(plr)
    end
end

Players.PlayerAdded:Connect(TrackPlayer)

RunService.RenderStepped:Connect(UpdateAllChams)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isGuiActive then 
        rpgHolding = true 
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        rpgHolding = false 
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) then
        local mouse = LocalPlayer:GetMouse()
        if mouse.Target and mouse.Target:IsDescendantOf(game:GetService("CoreGui")) then 
            isGuiActive = true 
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) then 
        isGuiActive = false 
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then 
        Rayfield:Destroy() 
    end
end)

local TargetCoords = Vector3.new(-770, 301, -750)
local GodModActive = false
local blackScreenActive = false
local blackScreenGui = nil

local function createBlackScreen()
    if blackScreenGui then
        blackScreenGui:Destroy()
    end
    
    blackScreenGui = Instance.new("ScreenGui")
    blackScreenGui.Name = "BlackScreenGui"
    blackScreenGui.DisplayOrder = 999999
    blackScreenGui.IgnoreGuiInset = true
    blackScreenGui.ResetOnSpawn = false
    blackScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.ZIndex = 999999
    frame.Parent = blackScreenGui
    
    local mainText = Instance.new("TextLabel")
    mainText.Size = UDim2.new(1, 0, 0.3, 0)
    mainText.Position = UDim2.new(0, 0, 0.35, 0)
    mainText.BackgroundTransparency = 1
    mainText.TextColor3 = Color3.new(1, 1, 1)
    mainText.Text = ""
    mainText.TextSize = 100
    mainText.Font = Enum.Font.GothamBlack
    mainText.TextWrapped = true
    mainText.ZIndex = 1000000
    mainText.Parent = frame
    
    local subText = Instance.new("TextLabel")
    subText.Size = UDim2.new(1, 0, 0.2, 0)
    subText.Position = UDim2.new(0, 0, 0.65, 0)
    subText.BackgroundTransparency = 1
    subText.TextColor3 = Color3.new(1, 1, 1)
    subText.Text = ""
    subText.TextSize = 50
    subText.Font = Enum.Font.Gotham
    subText.TextWrapped = true
    subText.ZIndex = 1000000
    subText.Parent = frame
    
    local dotsContainer = Instance.new("Frame")
    dotsContainer.Size = UDim2.new(1, 0, 1, 0)
    dotsContainer.Position = UDim2.new(0, 0, 0, 0)
    dotsContainer.BackgroundTransparency = 1
    dotsContainer.ZIndex = 1000000
    dotsContainer.Parent = frame
    
    local dots = {}
    for i = 1, 30 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 3, 0, 3)
        dot.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, math.random() * 0.9 + 0.05, 0)
        dot.BackgroundColor3 = Color3.new(1, 1, 1)
        dot.BackgroundTransparency = 0.3
        dot.BorderSizePixel = 0
        dot.ZIndex = 1000000
        dot.Parent = dotsContainer
        table.insert(dots, {frame = dot, speed = math.random(50, 150)})
    end
    
    blackScreenActive = true
    
    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not blackScreenActive then
            connection:Disconnect()
            return
        end
        
        for _, dotData in ipairs(dots) do
            local dot = dotData.frame
            local currentY = dot.Position.Y.Scale
            local newY = currentY + (deltaTime * dotData.speed * 0.01)
            
            if newY > 1 then
                newY = 0
                dot.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, newY, 0)
            else
                dot.Position = UDim2.new(dot.Position.X.Scale, 0, newY, 0)
            end
        end
    end)
    
    task.spawn(function()
        local m5wareText = "M 5 W A R E"
        local byText = "by pavel & forward & betto"
        
        local totalChars = #m5wareText + #byText
        local timePerChar = 10 / totalChars
        
        for i = 1, #m5wareText do
            mainText.Text = string.sub(m5wareText, 1, i)
            task.wait(timePerChar)
        end
        
        for i = 1, #byText do
            subText.Text = string.sub(byText, 1, i)
            task.wait(timePerChar)
        end
        
        task.wait(15)
        
        if blackScreenGui then
            blackScreenGui:Destroy()
            blackScreenGui = nil
        end
        blackScreenActive = false
        GodModActive = false
    end)
end

local function RunGodMod()
    if GodModActive then return end
    GodModActive = true
    
    createBlackScreen()
    
    local function FixEverything()
        local Camera = workspace.CurrentCamera
        if Camera then Camera:Destroy() end
        task.wait(0.1)
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.FieldOfView = 70
        
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
        LocalPlayer.TeamColor = BrickColor.new("Really red")
        LocalPlayer.Neutral = false
    end

    local function NukeUINew()
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        if not pgui then return end
        for _, gui in pairs(pgui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "m5wareGodMod" and gui.Name ~= "BlackScreenGui" then
                for _, obj in pairs(gui:GetDescendants()) do
                    if obj:IsA("GuiObject") then
                        local posX = obj.AbsolutePosition.X / workspace.CurrentCamera.ViewportSize.X
                        if (posX < 0.25 or posX > 0.75) and obj.Name ~= "Visuals" then
                            obj.Visible = false
                        end
                    end
                end
            end
        end
    end

    FixEverything()
    NukeUINew()

    local function FinalProcess(character)
        local root = character:WaitForChild("HumanoidRootPart", 15)
        if root then
            task.wait(3)
            root.CFrame = CFrame.new(TargetCoords)
        end
    end

    LocalPlayer.CharacterAdded:Connect(FinalProcess)
    task.wait(0.5)
    if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end

    task.spawn(function()
        while GodModActive do
            NukeUINew()
            task.wait(5)
        end
    end)
end

MiscTab:CreateButton({
    Name = "Good Mode",
    Callback = function()
        RunGodMod()
    end
})
