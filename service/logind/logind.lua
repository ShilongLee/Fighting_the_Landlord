require "skynet.manager"
local skynet = require "skynet"
local socket = require "skynet.socket"
local config = require "server_config"
local sproto = require "sproto"
local proto = require "pack_proto"
local errorcode = require "error_code"
local mysql = require "skynet.db.mysql"
local servernet = require "servernet"
local command = require "command"
local data_base
local token = 0

local function conn_sql()
    local conf = config.mysql_conf
    return mysql.connect(conf)
end

local function echo(addr, fd, msg)
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

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

-- 通知大厅要登录的token
local function Reg_in_lobby(res, token)
    skynet.send("LOBBY", "lua", "Reg", {
        token = token,
        user_data = {
            account = res[1].account,
            score = res[1].score
        }
    })
end

local function request(func, args, response, fd, addr)
    echo(addr, fd, "require " .. func)
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
        res = f(data_base, Reg_in_lobby, args)
    end
    echo(addr, fd, "result = " .. res.result)
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
            echo(addr, fd, "disconnect logind")
            socket.close(fd)
            return
        end
    end
end

skynet.start(function()
    data_base = conn_sql()
    local conf = config.logind_conf
    local listen_fd = socket.listen(conf.address, conf.port)
    socket.start(listen_fd, function(fd, addr)
        skynet.fork(function()
            echo(addr, fd, "connected logind")
            accept(fd, addr)
        end)
    end)
    skynet.register("LOGIND")
end)
