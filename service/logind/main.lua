require "skynet.manager"
local skynet = require "skynet"
local socket = require "skynet.socket"
local config = require "server_config"
local sproto = require "sproto"
local proto = require "pack_proto"
local errorcode = require "error_code"
local mysql = require "skynet.db.mysql"
local servernet = require "servernet"
local command = require "logind.command"
local logind = require "logind.logind"

local function check_args(user_data)
    user_data.account = string.gsub(user_data.account, ' ', '')
    user_data.password = string.gsub(user_data.password, ' ', '')
    if user_data.account == nil or user_data.account == "" then
        return errorcode.Nilaccount
    end
    if #user_data.account > 12 then
        return errorcode.Longaccount
    end
    if #user_data.password > 12 then
        return errorcode.Longpasswd
    end
    return errorcode.ok
end

local function request(func, args, response, fd, addr)
    logind.echo(addr, fd, "require " .. func)
    -- 检查参数
    local illegal = check_args(args)
    if illegal ~= errorcode.ok then
        return {
            result = illegal
        }
    end
    -- 调用方法
    local f = command[func]
    local res, pack
    if not f then
        res = {
            result = errorcode.Nofunction
        }
    else
        res = f(args)
    end
    logind.echo(addr, fd, "result = " .. res.result)
    -- 封装响应包
    if response then
        pack = response(res)
    end
    return pack
end

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
            logind.echo(addr, fd, "disconnect logind")
            socket.close(fd)
            return
        end
    end
end

skynet.start(function()
    local conf = config.mysql_conf
    logind.data_base = mysql.connect(conf)
    local conf = config.logind_conf
    local listen_fd = socket.listen(conf.address, conf.port)
    socket.start(listen_fd, function(fd, addr)
        skynet.fork(function()
            logind.echo(addr, fd, "connected logind")
            accept(fd, addr)
        end)
    end)
    skynet.register("LOGIND")
end)
