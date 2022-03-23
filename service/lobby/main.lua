local skynet = require "skynet"
local socket = require "skynet.socket"
local errorcode = require "error_code"
local proto = require "pack_proto"
local sproto = require "sproto"
local config = require "server_config"
local servernet = require "servernet"
local mysql = require "skynet.db.mysql"
local sql_cmd = require "sql_command"
local call = require "call" -- cmd of other service
local command = require "lobby.command" -- cmd of client
local lobby = require "lobby.lobby"
require "skynet.manager"

local function request(func, args, response, fd, addr)
    lobby.echo(addr, fd, "require " .. func)
    local f = command[func]
    local res, pack, close
    if not f then
        res = {
            result = errorcode.Nofunction
        }
    else
        res = f(fd, addr, args)
    end
    lobby.echo(addr, fd, "result = " .. res.result)
    if response then
        pack = response(res)
    end
    return pack, close
end

local function accept(fd, addr)
    socket.start(fd)
    -- 初始化文件描述符和解包函数
    local last = ""
    local host = sproto.new(proto.lobbymsg):host("package")
    -- 收包
    while true do
        local str
        str, last = servernet.recv(fd, last)
        local type, func, args, response
        if str then
            -- 拆包
            type, func, args, response = host:dispatch(str)
            if type == "REQUEST" then
                -- 调用
                local res = request(func, args, response, fd, addr)
                -- 响应结果
                if res then
                    servernet.send(fd, res)
                end
            end
        else
            command.quit(fd, addr, args)
            lobby.echo(addr, fd, "disconnect lobby")
            return
        end
        if func == "ready" then
            lobby:go_battle()
        end
    end
end

skynet.start(function()
    -- 连接数据库，清除在线状态
    local conf = config.mysql_conf
    lobby.data_base = mysql.connect(conf)
    sql_cmd.clear_online(lobby.data_base)
    -- 监听端口
    local conf = config.lobby_conf
    local listenfd = socket.listen(conf.address, conf.port)
    skynet.dispatch("lua", function(session, _, cmd, ...)
        local f = call[cmd]
        if session then
            skynet.ret(skynet.pack(f(...))) -- 回应消息
        else
            f(...)
        end
    end)
    socket.start(listenfd, function(fd, addr)
        skynet.fork(function()
            lobby.echo(addr, fd, "connect lobby")
            accept(fd, addr)
            socket.close(fd)
        end)
    end)
    skynet.register("LOBBY")
end)
