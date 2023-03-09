local Skynet = require "skynet.manager"
local netpack = require "skynet.netpack"
local socketdriver = require "skynet.socketdriver"

local socket    -- listen socket
local queue     -- message queue
local maxclient -- max client
local client_number = 0
local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
local nodelay = false
local conf = {} -- address, port, maxclient, nodelay
local watchdog = ...

local connection = {} -- fd -> {fd, addr, client, agent}

function CMD.close()
    assert(socket)
    socketdriver.close(socket)
end

function CMD.kick(fd)
    local c = connection[fd]
    if c ~= nil then
        connection[fd] = nil
        socketdriver.close(fd)
    end
end

function CMD.kick_all()
    for fd in pairs(connection) do
        connection[fd] = nil
        socketdriver.close(fd)
    end
end

function CMD.force_kick(fd)
    local c = connection[fd]
    if c ~= nil then
        connection[fd] = nil
        socketdriver.shutdown(fd)
    end
end

function CMD.forward(fd, agent, client)
    local c = assert(connection[fd])
    c.agent = agent
    c.client = client or 0
    if connection[fd] then
        socketdriver.start(fd)
    end
end

function CMD.open()
    assert(not socket)
    local address = conf.address or "0.0.0.0"
    local port = assert(conf.port)
    maxclient = conf.maxclient or 1024
    nodelay = conf.nodelay
    -- 写日志
    socket = socketdriver.listen(address, port, 5)
    socketdriver.start(socket)
end

function CMD.init(config)
    conf = config
end

local MSG = {}

Skynet.register_protocol {
    name = "client",
    id = Skynet.PTYPE_CLIENT,
}

Skynet.register_protocol {
    name = "socket",
    id = Skynet.PTYPE_SOCKET,	-- PTYPE_SOCKET = 6
    unpack = function ( msg, sz )
        return netpack.filter( queue, msg, sz)
    end,
    dispatch = function (_, _, q, type, ...)
        queue = q
        if type then
            MSG[type](...)
        end
    end
}

local function dispatch_msg(fd, msg, sz)
    -- recv a package, forward it
    local c = connection[fd]
    local agent = c.agent
    if agent then
        -- It's safe to redirect msg directly , gateserver framework will not free msg.
        Skynet.redirect(agent, c.client, "client", fd, msg, sz)
    else
        Skynet.send(watchdog, "lua", "socket", "data", fd, Skynet.tostring(msg, sz))
        -- skynet.tostring will copy msg to a string, so we must free msg here.
        Skynet.trash(msg, sz)
    end
end

MSG.data = dispatch_msg

local function dispatch_queue()
    local fd, msg, sz = netpack.pop(queue)
    if fd then
        -- may dispatch even the handler.message blocked
        -- If the handler.message never block, the queue should be empty, so only fork once and then exit.
        Skynet.fork(dispatch_queue)
        dispatch_msg(fd, msg, sz)

        for fd, msg, sz in netpack.pop, queue do
            dispatch_msg(fd, msg, sz)
        end
    end
end

MSG.more = dispatch_queue

function MSG.open(fd, addr)
    if client_number >= maxclient then
        socketdriver.shutdown(fd)
        return
    end
    if nodelay then
        socketdriver.nodelay(fd)
    end
    connection[fd] = {
        fd = fd,
        ip = addr
    }
    client_number = client_number + 1
    socketdriver.start(fd)
    Skynet.send(watchdog, "lua", "socket", "open", fd, addr)
end

function MSG.close(fd)
    client_number = client_number - 1
    local c = connection[fd]
	if c then
		connection[fd] = nil
	end
    Skynet.send(watchdog, "lua", "socket", "close", fd)
end

function MSG.error(fd, msg)
    local c = connection[fd]
	if c then
		connection[fd] = nil
	end
    if fd == socket then
        Skynet.error("gateserver accept error:", msg)
    else
        socketdriver.shutdown(fd)
    end
    Skynet.send(watchdog, "lua", "socket", "error", fd)
end

function MSG.warning(fd, size)
    Skynet.send(watchdog, "lua", "socket", "warning", fd)
end

local function init()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = CMD[cmd]
        if f then
            Skynet.ret(Skynet.pack(f(...)))
        end
    end)
    Skynet.register(".gate")
end

Skynet.start(init)