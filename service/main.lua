local skynet = require "skynet"
local config = require "server_config"
skynet.start(function ()
    skynet.newservice("logind")
    --local gate = skynet.newservice("gated")
    --local conf = config.gated_conf
    --skynet.call(gate,"lua","open",conf)
    skynet.exit()
end)