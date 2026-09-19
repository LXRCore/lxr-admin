--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-ADMIN — Locale: English (canonical)
     Developer   : iBoss21 | Brand : LXRCore | https://www.lxrcore.com
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

Locale.Register('en', {
    command = { id = 'player id', revive = 'Revive a player (or yourself)', heal = 'Heal a player (or yourself)', freeze = 'Freeze a player', unfreeze = 'Unfreeze a player', bring = 'Bring a player to you', ['goto'] = 'Go to a player', whoami = 'Your staff tier and identifiers (logged on the server)' },
    error = { rate = 'Slow down.', denied = 'Not yours to do.', gone = 'They are not here.', no_item = 'No such item.', too_heavy = 'They cannot carry that.', no_job = 'No such job.', no_money = 'No such account, or nothing to move.', no_weather = 'No such weather.', no_waypoint = 'Set a waypoint first.' },
    info = { done = 'Done.', warned = 'A warning from staff: %{reason}', kicked = 'Kicked by %{by}: %{reason}', banned = 'Banned: %{reason}\n%{discord}', frozen = 'Staff froze you.', unfrozen = 'You can move.', whoami = 'Your tier: %{tier}. Identifiers are in the server log.' },
    action = { go = 'Go to', bring = 'Bring', freeze = 'Freeze', unfreeze = 'Unfreeze', heal = 'Heal', revive = 'Revive', warn = 'Warn', kick = 'Kick', ban = 'Ban', give = 'Give item', job = 'Set job', money = 'Money', unban = 'Lift' },
    field = { reason = 'Reason', hours = 'Hours (0 = permanent)', item = 'Item name', amount = 'Amount (negative takes)', job = 'Job name', grade = 'Grade', account = 'Account (cash, bank…)' },
    ui = { kicker = 'Staff', title = 'The desk', hint_close = 'close', tab_players = 'Players', tab_server = 'Server', tab_me = 'Me', tab_bans = 'Ban book', players_head = 'Online', server_head = 'The server', me_head = 'On my own ped', bans_head = 'Bans', search = 'search', refresh = 'Refresh', pick_player = 'Pick a player.', nobody = 'Nobody here.', online = '%{n} online', announce = 'Announce', send = 'Send', weather = 'Weather', set = 'Set', time = 'Time', freeze_time = 'Freeze time', unfreeze_time = 'Unfreeze time', frozen = 'frozen', uptime = 'Up', sky = 'Sky', clock = 'Clock', noclip = 'No clip', god = 'Godmode', invisible = 'Invisible', on = 'on', off = 'off', teleport = 'Teleport', to_waypoint = 'To waypoint', go = 'Go', no_bans = 'The book is empty.', permanent = 'permanent', close = 'Close', confirm = 'Confirm', cancel = 'Cancel' },
})
