require "lib.events"
local Events = require("lib.events")

commands.add_command("po_rescan", "Re-scans for radars", Events.findall_radars)
commands.add_command("po_rechart", "Rechart base", Events.rechart_base)
