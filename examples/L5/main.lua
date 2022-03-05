local skynet = require "skynet"
skynet.start(function()
    print("main start ...")
    skynet.newservice("server")
    local conf = {
        address = "127.0.0.1",
        port = 8888,
        maxclient = 1024,
        nodelay = true,
    }
    local gate = skynet.newservice("gate")
    skynet.call(gate,"lua","open",conf)
    skynet.exit()
end)
