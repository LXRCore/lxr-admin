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

-- ── spectate: a free camera on the other player's ped, my own ped parked invisible and safe; the same call ends it
local spectating = nil   -- { target = serverId, cam, me = { coords } }
local function stopSpectate()
    if not spectating then return end
    local s = spectating
    spectating = nil
    RenderScriptCams(false, true, 500, true, true)
    if s.cam then DestroyCam(s.cam, false) end
    local ped = PlayerPedId()
    SetEntityVisible(ped, not tools.invisible)
    SetEntityInvincible(ped, tools.god)
    FreezeEntityPosition(ped, false)
    if s.me then SetEntityCoords(ped, s.me.x, s.me.y, s.me.z, false, false, false, false) end
    toast('info.spectate_off', 'info')
end
RegisterNetEvent('lxr-admin:client:spectate', function(target)
    if spectating then return stopSpectate() end
    local pid = GetPlayerFromServerId(tonumber(target) or -1)
    local tp = pid ~= -1 and GetPlayerPed(pid) or 0
    if tp == 0 then return toast('error.gone', 'error') end
    local ped = PlayerPedId()
    spectating = { target = target, me = GetEntityCoords(ped) }
    SetEntityVisible(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    spectating.cam = cam
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
    toast('info.spectate_on', 'info', { id = target })
    CreateThread(function()
        local angle = 0.0
        while spectating and spectating.cam == cam do
            local pid2 = GetPlayerFromServerId(spectating.target)
            local t = pid2 ~= -1 and GetPlayerPed(pid2) or 0
            if t == 0 then stopSpectate() break end
            -- the mouse orbits, the wheel is not needed: a fixed distance behind and above
            angle = angle - GetDisabledControlNormal(0, 0xA987235F) * 3.0   -- look left/right
            local tc = GetEntityCoords(t)
            local rad = math.rad(angle)
            local pos = vector3(tc.x + math.sin(rad) * 4.0, tc.y - math.cos(rad) * 4.0, tc.z + 1.6)
            SetCamCoord(cam, pos.x, pos.y, pos.z)
            PointCamAtCoord(cam, tc.x, tc.y, tc.z + 0.6)
            SetEntityCoords(PlayerPedId(), tc.x, tc.y, tc.z - 5.0, false, false, false, false)   -- keep my ped streamed near them
            if IsControlJustReleased(0, 0x156F7119) then stopSpectate() break end   -- Backspace ends it
            Wait(0)
        end
    end)
end)

-- ── staff blips: the server feeds positions while they are on
local blips, blipsOn = {}, false
RegisterNetEvent('lxr-admin:client:blips', function(list)
    local seen = {}
    for _, p in ipairs(list or {}) do
        if p.id ~= GetPlayerServerId(PlayerId()) then
            seen[p.id] = true
            local b = blips[p.id]
            if not b then
                b = N(0x554D9D53F696D002, 1664425300, p.x, p.y, p.z)   -- BlipAddForCoords
                N(0x74F74D3207ED525C, b, joaat(Config.Blips.sprite or 'blip_ambient_companion'), true)
                N(0xD38744167B2FA257, b, Config.Blips.scale or 0.6)     -- scale
                blips[p.id] = b
            else
                N(0xAE2AF67E9D9AF65D, b, p.x, p.y, p.z)   -- SetBlipCoords
            end
            N(0x9CB1A1623062F402, b, ('%d · %s'):format(p.id, p.name or ''))
        end
    end
    for id, b in pairs(blips) do if not seen[id] then RemoveBlip(b) blips[id] = nil end end
end)
RegisterNUICallback('blips', function(d, cb)
    local on = d.on == true
    local ok, err = LXR.RPC.Server('lxr-admin:blips', on)
    if not ok then toast('error.' .. tostring(err), 'error') return cb({ ok = false }) end
    blipsOn = on
    if not on then for id, b in pairs(blips) do RemoveBlip(b) blips[id] = nil end end
    tools.blips = on
    page('tools')
    cb({ ok = true })
end)

-- ── developer tools: /coords copies where I stand; /entity names what the crosshair sees; /delent removes it; /ids shows ids overhead
local function underCrosshair()
    local from = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local to = from + dir * 30.0
    local ray = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, -1, PlayerPedId(), 0)
    local _, hit, coords, _, ent = GetShapeTestResult(ray)
    return hit == 1 and ent or nil, coords
end
RegisterCommand('coords', function()
    if not LocalPlayer.state.isLoggedIn then return end
    local ok = LXR.RPC.Server('lxr-admin:me', 'devtools', true)
    if not ok then return end
    local c, h = GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId())
    local s = ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(c.x, c.y, c.z, h)
    SendNUIMessage({ action = 'clipboard', text = s })
    toast('info.coords', 'info', { coords = s })
    print('^3[lxr-admin]^7 ' .. s)
end, false)
RegisterCommand('entity', function()
    local ok = LXR.RPC.Server('lxr-admin:me', 'devtools', true)
    if not ok then return end
    local ent = underCrosshair()
    if not ent then return toast('error.nothing_there', 'error') end
    local model = GetEntityModel(ent)
    local kind = IsEntityAPed(ent) and 'ped' or IsEntityAVehicle(ent) and 'vehicle' or 'object'
    local netId = NetworkGetEntityIsNetworked(ent) and NetworkGetNetworkIdFromEntity(ent) or 0
    local c = GetEntityCoords(ent)
    local s = ('%s model 0x%X net %d at %.2f, %.2f, %.2f'):format(kind, model, netId, c.x, c.y, c.z)
    toast('info.entity', 'info', { info = s })
    print('^3[lxr-admin]^7 ' .. s)
end, false)
RegisterCommand('delent', function()
    local ent = underCrosshair()
    if not ent then return toast('error.nothing_there', 'error') end
    if not NetworkGetEntityIsNetworked(ent) then
        local ok = LXR.RPC.Server('lxr-admin:me', 'delete', true)
        if ok then SetEntityAsMissionEntity(ent, true, true) DeleteEntity(ent) toast('info.done', 'success') end
        return
    end
    local ok, err = LXR.RPC.Server('lxr-admin:delete', NetworkGetNetworkIdFromEntity(ent))
    if ok then toast('info.done', 'success') else toast('error.' .. tostring(err), 'error') end
end, false)
local showIds = false
RegisterCommand('ids', function()
    local ok = LXR.RPC.Server('lxr-admin:me', 'devtools', true)
    if not ok then return end
    showIds = not showIds
    if not showIds then return end
    CreateThread(function()
        while showIds do
            local me = PlayerId()
            for _, pid in ipairs(GetActivePlayers()) do
                if pid ~= me then
                    local ped = GetPlayerPed(pid)
                    local c = GetEntityCoords(ped)
                    if #(c - GetEntityCoords(PlayerPedId())) < 60.0 then
                        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(c.x, c.y, c.z + 1.1)
                        if onScreen then
                            local text = tostring(GetPlayerServerId(pid))
                            SetTextScale(0.3, 0.3) SetTextCentre(true) SetTextColor(255, 255, 255, 200)
                            DisplayText(CreateVarString(10, 'LITERAL_STRING', text), sx, sy)
                        end
                    end
                end
            end
            Wait(0)
        end
    end)
end, false)

RegisterCommand('noclip', function() setTool('noclip', not tools.noclip) end, false)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then close() tools.noclip = false showIds = false stopSpectate() for _, b in pairs(blips) do RemoveBlip(b) end end end)
RegisterNUICallback('reports', function(d, cb) local ok, list = LXR.RPC.Server('lxr-admin:reports', d.what, d.id) cb({ ok = ok, reports = list }) end)
RegisterNUICallback('goto', function(d, cb) teleport(tonumber(d.x) or 0.0, tonumber(d.y) or 0.0, tonumber(d.z) or 100.0) close() cb({ ok = true }) end)
exports('IsOpen', function() return open end)
exports('Tools', function() return tools end)
