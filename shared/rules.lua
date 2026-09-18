--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-ADMIN — Shared rules: tiers, the action book
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRAdmin = LXRAdmin or {}
local A = LXRAdmin

---Tier order, highest first (the core's groups minus 'whitelisted').
function A.Tiers()
    local out = {}
    for _, g in ipairs((Config.Server and Config.Server.permissions) or { 'god', 'developer', 'headadmin', 'admin', 'mod', 'helper' }) do if g ~= 'whitelisted' then out[#out + 1] = g end end
    return out
end

---Groups that satisfy a tier: the tier itself and everything above it.
function A.GroupsFor(tier)
    local out = {}
    for _, g in ipairs(A.Tiers()) do out[#out + 1] = g if g == tier then return out end end
    return {}   -- unknown tier: nobody
end

---Does a set of held groups satisfy an action? has(group) → bool
function A.Allowed(action, has)
    local tier = Config.Access[action]
    if not tier then return false end
    for _, g in ipairs(A.GroupsFor(tier)) do if has(g) then return true end end
    return false
end

---Every action name (for the client's button set).
function A.Actions()
    local out = {}
    for k in pairs(Config.Access) do out[#out + 1] = k end
    table.sort(out)
    return out
end

---Ban hours → expire timestamp (0 hours = permanent).
function A.Expire(hours, now)
    hours = tonumber(hours) or 0
    if hours <= 0 then return 2147483647 end
    return now + math.floor(math.min(hours, Config.Ban.maxHours) * 3600)
end
