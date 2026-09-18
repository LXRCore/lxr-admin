--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-ADMIN — Client: the panel, and the tools on my own ped
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local LXR = exports['lxr-core']:GetLXR()
local N = Citizen.InvokeNative
local open, tools = false, { noclip = false, god = false, invisible = false }

local function toast(key, kind, vars) LXRCore.Notify(Lang:t(key, vars), kind or 'info') end
local function page(action, payload) SendNUIMessage({ action = action, payload = payload, brand = LXRCore.Brand, lang = Config.Lang, locale = Lang.bundle(), tools = tools }) end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🪟 PANEL
-- ═══════════════════════════════════════════════════════════════════════════════
local function close()
    if not open then return end
    open = false
    SetNuiFocus(false, false)
    page('close')
end
local function openPanel()
    if open then return close() end
    local ok, data = LXR.RPC.Server('lxr-admin:open')
    if not ok then return toast('error.' .. tostring(data), 'error') end
    open = true
    SetNuiFocus(true, true)
    page('open', data)
end

RegisterCommand(Config.Command.name, openPanel, false)
RegisterKeyMapping(Config.Command.name, 'LXR admin panel', 'keyboard', Config.Command.key)
RegisterNUICallback('close', function(_, cb) close() cb({ ok = true }) end)
RegisterNUICallback('players', function(_, cb) local ok, list = LXR.RPC.Server('lxr-admin:players') cb({ ok = ok, players = list }) end)
RegisterNUICallback('bans', function(_, cb) local ok, rows = LXR.RPC.Server('lxr-admin:bans') cb({ ok = ok, bans = rows }) end)
RegisterNUICallback('unban', function(d, cb) local ok, err = LXR.RPC.Server('lxr-admin:unban', d.id) cb({ ok = ok, error = err }) end)
RegisterNUICallback('action', function(d, cb)
    local ok, err = LXR.RPC.Server('lxr-admin:action', d.action, d.target, d.args)
    if not ok then toast('error.' .. tostring(err), 'error') else toast('info.done', 'success') end
    cb({ ok = ok, error = err })
end)
RegisterNUICallback('server', function(d, cb)
    local ok, res = LXR.RPC.Server('lxr-admin:server', d.what, d.args)
    if not ok then toast('error.' .. tostring(res), 'error') end
    cb({ ok = ok, server = ok and res or nil, error = (not ok) and res or nil })
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🧍 ON MY OWN PED
-- ═══════════════════════════════════════════════════════════════════════════════
local function teleport(x, y, z)
    local ped = PlayerPedId()
    local ent = IsPedOnMount(ped) and GetMount(ped) or (IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false)) or ped
    local ok, gz = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
    SetEntityCoords(ent, x, y, ok and gz + 0.5 or z, false, false, false, false)
end
RegisterNetEvent('lxr-admin:client:teleport', function(x, y, z) teleport(x, y, z) end)
RegisterNetEvent('lxr-admin:client:freeze', function(on) FreezeEntityPosition(PlayerPedId(), on == true) if on then toast('info.frozen', 'warning') else toast('info.unfrozen', 'info') end end)
RegisterNetEvent('lxr-admin:client:heal', function() local ped = PlayerPedId() SetEntityHealth(ped, GetEntityMaxHealth(ped)) N(0xC6258F41D86676E0, ped, 0, 100) N(0xC6258F41D86676E0, ped, 1, 100) end)  -- SetAttributeCoreValue health, stamina

local MOVE_LR, MOVE_UD, UP, DOWN, FAST = 0x4D8FB4C1, 0xFDA83190, 0xE8342FF2, 0xDE794E3E, 0x8FFC75D6
local function noclipLoop()
    local ped = PlayerPedId()
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    while tools.noclip do
        local rot = GetGameplayCamRot(2)
        SetEntityRotation(ped, 0.0, 0.0, rot.z, 2, true)
        local lr, ud = GetControlNormal(0, MOVE_LR), GetControlNormal(0, MOVE_UD)
        local up = (IsControlPressed(0, UP) and 1.0 or 0.0) - (IsControlPressed(0, DOWN) and 1.0 or 0.0)
        local speed = IsControlPressed(0, FAST) and Config.NoClip.fast or Config.NoClip.speed
        local pos = GetEntityCoords(ped)
        local yaw = math.rad(rot.z)
        local fx, fy = -math.sin(yaw), math.cos(yaw)
        local pitch = math.rad(rot.x)
        local nx = pos.x + (fx * -ud + fy * lr) * speed
        local ny = pos.y + (fy * -ud - fx * lr) * speed
        local nz = pos.z + (-ud * math.sin(pitch) * speed) + up * speed
        SetEntityCoords(ped, nx, ny, nz, false, false, false, false)
        Wait(0)
    end
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, tools.god)
end

local function setTool(tool, on)
    local ok, err = LXR.RPC.Server('lxr-admin:me', tool, on)
    if not ok then toast('error.' .. tostring(err), 'error') return false end
    tools[tool] = on
    local ped = PlayerPedId()
    if tool == 'noclip' then if on then CreateThread(noclipLoop) end
    elseif tool == 'god' then SetEntityInvincible(ped, on) SetPlayerInvincible(PlayerId(), on)
    elseif tool == 'invisible' then SetEntityVisible(ped, not on) end
    page('tools')
    return true
end

RegisterNUICallback('tool', function(d, cb) cb({ ok = setTool(d.tool, d.on == true) }) end)
RegisterNUICallback('teleport', function(d, cb)
    local ok, err = LXR.RPC.Server('lxr-admin:me', 'teleport', true)
    if not ok then toast('error.' .. tostring(err), 'error') return cb({ ok = false }) end
    if d.waypoint then
        if not IsWaypointActive() then toast('error.no_waypoint', 'error') return cb({ ok = false }) end
        local w = GetWaypointCoords()
        teleport(w.x, w.y, 200.0)
    else teleport(tonumber(d.x) or 0.0, tonumber(d.y) or 0.0, tonumber(d.z) or 100.0) end
    close()
    cb({ ok = true })
end)

RegisterCommand('noclip', function() setTool('noclip', not tools.noclip) end, false)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then close() tools.noclip = false end end)
exports('IsOpen', function() return open end)
exports('Tools', function() return tools end)
