local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local remoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local player = game.Players.LocalPlayer

-- Assuming RemoteEvent also exists for voting
local remoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

-- --- Initial Game Entry / Lobby Check ---
if workspace:FindFirstChild("Elevators") then
    local args = {
        [1] = "Multiplayer",
        [2] = "v2:start",
        [3] = {
            ["count"] = 1,
            ["mode"] = "hardcore"
        }
    }
    remoteFunction:InvokeServer(unpack(args))
    task.wait(3) -- Give time for the server to move you to the match lobby
else
    remoteFunction:InvokeServer("Voting", "Skip")
    task.wait(1)
end

-- --- Cash Retrieval Functions ---
local guiPath = player:WaitForChild("PlayerGui")
    :WaitForChild("ReactUniversalHotbar")
    :WaitForChild("Frame")
    :WaitForChild("values")
    :WaitForChild("cash")
    :WaitForChild("amount")

local function getCash()
    local rawText = guiPath.Text or ""
    local cleaned = rawText:gsub("[^%d%-]", "")
    return tonumber(cleaned) or 0
end

local function waitForCash(minAmount)
    while getCash() < minAmount do
        task.wait(1)
    end
end

-- --- Safe Remote Invocation Helpers (No console output from these) ---
local function safeInvoke(args, cost)
    if cost then
        waitForCash(cost)
    end
    pcall(function()
        remoteFunction:InvokeServer(unpack(args))
    end)
    task.wait(1)
end

local function safeFire(args)
    pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)
    task.wait(1)
end

-- --- Lobby Actions (After Game Join / Teleport to Pre-Match Lobby) ---
task.wait(5)

-- Map Override
safeInvoke({
    "LobbyVoting",
    "Override",
    "Crossroads"
})
task.wait(1)

-- Vote for Wrecked Battlefield II
safeFire({
    "LobbyVoting",
    "Vote",
    "Crossroads",
    Vector3.new(15.260380744934082, 9.839303970336914, 57.945106506347656)
})
task.wait(1)

-- Vote Ready
safeInvoke({
    "LobbyVoting",
    "Ready"
})
task.wait(5)

-- Ensure character is loaded and get necessary parts
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
task.wait(2)

-- --- In-Match Tower Placement (Wrecked Battlefield II) ---
local placementSequence = {
    -- Pyromancer cost UPDATED to 1200
    { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(-3.2550888061523438, 1.0000081062316895, -3.3469676971435547) }, "Pyromancer" }, cost = 1200 },
    -- 5 Crook Bosses (Cost 900 each)
    { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(11.034339904785156, 0.9999979734420776, 12.387344360351562) }, "Crook Boss" }, cost = 900 },
    { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(10.406021118164062, 0.9999985694885254, 8.785298347473145) }, "Crook Boss" }, cost = 900 },
    { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(8.283954620361328, 0.999998152256012, 11.18062973022461) }, "Crook Boss" }, cost = 900 },
    { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(7.28225040435791, 0.9999986886978149, 7.725786209106445) }, "Crook Boss" }, cost = 900 },
    { args = { "Troops", "Pl\208\176ce", { Rotation = CFrame.new(), Position = Vector3.new(9.900857925415039, 0.9999990463256836, 5.724668502807617) }, "Crook Boss" }, cost = 900 },
}

for _, step in ipairs(placementSequence) do
    safeInvoke(step.args, step.cost)
end

-- --- Parallel Upgrade Loop and Timers ---
local upgradeDone = false
task.spawn(function()
    local towerFolder = workspace:WaitForChild("Towers", 600)
    if not towerFolder then return end
    local maxedTowers = {}

    while not upgradeDone do
        local towers = towerFolder:GetChildren()
        for i, tower in ipairs(towers) do
            if not maxedTowers[tower] then
                local args = {
                    "Troops",
                    "Upgrade",
                    "Set",
                    {
                        Troop = tower,
                        Path = 1
                    }
                }
                local success, err = pcall(function()
                    remoteFunction:InvokeServer(unpack(args))
                end)
                if not success and string.find(tostring(err), "Max Level", 1, true) then
                    maxedTowers[tower] = true
                end
            end
        end
        task.wait(1)
    end
end)

task.wait(400)

upgradeDone = true
task.wait(1)


TeleportService:Teleport(3260590327)
