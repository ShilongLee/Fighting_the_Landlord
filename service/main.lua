local skynet = require "skynet"

skynet.start(function ()
    --skynet.newservice("login")
    local gate = skynet.newservice("gated")
    local conf = {
        address = "127.0.0.1",
        port = 8888,
        maxclient = 1024,
        nodelay = true,
    }
    skynet.call(gate,"lua","open",conf)
    skynet.exit()
end)