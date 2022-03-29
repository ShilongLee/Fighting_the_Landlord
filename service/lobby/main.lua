local skynet = require "skynet"
local socket = require "skynet.socket"
local error = require "error"
local proto = require "pack_proto"
local sproto = require "sproto"
local config = require "server_config"
local servernet = require "servernet"
local mysql = require "skynet.db.mysql"
local sql_cmd = require "sql_command"
local call = require "call" -- cmd of other service
local command = require "lobby.command" -- cmd of client
local lobby = require "lobby.lobby"
local Log = require "logger"
require "skynet.manager"

local function request(func, args, response, fd, addr)
    Log.echo(addr, fd, "require " .. func)
    local f = command[func]
    local res, pack, close
    -- 调用方法函数
    if not f then
        res = {
            result = error.Nofunction
        }
    else
        res = f(fd, addr, args)
    end
    Log.echo(addr, fd, "result = " .. res.result)
    -- 封装响应包
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
        end
        -- 断开连接或每条命令的额外处理
        if not str or lobby:extra(func, fd, addr) then
            lobby:disconnect(fd)
            Log.echo(addr, fd, "disconnect lobby")
            return
        end
    end
end

skynet.start(function()
    -- 连接数据库，清除在线状态
    local conf = config.mysql_conf
    lobby.data_base = mysql.connect(conf)
    sql_cmd.clear_status(lobby.data_base, config.sql_table[1])
    sql_cmd.clear_lobby(lobby.data_base)
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
            Log.echo(addr, fd, "connect lobby")
            accept(fd, addr)
            socket.close(fd)
        end)
    end)
    skynet.register("LOBBY")
end)
