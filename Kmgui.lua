local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local CONFIG = {
    Language = "RU",
    Theme = "Red",
    Scale = 1,
    Transparency = 0.08,
    AimRadius = 120,
    AimSensitivity = 0.5,
    EventFilter = "",
    LogLimit = 250,
}

local COLORS = {
    bg = Color3.fromRGB(15, 12, 16),
    panel = Color3.fromRGB(25, 17, 22),
    panel2 = Color3.fromRGB(36, 22, 29),
    red = Color3.fromRGB(242, 54, 76),
    red2 = Color3.fromRGB(173, 29, 49),
    text = Color3.fromRGB(245, 238, 241),
    muted = Color3.fromRGB(173, 151, 160),
    green = Color3.fromRGB(100, 220, 150),
    yellow = Color3.fromRGB(255, 202, 92),
}

local STR = {
    RU = {
        title="NEXUS AC LAB", subtitle="MOBILE DIAGNOSTICS",
        dashboard="Обзор", aim="Aim Lab", movement="Движение",
        remotes="Remote Inspector", monitor="AC Monitor", settings="Настройки",
        ready="Готово к диагностике", localonly="Клиентский режим",
        crosshair="Тестовый прицел", radius="Радиус прицела",
        sensitivity="Чувствительность (визуальная)", showcross="Показать прицел",
        movementnow="Текущее движение", walkspeed="WalkSpeed",
        jumppower="JumpPower", state="Состояние", collision="Столкновения",
        refresh="Обновить список", search="Поиск функций / событий...",
        eventsearch="Фильтр Remote-объектов...", remotelist="Доступные Remote-объекты",
        calllog="Журнал тестовых событий", clear="Очистить журнал",
        export="Экспорт отчёта", nofeed="Серверный AC feed не найден",
        nofeedhint="Для серверных обнаружений игра должна предоставить ReplicatedStorage.ACMonitorFeed.",
        args="Аргументы безопасно не перехватываются автоматически",
        limits="Ограничения", language="Язык", scale="Размер интерфейса",
        transparency="Прозрачность панели", refreshhint="Список отражает только доступные клиенту объекты.",
        aimhint="Aim Lab — визуальный прицел. Автоматическое наведение на игроков не выполняется.",
        movehint="Только чтение локальных свойств; значения не изменяются.",
        remotelimit="Не отправляет Remote-вызовы и не перехватывает вызовы других скриптов.",
        monitorhint="Показываются только события, которые собственная игра явно передаёт клиенту.",
        enabled="Включено", disabled="Выключено", yes="Да", no="Нет",
        fly="Полёт", teleport="Телепортация", speed="Скорость",
        normal="Наблюдение", unknown="Неизвестно", copied="Отчёт подготовлен в поле ниже.",
        exportbox="Текст отчёта (можно выделить и скопировать)",
        tabsearch="Найденные разделы", remoteCount="Найдено объектов",
        status="Статус", time="Время", name="Название", result="Результат",
        safe="Безопасный режим", close="Свернуть", open="Открыть",
    },
    EN = {
        title="NEXUS AC LAB", subtitle="MOBILE DIAGNOSTICS",
        dashboard="Overview", aim="Aim Lab", movement="Movement",
        remotes="Remote Inspector", monitor="AC Monitor", settings="Settings",
        ready="Ready for diagnostics", localonly="Client-side mode",
        crosshair="Training crosshair", radius="Crosshair radius",
        sensitivity="Sensitivity (visual)", showcross="Show crosshair",
        movementnow="Current movement", walkspeed="WalkSpeed",
        jumppower="JumpPower", state="State", collision="Collision",
        refresh="Refresh list", search="Search features / events...",
        eventsearch="Filter Remote objects...", remotelist="Available Remote objects",
        calllog="Test event log", clear="Clear log",
        export="Export report", nofeed="Server AC feed not found",
        nofeedhint="The game must provide ReplicatedStorage.ACMonitorFeed for server detections.",
        args="Arguments are not automatically intercepted",
        limits="Limitations", language="Language", scale="UI scale",
        transparency="Panel transparency", refreshhint="Only client-accessible objects are listed.",
        aimhint="Aim Lab is a visual crosshair. It does not auto-aim at players.",
        movehint="Reads local properties only; does not modify values.",
        remotelimit="Does not send remote calls or intercept other scripts.",
        monitorhint="Only events explicitly sent to this client by your own game are shown.",
        enabled="Enabled", disabled="Disabled", yes="Yes", no="No",
        fly="Flight", teleport="Teleport", speed="Speed",
        normal="Observe", unknown="Unknown", copied="Report prepared in the field below.",
        exportbox="Report text (select and copy)",
        tabsearch="Matching sections", remoteCount="Objects found",
        status="Status", time="Time", name="Name", result="Result",
        safe="Safe mode", close="Collapse", open="Open",
    }
}
local function T(key)
    return (STR[CONFIG.Language] and STR[CONFIG.Language][key]) or STR.RU[key] or key
end

local function safeString(v)
    local ok, s = pcall(function() return tostring(v) end)
    if not ok then return "<unavailable>" end
    s = s:gsub("[%c]", " ")
    if #s > 140 then s = s:sub(1, 137) .. "..." end
    return s
end

local logs = {}
local function addLog(category, name, result, details)
    local entry = {
        time = os.date("%H:%M:%S"),
        category = safeString(category),
        name = safeString(name),
        result = safeString(result),
        details = safeString(details or ""),
    }
    table.insert(logs, 1, entry)
    while #logs > CONFIG.LogLimit do table.remove(logs) end
end

local oldGui = nil
pcall(function()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then
        oldGui = pg:FindFirstChild("NexusACLab")
        if oldGui then oldGui:Destroy() end
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "NexusACLab"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = false
pcall(function()
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    parented = true
end)
if not parented then
    -- Some executors expose gethui; this is optional and executor-specific.
    pcall(function()
        if gethui then gui.Parent = gethui(); parented = true end
    end)
end
if not parented then return end

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
end
local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.red
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.15
    s.Parent = obj
end
local function newText(parent, text, size, bold, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextColor3 = color or COLORS.text
    l.TextSize = size or 14
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end
local function newButton(parent, text, size)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = true
    b.Text = text
    b.TextColor3 = COLORS.text
    b.TextSize = 13
    b.Font = Enum.Font.GothamSemibold
    b.BackgroundColor3 = COLORS.panel2
    b.Size = size or UDim2.new(1, 0, 0, 34)
    b.Parent = parent
    corner(b, 7)
    stroke(b, COLORS.red2, 1, 0.25)
    return b
end
local function newBox(parent, placeholder, size)
    local b = Instance.new("TextBox")
    b.ClearTextOnFocus = false
    b.PlaceholderText = placeholder or ""
    b.Text = ""
    b.TextColor3 = COLORS.text
    b.PlaceholderColor3 = COLORS.muted
    b.TextSize = 13
    b.Font = Enum.Font.Gotham
    b.BackgroundColor3 = COLORS.bg
    b.Size = size or UDim2.new(1, 0, 0, 34)
    b.Parent = parent
    corner(b, 7)
    stroke(b, COLORS.red2, 1, 0.35)
    return b
end
local function newPage(parent)
    local p = Instance.new("ScrollingFrame")
    p.Name = "Page"
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.Size = UDim2.new(1, -12, 1, -12)
    p.Position = UDim2.fromOffset(6, 6)
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = COLORS.red
    p.CanvasSize = UDim2.new()
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = p
    return p
end
local function section(parent, title)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = COLORS.panel
    f.BackgroundTransparency = 0.04
    f.Size = UDim2.new(1, -4, 0, 42)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Parent = parent
    corner(f, 9)
    stroke(f, COLORS.red2, 1, 0.45)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = f
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 9); pad.PaddingBottom = UDim.new(0, 9)
    pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = f
    local h = newText(f, title, 14, true, COLORS.red)
    h.Size = UDim2.new(1, 0, 0, 22)
    h.LayoutOrder = 1
    return f
end
local function addHint(parent, text)
    local l = newText(parent, text, 12, false, COLORS.muted)
    l.Size = UDim2.new(1, 0, 0, 42)
    l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.LayoutOrder = 99
    return l
end

local floating = newButton(gui, "N", UDim2.fromOffset(48, 48))
floating.Name = "NexusFloatingButton"
floating.Position = UDim2.new(0, 12, 0.45, 0)
floating.BackgroundColor3 = COLORS.red2
floating.TextSize = 20
floating.ZIndex = 20
corner(floating, 24)

local main = Instance.new("Frame")
main.Name = "MainPanel"
main.Size = UDim2.new(0, 340, 0, 440)
main.Position = UDim2.new(0, 68, 0.5, -220)
main.BackgroundColor3 = COLORS.bg
main.BackgroundTransparency = CONFIG.Transparency
main.Visible = true
main.Parent = gui
corner(main, 12); stroke(main, COLORS.red, 1.5, 0.08)
local scaleObj = Instance.new("UIScale")
scaleObj.Scale = CONFIG.Scale
scaleObj.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundColor3 = COLORS.panel
header.Parent = main
corner(header, 12)
local title = newText(header, T("title"), 17, true, COLORS.red)
title.Position = UDim2.fromOffset(12, 5); title.Size = UDim2.new(1, -60, 0, 25)
local subtitle = newText(header, T("subtitle") .. "  •  " .. T("safe"), 9, true, COLORS.muted)
subtitle.Position = UDim2.fromOffset(12, 30); subtitle.Size = UDim2.new(1, -60, 0, 16)
local close = newButton(header, "×", UDim2.fromOffset(32, 32))
close.Position = UDim2.new(1, -40, 0, 12)
close.TextSize = 20
close.BackgroundColor3 = COLORS.red2

local search = newBox(main, T("search"), UDim2.new(1, -16, 0, 32))
search.Position = UDim2.fromOffset(8, 64)

local nav = Instance.new("ScrollingFrame")
nav.Name = "Tabs"
nav.BackgroundTransparency = 1
nav.BorderSizePixel = 0
nav.Position = UDim2.fromOffset(8, 104)
nav.Size = UDim2.new(0, 105, 1, -112)
nav.ScrollBarThickness = 2
nav.ScrollBarImageColor3 = COLORS.red
nav.AutomaticCanvasSize = Enum.AutomaticSize.Y
nav.CanvasSize = UDim2.new()
nav.Parent = main
local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 5)
navLayout.Parent = nav

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(120, 104)
content.Size = UDim2.new(1, -128, 1, -112)
content.Parent = main

local pages = {}
local tabButtons = {}
local tabKeys = {"dashboard","aim","movement","remotes","monitor","settings"}
local currentTab = "dashboard"
local function setTab(key)
    currentTab = key
    for k, p in pairs(pages) do p.Visible = (k == key) end
    for k, b in pairs(tabButtons) do
        b.BackgroundColor3 = k == key and COLORS.red2 or COLORS.panel2
    end
end
for _, key in ipairs(tabKeys) do
    local b = newButton(nav, T(key), UDim2.new(1, -3, 0, 36))
    b.TextSize = 11
    b.MouseButton1Click:Connect(function() setTab(key) end)
    tabButtons[key] = b
    pages[key] = newPage(content)
end

-- Dashboard
do
    local p = pages.dashboard
    local s = section(p, T("ready"))
    local status = newText(s, T("localonly") .. " • " .. T("safe"), 12, false, COLORS.green)
    status.Size = UDim2.new(1, 0, 0, 22); status.LayoutOrder = 2
    local summary = newText(s, "NEXUS AC LAB / Red Cyber", 12, false, COLORS.muted)
    summary.Size = UDim2.new(1, 0, 0, 22); summary.LayoutOrder = 3
    local s2 = section(p, T("limits"))
    addHint(s2, T("remotelimit") .. " " .. T("refreshhint"))
    local refreshBtn = newButton(s2, T("refresh"))
    refreshBtn.LayoutOrder = 3
    refreshBtn.MouseButton1Click:Connect(function()
        addLog("UI", "Refresh", "Requested", "Remote list refresh")
    end)
end

-- Aim Lab: visual-only crosshair; no target tracking or player auto-aim.
local crosshairEnabled = true
local crosshairGui = Instance.new("Frame")
crosshairGui.Name = "TrainingCrosshair"
crosshairGui.BackgroundTransparency = 1
crosshairGui.Size = UDim2.fromOffset(200, 200)
crosshairGui.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairGui.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairGui.Parent = gui
local circle = Instance.new("Frame")
circle.Name = "Radius"
circle.BackgroundTransparency = 1
circle.Size = UDim2.fromOffset(CONFIG.AimRadius * 2, CONFIG.AimRadius * 2)
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.Parent = crosshairGui
corner(circle, 100); stroke(circle, COLORS.red, 1, 0.35)
local function crossLine(size, pos)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = COLORS.red
    f.BorderSizePixel = 0
    f.Size = size; f.Position = pos; f.Parent = crosshairGui
    return f
end
crossLine(UDim2.fromOffset(2, 14), UDim2.new(0.5, -1, 0.5, -20))
crossLine(UDim2.fromOffset(2, 14), UDim2.new(0.5, -1, 0.5, 6))
crossLine(UDim2.fromOffset(14, 2), UDim2.new(0.5, -20, 0.5, -1))
crossLine(UDim2.fromOffset(14, 2), UDim2.new(0.5, 6, 0.5, -1))
do
    local p = pages.aim
    local s = section(p, T("crosshair"))
    local toggle = newButton(s, T("showcross") .. ": " .. T("enabled"))
    toggle.LayoutOrder = 2
    toggle.MouseButton1Click:Connect(function()
        crosshairEnabled = not crosshairEnabled
        crosshairGui.Visible = crosshairEnabled
        toggle.Text = T("showcross") .. ": " .. (crosshairEnabled and T("enabled") or T("disabled"))
        addLog("Aim Lab", "Crosshair", crosshairEnabled and "Enabled" or "Disabled")
    end)
    local radiusLabel = newText(s, T("radius") .. ": " .. CONFIG.AimRadius, 12, false)
    radiusLabel.Size = UDim2.new(1, 0, 0, 20); radiusLabel.LayoutOrder = 3
    local radius = newButton(s, "− 20", UDim2.new(1, 0, 0, 30)); radius.LayoutOrder = 4
    local radiusPlus = newButton(s, "+ 20", UDim2.new(1, 0, 0, 30)); radiusPlus.LayoutOrder = 5
    local function updateRadius(delta)
        CONFIG.AimRadius = math.clamp(CONFIG.AimRadius + delta, 20, 300)
        circle.Size = UDim2.fromOffset(CONFIG.AimRadius*2, CONFIG.AimRadius*2)
        radiusLabel.Text = T("radius") .. ": " .. CONFIG.AimRadius
    end
    radius.MouseButton1Click:Connect(function() updateRadius(-20) end)
    radiusPlus.MouseButton1Click:Connect(function() updateRadius(20) end)
    local sensLabel = newText(s, T("sensitivity") .. ": " .. CONFIG.AimSensitivity, 12, false)
    sensLabel.Size = UDim2.new(1, 0, 0, 20); sensLabel.LayoutOrder = 6
    local sensDown = newButton(s, "− 0.1"); sensDown.LayoutOrder = 7
    local sensUp = newButton(s, "+ 0.1"); sensUp.LayoutOrder = 8
    local function updateSens(d)
        CONFIG.AimSensitivity = math.clamp(math.floor((CONFIG.AimSensitivity+d)*10+0.5)/10, 0.1, 1)
        sensLabel.Text = T("sensitivity") .. ": " .. CONFIG.AimSensitivity
    end
    sensDown.MouseButton1Click:Connect(function() updateSens(-0.1) end)
    sensUp.MouseButton1Click:Connect(function() updateSens(0.1) end)
    addHint(s, T("aimhint"))
end

-- Movement diagnostics: observe only.
local movementLabel
do
    local p = pages.movement
    local s = section(p, T("movementnow"))
    movementLabel = newText(s, "…", 12, false)
    movementLabel.Size = UDim2.new(1, 0, 0, 100)
    movementLabel.TextYAlignment = Enum.TextYAlignment.Top
    movementLabel.TextWrapped = true
    movementLabel.LayoutOrder = 2
    local s2 = section(p, T("calllog"))
    local runTest = newButton(s2, "Run local snapshot")
    runTest.LayoutOrder = 2
    runTest.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and root then
            addLog("Movement", "Snapshot", "OK",
                "WalkSpeed="..safeString(hum.WalkSpeed).."; JumpPower="..safeString(hum.JumpPower)
                .."; RootAnchored="..safeString(root.Anchored))
        else
            addLog("Movement", "Snapshot", "Unavailable", "Character or Humanoid missing")
        end
    end)
    addHint(s, T("movehint"))
end

-- Remote Inspector: enumerate visible objects only; do not invoke them or claim interception.
local remoteSearch
local remoteList
local remoteCountLabel
local function isRemote(obj)
    return obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
end
local function rebuildRemoteList()
    if not remoteList then return end
    for _, child in ipairs(remoteList:GetChildren()) do child:Destroy() end
    local query = (remoteSearch and remoteSearch.Text or ""):lower()
    local count = 0
    local remotes = {}
    local ok, descendants = pcall(function() return ReplicatedStorage:GetDescendants() end)
    if ok then
        for _, obj in ipairs(descendants) do
            if isRemote(obj) then
                local path = obj:GetFullName()
                if query == "" or path:lower():find(query, 1, true) then
                    table.insert(remotes, {name=obj.Name, path=path, class=obj.ClassName})
                end
            end
        end
    end
    table.sort(remotes, function(a,b) return a.path < b.path end)
    for _, info in ipairs(remotes) do
        count = count + 1
        local row = Instance.new("Frame")
        row.BackgroundColor3 = COLORS.panel2
        row.Size = UDim2.new(1, -2, 0, 54)
        row.Parent = remoteList
        corner(row, 6)
        local n = newText(row, info.name .. "  [" .. info.class .. "]", 11, true, COLORS.text)
        n.Position = UDim2.fromOffset(6, 3); n.Size = UDim2.new(1, -12, 0, 20)
        local path = newText(row, info.path, 9, false, COLORS.muted)
        path.Position = UDim2.fromOffset(6, 24); path.Size = UDim2.new(1, -12, 0, 25)
        path.TextWrapped = true
        path.TextTruncate = Enum.TextTruncate.AtEnd
    end
    remoteCountLabel.Text = T("remoteCount") .. ": " .. tostring(count)
end
do
    local p = pages.remotes
    local s = section(p, T("remotelist"))
    remoteCountLabel = newText(s, T("remoteCount") .. ": 0", 11, false, COLORS.muted)
    remoteCountLabel.Size = UDim2.new(1, 0, 0, 20); remoteCountLabel.LayoutOrder = 2
    remoteSearch = newBox(s, T("eventsearch"))
    remoteSearch.LayoutOrder = 3
    local refresh = newButton(s, T("refresh")); refresh.LayoutOrder = 4
    remoteList = Instance.new("Frame")
    remoteList.BackgroundTransparency = 1
    remoteList.Size = UDim2.new(1, 0, 0, 10)
    remoteList.AutomaticSize = Enum.AutomaticSize.Y
    remoteList.Parent = s
    remoteList.LayoutOrder = 5
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4); listLayout.Parent = remoteList
    remoteSearch:GetPropertyChangedSignal("Text"):Connect(rebuildRemoteList)
    refresh.MouseButton1Click:Connect(function()
        rebuildRemoteList()
        addLog("Remote Inspector", "Refresh list", "Completed", "ReplicatedStorage descendants only")
    end)
    addHint(s, T("refreshhint") .. " " .. T("remotelimit"))
end

-- AC monitor only subscribes if the game's own client-visible feed exists.
local monitorText
local reportBox
do
    local p = pages.monitor
    local s = section(p, T("monitor"))
    monitorText = newText(s, T("nofeed"), 12, true, COLORS.yellow)
    monitorText.Size = UDim2.new(1, 0, 0, 30); monitorText.LayoutOrder = 2
    local hint = addHint(s, T("nofeedhint") .. " " .. T("monitorhint"))
    hint.LayoutOrder = 3
    local s2 = section(p, T("calllog"))
    local clearBtn = newButton(s2, T("clear")); clearBtn.LayoutOrder = 2
    clearBtn.MouseButton1Click:Connect(function()
        table.clear(logs)
        addLog("UI", "Log", "Cleared")
        monitorText.Text = "Log cleared • " .. os.date("%H:%M:%S")
    end)
    local exportBtn = newButton(s2, T("export")); exportBtn.LayoutOrder = 3
    exportBtn.MouseButton1Click:Connect(function()
        local report = {
            tool="NEXUS AC LAB Mobile Edition",
            generated=os.date("!%Y-%m-%dT%H:%M:%SZ"),
            language=CONFIG.Language,
            note="Client-side diagnostic log only; not a complete server audit.",
            events=logs,
        }
        local encoded = HttpService:JSONEncode(report)
        reportBox.Text = encoded
        addLog("Export", "JSON report", "Prepared", tostring(#encoded).." chars")
    end)
    reportBox = newBox(s2, T("exportbox"), UDim2.new(1, 0, 0, 110))
    reportBox.MultiLine = true
    reportBox.TextXAlignment = Enum.TextXAlignment.Left
    reportBox.TextYAlignment = Enum.TextYAlignment.Top
    reportBox.TextWrapped = true
    reportBox.LayoutOrder = 4
end

-- Settings
do
    local p = pages.settings
    local s = section(p, T("settings"))
    local langBtn = newButton(s, "Language: " .. CONFIG.Language); langBtn.LayoutOrder = 2
    langBtn.MouseButton1Click:Connect(function()
        CONFIG.Language = CONFIG.Language == "RU" and "EN" or "RU"
        langBtn.Text = T("language") .. ": " .. CONFIG.Language
        addLog("Settings", "Language", CONFIG.Language)
        -- Rebuild text labels/buttons by re-running script for a complete translation refresh.
        title.Text = T("title"); subtitle.Text = T("subtitle") .. "  •  " .. T("safe")
        for key, b in pairs(tabButtons) do b.Text = T(key) end
        search.PlaceholderText = T("search")
    end)
    local smaller = newButton(s, "− UI scale"); smaller.LayoutOrder = 3
    local bigger = newButton(s, "+ UI scale"); bigger.LayoutOrder = 4
    local function setScale(v)
        CONFIG.Scale = math.clamp(v, 0.75, 1.2)
        scaleObj.Scale = CONFIG.Scale
    end
    smaller.MouseButton1Click:Connect(function() setScale(CONFIG.Scale - 0.05) end)
    bigger.MouseButton1Click:Connect(function() setScale(CONFIG.Scale + 0.05) end)
    local lessTrans = newButton(s, "More opaque"); lessTrans.LayoutOrder = 5
    local moreTrans = newButton(s, "More transparent"); moreTrans.LayoutOrder = 6
    lessTrans.MouseButton1Click:Connect(function()
        CONFIG.Transparency = math.clamp(CONFIG.Transparency - 0.05, 0, 0.5)
        main.BackgroundTransparency = CONFIG.Transparency
    end)
    moreTrans.MouseButton1Click:Connect(function()
        CONFIG.Transparency = math.clamp(CONFIG.Transparency + 0.05, 0, 0.5)
        main.BackgroundTransparency = CONFIG.Transparency
    end)
    addHint(s, T("limits") .. ": " .. T("remotelimit"))
end

-- Search tabs by translated tab names. Does not search arbitrary executor functions.
search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = search.Text:lower()
    for key, button in pairs(tabButtons) do
        local name = T(key):lower()
        button.Visible = (q == "" or name:find(q, 1, true) ~= nil)
    end
end)

-- AC monitor feed: only listen to the explicitly named game-provided event.
local feed = ReplicatedStorage:FindFirstChild("ACMonitorFeed")
if feed and feed:IsA("RemoteEvent") then
    monitorText.Text = "ACMonitorFeed connected"
    monitorText.TextColor3 = COLORS.green
    feed.OnClientEvent:Connect(function(payload)
        -- Display only simple scalar fields to avoid dumping sensitive/arbitrary objects.
        if typeof(payload) == "table" then
            local category = safeString(payload.category or "AC")
            local name = safeString(payload.name or payload.rule or "Detection")
            local result = safeString(payload.result or payload.status or "Received")
            local details = safeString(payload.details or "")
            addLog(category, name, result, details)
        else
            addLog("AC feed", "Message", "Received", safeString(payload))
        end
    end)
end

local lastMoveUpdate = 0
RunService.Heartbeat:Connect(function(dt)
    lastMoveUpdate += dt
    if lastMoveUpdate < 0.5 then return end
    lastMoveUpdate = 0
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum and root and movementLabel then
        local collidable = root.CanCollide
        movementLabel.Text = T("walkspeed") .. ": " .. string.format("%.1f", hum.WalkSpeed)
            .. "\n" .. T("jumppower") .. ": " .. string.format("%.1f", hum.JumpPower)
            .. "\n" .. T("state") .. ": " .. safeString(hum:GetState())
            .. "\n" .. T("collision") .. ": " .. (collidable and T("yes") or T("no"))
            .. "\n" .. T("speed") .. " (assembly): " .. string.format("%.1f", root.AssemblyLinearVelocity.Magnitude)
    else
        movementLabel.Text = "Character unavailable"
    end
end)

local open = true
local function setOpen(v)
    open = v
    main.Visible = v
    floating.Text = v and "×" or "N"
end
floating.MouseButton1Click:Connect(function() setOpen(not open) end)
close.MouseButton1Click:Connect(function() setOpen(false) end)

-- Drag support for touch and mouse.
do
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

addLog("NEXUS", "Startup", "OK", "Client-side diagnostics loaded")
rebuildRemoteList()
setTab("dashboard")
