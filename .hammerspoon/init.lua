-- Inspired by
-- https://github.com/digitalbase/hammerspoon/blob/master/init.lua
-------------------------------------------------------------------------------
-- imported spoons
-------------------------------------------------------------------------------
hs.loadSpoon("SpoonInstall")

hs.loadSpoon("Lunette")
local customBindings = {
    undo = false,
    topLeft = false,
    topRight = false,
    bottomLeft = false,
    bottomRight = false,
    leftHalf = {{{"cmd", "ctrl"}, "left"}},
    rightHalf = {{{"cmd", "ctrl"}, "right"}}
}
spoon.Lunette:bindHotkeys(customBindings)

spoon.SpoonInstall:andUse("PushToTalk", {
    start = true,
    config = {app_switcher = {['Slack'] = 'push-to-talk'}}
})

-- helper function
local forEach = function(config, fun) hs.fnutils.each(config, fun) end
local getOrElse = function(optional, alternative)
    if (optional == nil) then
        return alternativ
    else
        return optional
    end
end

-------------------------------------------------------------------------------
-- menu
-------------------------------------------------------------------------------
-- menuHammer = hs.loadSpoon("MenuHammer")
-- menuHammer:enter()

-------------------------------------------------------------------------------
-- generic configuration
-------------------------------------------------------------------------------
hs.window.animationDuration = 0
hs.application.enableSpotlightForNameSearches(true)

ext = {frame = {}, win = {}, app = {}, utils = {}, cache = {}, watchers = {}}
local baseCombination = {"cmd", "shift"}

-------------------------------------------------------------------------------
-- reload configuration
-------------------------------------------------------------------------------
hs.hotkey.bind(baseCombination, "R", function()
    hs.reload()
    print('config reloaded')
end)

-------------------------------------------------------------------------------
-- launch or focus applications with shortkey
-------------------------------------------------------------------------------
local keyToAppConfig = {
    {key = "e", app = "IntelliJ IDEA"}, {key = "d", app = "Slack"},
    {key = "m", app = "Mail"}, {key = "f", app = "Firefox"},
    {key = "c", app = "Calendar"}, {key = "s", app = "Spotify"},
    {key = "v", app = "Visual Studio Code"}, {key = "b", app = "Bear"},
    {key = "n", app = "Nozbe"}, {key = "x", app = "Google Chrome"},
    {key = "z", app = "Signal"}, {key = "w", app = "Warp"}
}
forEach(keyToAppConfig, function(object)
    hs.hotkey.bind(baseCombination, object.key,
                   function() ext.app.forceLaunchOrFocus(object.app) end)
end)

-------------------------------------------------------------------------------
-- push active window to monitor
-------------------------------------------------------------------------------
local laptopMonitorId = nil
if(hs.screen.find("Retina Display") ~= nil) then
    laptopMonitorId = hs.screen.find("Retina Display"):id()
end 
local primaryMonitor = hs.screen.primaryScreen()
local primaryMonitorId = primaryMonitor:id()
local secondaryMonitorId = nil
if (primaryMonitor:toEast() ~= nil) then
    secondaryMonitorId = primaryMonitor:toEast():id()
elseif (primaryMonitor:toWest() ~= nil) then
    secondaryMonitorId = primaryMonitor:toWest():id()
end


local monitorsConfig = {
    {key = "1", monitor = laptopMonitorId},
    {key = "2", monitor = primaryMonitorId},
    {key = "3", monitor = secondaryMonitorId}
}

forEach(monitorsConfig, function(config)
    hs.hotkey.bind(baseCombination, config.key, function()
        moveWindowTo({
            appName = hs.window.focusedWindow():application():name(),
            monitor = config.monitor
        })
    end)
end)

-------------------------------------------------------------------------------
-- push windows to default layout
-------------------------------------------------------------------------------
local defaltSetupConfig = {
    {appName = "Firefox", monitor = primaryMonitorId},
    {appName = "Slack", monitor = laptopMonitorId},
    {appName = "Mail", monitor = primaryMonitorId},
    {appName = "Calendar", monitor = primaryMonitorId},
    {appName = "IntelliJ IDEA", monitor = primaryMonitorId},
    {appName = "Spotify", monitor = laptopMonitorId}
}

hs.hotkey.bind(baseCombination, "0",
               function() moveWindowsToScreen(defaltSetupConfig) end)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- functions
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- https://github.com/szymonkaliski/Dotfiles/blob/b5a640336efc9fde1e8048c2894529427746076f/Dotfiles/hammerspoon/init.lua#L411-L440
function ext.app.forceLaunchOrFocus(appName)
    -- first focus with hammerspoon
    hs.application.launchOrFocus(appName)

    -- clear timer if exists
    if ext.cache.launchTimer then ext.cache.launchTimer:stop() end

    -- wait 500ms for window to appear and try hard to show the window
    ext.cache.launchTimer = hs.timer.doAfter(0.8, function()
        local frontmostApp = hs.application.frontmostApplication()
        local frontmostWindows = hs.fnutils.filter(frontmostApp:allWindows(),
                                                   function(win)
            return win:isStandard()
        end)

        -- break if this app is not frontmost (when/why?)
        if frontmostApp:title() ~= appName then
            print('Expected app in front: ' .. appName .. ' got: ' ..
                      frontmostApp:title())
            return
        end

        if #frontmostWindows == 0 then
            -- check if there's app name in window menu (Calendar, Messages, etc...)
            if frontmostApp:findMenuItem({'Window', appName}) then
                -- select it, usually moves to space with this window
                frontmostApp:selectMenuItem({'Window', appName})
            else
                -- otherwise send cmd-n to create new window
                hs.eventtap.keyStroke({'cmd'}, 'n')
            end
        end
    end)
end

function moveWindowsToScreen(configs) hs.fnutils.each(configs, moveWindowTo) end

-- config: 
--     {
--        appName = "Firefox", 
--        monitor = [left|right|laptop](monitor_id)
--     }
function moveWindowTo(config)
    local app = hs.application.find(config.appName)
    if (app) then
        local wins = app:allWindows()
        local counter = 1
        for j, win in ipairs(wins) do
            if (win:isVisible()) then
                pushWindow(win, 0, 0, 1, 1)
                win:moveToScreen(hs.screen.find(config.monitor))
                counter = counter + 1
            end
        end
    end
end

-- parpams
-- x,y - screen point
-- w,h - percentage of widht/heigh
function pushWindow(win, x, y, w, h)
    local f = win:frame()
    local screen = win:screen()
    local max = screen:frame()

    f.x = max.x + (max.w * x)
    f.y = max.y + (max.h * y)
    f.w = max.w * w
    f.h = max.h * h
    win:setFrame(f)
end

