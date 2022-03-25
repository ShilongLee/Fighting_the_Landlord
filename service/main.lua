local skynet = require "skynet"
local config = require "server_config"
local logind = "logind/main"
local lobby = "lobby/main"
local gated = "gated/main"

skynet.start(function()
    local a = skynet.newservice(logind)
    -- skynet.newservice(lobby)
    -- local gate = skynet.newservice(gated)
    -- local conf = config.gated_conf
    -- skynet.call(gate, "lua", "open", conf)
    skynet.exit()
end)
