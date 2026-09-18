--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-ADMIN — Offline tests: tiers include the tiers above, every action has a tier, ban expiry, locale parity
     Usage (from the lxr-admin folder):  lua tests/run.lua [--mock out.js en|ka]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE) os.exit(2) end
local Shim = require('tests.lib.fxshim')
for _, f in ipairs({ 'shared/main.lua', 'shared/locale.lua', 'locales/en.lua', 'config.lua' }) do Shim.load(CORE .. '/' .. f) end
local coreConfig = Config
Config = nil Locale = nil
Shim.load('shared/locale.lua') Shim.load('locales/en.lua') Shim.load('locales/ka.lua') Shim.load('config.lua') Shim.load('shared/rules.lua')
Config.Server = coreConfig.Server
local A = LXRAdmin

local passed, failed = 0, 0
local function test(name, fn) local okT, err = xpcall(fn, debug.traceback) if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-admin offline tests')
test('tiers come from the core, highest first, without whitelisted', function()
    local tiers = A.Tiers()
    eq(tiers[1], 'god') eq(tiers[#tiers], 'helper')
    for _, g in ipairs(tiers) do assert(g ~= 'whitelisted') end
    local set = {}
    for _, g in ipairs(A.GroupsFor('mod')) do set[g] = true end
    assert(set.god and set.admin and set.mod and not set.helper, 'mod includes everything above it, not below')
    eq(#A.GroupsFor('nothing'), 0)
end)
test('every configured action names a real tier', function()
    local valid = {}
    for _, g in ipairs(A.Tiers()) do valid[g] = true end
    for action, tier in pairs(Config.Access) do assert(valid[tier], action .. ' → ' .. tostring(tier)) end
    assert(#A.Actions() >= 15)
end)
test('allowed: a helper may goto but not ban; a god may do everything; unknown actions never', function()
    local helper = function(g) return g == 'helper' end
    local god = function(g) return g == 'god' end
    assert(A.Allowed('go', helper)) assert(not A.Allowed('ban', helper))
    for _, a in ipairs(A.Actions()) do assert(A.Allowed(a, god), a) end
    assert(not A.Allowed('nuke', god))
end)
test('ban expiry: hours, permanent, capped', function()
    eq(A.Expire(0, 1000), 2147483647) eq(A.Expire(nil, 1000), 2147483647)
    eq(A.Expire(2, 1000), 1000 + 7200)
    eq(A.Expire(999999, 1000), 1000 + Config.Ban.maxHours * 3600)
end)
test('locale parity', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
end)
print(('%d passed, %d failed'):format(passed, failed))
if arg and arg[1] == '--mock' and arg[2] then
    Config.Lang = arg[3] or 'en'
    local me = {}
    for _, a in ipairs(A.Actions()) do me[a] = A.Allowed(a, function(g) return g == 'admin' end) end
    local players = {
        { id = 1, account = 'iBoss21', name = 'Levan Abashidze', job = 'Sheriff', citizenid = 'LXR1A2B3C', ping = 34, x = -308.9, y = 777.4, z = 118.8, groups = { 'god' } },
        { id = 4, account = 'nino_k', name = 'Nino Kvaratskhelia', job = 'Doctor', citizenid = 'LXR9F8E7D', ping = 58, x = 1330.1, y = -1299.7, z = 77.0, groups = {} },
        { id = 7, account = 'dutch', name = 'Tomas Reyes', job = 'Unemployed', citizenid = 'LXR55AA11', ping = 112, x = 2640.2, y = -1220.9, z = 53.1, groups = {} },
        { id = 12, account = 'grace', name = 'Grace Delacroix', job = 'Trapper', citizenid = 'LXR00C0DE', ping = 41, x = -1800.5, y = -390.3, z = 160.4, groups = { 'mod' } },
    }
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode({ action = 'open', payload = { players = players, server = { players = 4, max = 64, uptime = 754, weather = 'sunny', nextWeather = 'clouds', hour = 17, minute = 42, season = 'autumn', frozen = false }, me = me, groups = { 'admin' }, tiers = A.Tiers() }, tools = { noclip = false, god = true, invisible = false }, lang = Config.Lang, locale = Lang.bundle(), brand = { name = 'The Land of Wolves', theme = 'night' } }) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
