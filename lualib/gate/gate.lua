local Class = require "class"
local Skynet = require "skynet"

local M = Class("gate")

-- 仅关闭网关监听，存在的连接依然有效
function M:close()
    Skynet.send(self.addr, "lua", "close")
end

function M:kick(fd)
    Skynet.send(self.addr, "lua", "kick", fd)
end

-- 踢掉所有连接
function M:kick_all()
    Skynet.send(self.addr, "lua", "kick_all")
end

function M:force_kick(fd)
    Skynet.send(self.addr, "lua", "force_kick", fd)
end

function M:forward(fd, agent, client)
    Skynet.send(self.addr, "lua", "forward", fd, agent, client)
end

function M:open()
    Skynet.send(self.addr, "lua", "open")
end

function M:_init(conf)
    self.addr = Skynet.newservice("gateserver", Skynet.self(), conf)
end

return M
