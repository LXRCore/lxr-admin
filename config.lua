--[[
    ██╗     ██╗  ██╗██████╗        █████╗ ██████╗ ███╗   ███╗██╗███╗   ██╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔══██╗██╔══██╗████╗ ████║██║████╗  ██║
    ██║      ╚███╔╝ ██████╔╝█████╗███████║██║  ██║██╔████╔██║██║██╔██╗ ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝██╔══██║██║  ██║██║╚██╔╝██║██║██║╚██╗██║
    ███████╗██╔╝ ██╗██║  ██║      ██║  ██║██████╔╝██║ ╚═╝ ██║██║██║ ╚████║
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝╚═════╝ ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝

    LXR Core - Admin

    The staff desk. Every action has a tier from the core's permission
    groups and is checked on the server, never on the client; every action
    is logged with who did what to whom. The panel is the LXR UI Kit: a
    player list, a server page, a page for yourself, and the ban book.

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/ZHMKVYyhBa (development)
    GitHub:      https://github.com/LXRCore

    Version: 3.0.0
    Performance Target: 0.00 ms idle (noclip and godmode run a frame loop only while on)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

Config = Config or {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ LANGUAGE ██████████████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████
Config.Lang = 'en'

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ACCESS ════════════════════════════════════════════════
-- ████████████████████████████████████████████████████████████████████████████████
-- tiers are the core's Config.Server.permissions, highest first; a tier includes every tier above it
Config.Access = {
    open      = 'helper',
    players   = 'helper',
    go        = 'helper', bring = 'mod', freeze = 'mod', warn = 'helper',
    heal      = 'mod', revive = 'mod', kick = 'mod',
    ban       = 'admin', unban = 'admin', give = 'admin', job = 'admin', money = 'admin',
    announce  = 'mod', weather = 'admin', time = 'admin',
    noclip    = 'mod', god = 'admin', invisible = 'admin', teleport = 'helper',
}

Config.Command = { name = 'admin', key = 'F10' }
Config.Ban = { maxHours = 24 * 365, permanentHours = 0 }
Config.NoClip = { speed = 1.0, fast = 4.0 }
Config.Security = { rateLimit = { windowMs = 1000, burst = 8 } }
Config.Debug = { printBanner = true, log = true }
