require "skynet.manager"
local skynet = require "skynet"
local socket = require "skynet.socket"
local config = require "server_config"
local sproto = require "sproto"
local proto = require "pack_proto"
local error = require "error"
local mysql = require "skynet.db.mysql"
local servernet = require "servernet"
local command = require "logind.command"
local logind = require "logind.logind"
local Log = require "logger"

-- 调用方法函数
local function request(func, args, response, fd, addr)
    Log.echo(addr, fd, "require " .. func)
    -- 调用方法
    local f = command[func]
    local res, pack
    if not f then
        res = {
            result = error.Nofunction
        }
    else
        res = f(args)
    end
    Log.echo(addr, fd, "result = " .. res.result)
    -- 封装响应包
    if response then
        pack = response(res)
    end
    return pack
end

-- 根据协议拆分客户端包
local function accept(fd, addr)
    -- 初始化文件描述符和解包函数
    local last = ""
    socket.start(fd)
    local host = sproto.new(proto.logindmsg):host("package")
    -- 收包
    while true do
        local str
        str, last = servernet.recv(fd, last)
        if str then
            -- 拆包
            local type, func, args, response = host:dispatch(str)
            if type == "REQUEST" then
                -- 调用
                local res = request(func, args, response, fd, addr)
                -- 响应结果
                if res then
                    servernet.send(fd, res)
                end
            end
        else
            Log.echo(addr, fd, "disconnect logind")
            socket.close(fd)
            return
        end
    end
end

skynet.start(function()
    -- 打开数据库
    local conf = config.mysql_conf
    logind.data_base = mysql.connect(conf)
    local conf = config.logind_conf
    -- 监听客户端连接
    local listen_fd = socket.listen(conf.address, conf.port)
    socket.start(listen_fd, function(fd, addr)
        skynet.fork(function()
            Log.echo(addr, fd, "connected logind")
            accept(fd, addr)
        end)
    end)
    skynet.register("LOGIND")
end)
