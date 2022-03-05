local skynet = require "skynet"
local socket = require "skynet.socket"
local function toagent2(fd)
    socket.start(fd)
    socket.write(fd,"main recvd fd turn to agent2")
    skynet.newservice("agent2",fd)
    socket.abandon(fd)
end
skynet.start(function()
    print("server start ...")
    local listenfd = socket.listen("127.0.0.1", 8888)
    --local agent1 = skynet.newservice("agent1")
    --local agent2 = skynet.newservice("agent2")
    socket.start(listenfd, function(fd, ip)
        print(string.format("%s connect fd = %d", ip, fd))
        --skynet.call(agent1,"lua",fd)
        toagent2(fd)
    end)
end)
