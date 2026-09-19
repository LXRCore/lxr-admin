--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-ADMIN — Server: every action checked and logged here
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local A = LXRAdmin
local RES = GetCurrentResourceName()
local buckets = {}

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end
local function has(src) return function(g) return LXRCore.Perms.Has(src, g) end end
local function may(src, action) return A.Allowed(action, has(src)) end
local function player(src) return LXRCore.Functions.GetPlayer(src) end
local function nameOf(P) local c = P.PlayerData.charinfo or {} return ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s+', '') end
local function log(src, action, target, detail)
    if Config.Debug.log then LXRCore.Log.info('admin', ('%s %s → %s %s'):format(GetPlayerName(src) or src, action, tostring(target or '-'), detail or ''), { source = src }) end
    LXRCore.Emit('lxr:admin:action', nil, src, action, target, detail)
end
local function groupsOf(src)
    local out = {}
    for _, g in ipairs(A.Tiers()) do if LXRCore.Perms.Has(src, g) then out[#out + 1] = g end end
    return out
end
local function mine(src)
    local out = {}
    for _, a in ipairs(A.Actions()) do out[a] = may(src, a) end
    return out
end

local function players()
    local out = {}
    for _, id in ipairs(GetPlayers()) do
        local n = tonumber(id)
        local P = player(n)
        local ped = GetPlayerPed(n)
        local c = ped ~= 0 and GetEntityCoords(ped) or vector3(0, 0, 0)
        out[#out + 1] = { id = n, account = GetPlayerName(n), name = P and nameOf(P) or '', job = P and P.PlayerData.job.label or '', citizenid = P and P.PlayerData.citizenid or '', ping = GetPlayerPing(n), x = c.x, y = c.y, z = c.z, groups = groupsOf(n) }
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function server()
    local weather, nextW = nil, nil
    if GetResourceState('lxr-weather') == 'started' then weather, nextW = exports['lxr-weather']:GetWeather() end
    local cal = GlobalState.calendar
    return { players = #GetPlayers(), max = GetConvarInt('sv_maxclients', 32), uptime = math.floor(GetGameTimer() / 60000), weather = weather, nextWeather = nextW, hour = cal and cal.hour, minute = cal and cal.minute, season = cal and cal.season, frozen = cal and cal.frozen }
end

LXR.RPC.Register('lxr-admin:open', function(src)
    if not may(src, 'open') then return false, 'denied' end
    return true, { players = players(), server = server(), me = mine(src), groups = groupsOf(src), tiers = A.Tiers() }
end)
LXR.RPC.Register('lxr-admin:players', function(src)
    if not may(src, 'players') then return false, 'denied' end
    return true, players()
end)
LXR.RPC.Register('lxr-admin:bans', function(src)
    if not may(src, 'ban') then return false, 'denied' end
    local rows = LXRCore.DB.Query('SELECT id, name, reason, expire, bannedby FROM bans ORDER BY id DESC LIMIT 100') or {}
    return true, rows
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎯 PLAYER ACTIONS
-- ═══════════════════════════════════════════════════════════════════════════════
local actions = {}

actions.go = function(src, T) local ped = GetPlayerPed(T) if ped == 0 then return false, 'gone' end local c = GetEntityCoords(ped) TriggerClientEvent('lxr-admin:client:teleport', src, c.x, c.y, c.z) return true end
actions.bring = function(src, T) local ped = GetPlayerPed(src) if ped == 0 then return false, 'gone' end local c = GetEntityCoords(ped) TriggerClientEvent('lxr-admin:client:teleport', T, c.x, c.y, c.z) return true end
actions.freeze = function(src, T, args) TriggerClientEvent('lxr-admin:client:freeze', T, args.on ~= false) return true end
actions.warn = function(src, T, args) LXRCore.Notify(T, Lang:t('info.warned', { reason = tostring(args.reason or '') }), 'warning', 8000) return true end
actions.heal = function(src, T) TriggerClientEvent('lxr-admin:client:heal', T) return true end
actions.revive = function(src, T) if GetResourceState('lxr-doctor') == 'started' then exports['lxr-doctor']:Revive(T) else TriggerClientEvent('lxr-admin:client:heal', T) end return true end
actions.kick = function(src, T, args) LXRCore.Functions.Kick(T, Lang:t('info.kicked', { reason = tostring(args.reason or ''), by = GetPlayerName(src) })) return true end
actions.ban = function(src, T, args)
    local expire = A.Expire(args.hours, os.time())
    LXRCore.DB.InsertAsync('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(T), GetPlayerIdentifierByType(T, 'license'), GetPlayerIdentifierByType(T, 'discord'), GetPlayerIdentifierByType(T, 'ip'), tostring(args.reason or ''), expire, GetPlayerName(src) })
    DropPlayer(T, Lang:t('info.banned', { reason = tostring(args.reason or ''), discord = LXRCore.Brand.discord or '' }))
    return true
end
actions.give = function(src, T, args)
    local P = player(T)
    local def = LXRShared.Items[tostring(args.item or ''):lower()]
    if not P or not def then return false, 'no_item' end
    local n = math.max(1, math.floor(tonumber(args.amount) or 1))
    if not P.Functions.AddItem(def.name, n, nil, nil, 'admin:give') then return false, 'too_heavy' end
    return true
end
actions.job = function(src, T, args)
    local P = player(T)
    local job = tostring(args.job or ''):lower()
    if not P or not LXRShared.Jobs[job] then return false, 'no_job' end
    P.Functions.SetJob(job, tonumber(args.grade) or 0)
    return true
end
actions.money = function(src, T, args)
    local P = player(T)
    local account, amount = tostring(args.account or 'cash'), tonumber(args.amount) or 0
    if not P or not Config.Money.MoneyTypes[account] or amount == 0 then return false, 'no_money' end
    if amount > 0 then P.Functions.AddMoney(account, amount, 'admin') else P.Functions.RemoveMoney(account, -amount, 'admin') end
    return true
end

LXR.RPC.Register('lxr-admin:action', function(src, action, target, args)
    if limited(src) then return false, 'rate' end
    local fn = actions[action]
    if not fn or not may(src, action) then return false, 'denied' end
    local T = tonumber(target)
    if not T or not GetPlayerName(T) then return false, 'gone' end
    args = type(args) == 'table' and args or {}
    local ok, err = fn(src, T, args)
    if ok then log(src, action, T, args.reason or args.item or args.job or args.account) end
    return ok, err
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🌍 SERVER + ME
-- ═══════════════════════════════════════════════════════════════════════════════
LXR.RPC.Register('lxr-admin:server', function(src, what, args)
    if limited(src) then return false, 'rate' end
    args = type(args) == 'table' and args or {}
    if what == 'announce' then
        if not may(src, 'announce') then return false, 'denied' end
        LXRCore.Notify(-1, tostring(args.text or ''), 'info', 10000)
    elseif what == 'weather' then
        if not may(src, 'weather') or GetResourceState('lxr-weather') ~= 'started' then return false, 'denied' end
        if not exports['lxr-weather']:SetWeather(tostring(args.kind or '')) then return false, 'no_weather' end
    elseif what == 'time' then
        if not may(src, 'time') or GetResourceState('lxr-weather') ~= 'started' then return false, 'denied' end
        if args.freeze ~= nil then exports['lxr-weather']:FreezeTime(args.freeze == true) else exports['lxr-weather']:SetTime(tonumber(args.hour) or 12, tonumber(args.minute) or 0) end
    else return false, 'denied' end
    log(src, what, nil, args.text or args.kind or tostring(args.hour or args.freeze))
    return true, server()
end)

---the client asks before turning a self-tool on; the answer is the permission, and the log line
LXR.RPC.Register('lxr-admin:me', function(src, tool, on)
    if limited(src) then return false, 'rate' end
    if not may(src, tool) then return false, 'denied' end
    if tool == 'noclip' or tool == 'god' or tool == 'invisible' then Player(src).state:set('staff_' .. tool, on == true, true) end   -- lxr-warden reads these
    log(src, tool, src, on and 'on' or 'off')
    return true
end)

LXR.RPC.Register('lxr-admin:unban', function(src, id)
    if limited(src) or not may(src, 'unban') then return false, 'denied' end
    LXRCore.DB.Update('DELETE FROM bans WHERE id = ?', { tonumber(id) or 0 })
    log(src, 'unban', id)
    return true
end)

-- chat shortcuts for the desk's most used actions: /revive [id], /heal [id], /freeze [id], /bring <id>, /goto <id>
-- (no id = yourself where that makes sense); the same permission tiers as the panel
local function quick(cmd, action, selfOk, extra)
    LXRCore.Commands.Add(cmd, Lang:t('command.' .. cmd), { { name = 'id', help = Lang:t('command.id') } }, false, function(src, args)
        local T = tonumber(args[1]) or (selfOk and src) or nil
        if not T or not GetPlayerName(T) then return LXRCore.Notify(src, Lang:t('error.gone'), 'error') end
        if not may(src, action) then return LXRCore.Notify(src, Lang:t('error.denied'), 'error') end
        local ok, err = actions[action](src, T, extra or {})
        if ok then log(src, action, T) LXRCore.Notify(src, Lang:t('info.done'), 'success') else LXRCore.Notify(src, Lang:t('error.' .. tostring(err)), 'error') end
    end, 'admin')
end
quick('revive', 'revive', true)
quick('heal', 'heal', true)
quick('freeze', 'freeze', false)
quick('unfreeze', 'freeze', false, { on = false })
quick('bring', 'bring', false)
quick('goto', 'go', false)
-- /whoami — your tier and identifiers, for anyone (the answer to "why is /revive denied")
LXRCore.Commands.Add('whoami', Lang:t('command.whoami'), {}, false, function(src)
    local ids = {}
    for _, id in ipairs(GetPlayerIdentifiers(src)) do if not id:find('^ip:') then ids[#ids + 1] = id end end
    local tier = LXRCore.Perms.Group(src)
    LXRCore.Notify(src, Lang:t('info.whoami', { tier = tier }), tier == 'user' and 'error' or 'success', 8000)
    LXRCore.Log.info('admin', ('whoami %s: tier %s, %s'):format(GetPlayerName(src) or src, tier, table.concat(ids, ' ')), { source = src })
end, 'user')

AddEventHandler('playerDropped', function() buckets[source] = nil end)
CreateThread(function() if Config.Debug.printBanner then print(('^1[lxr-admin]^7 v%s — %d actions, tiers %s'):format(GetResourceMetadata(RES, 'version', 0), #A.Actions(), table.concat(A.Tiers(), ' > '))) end end)
exports('May', may)
exports('Players', players)
