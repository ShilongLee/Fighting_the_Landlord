local skynet = require "skynet"
local socket = require "skynet.socket"
local proto = require "pack_proto"
local errorcode = require "error_code"
local sproto = require "sproto"
local config = require "server_config"
local servernet = require "servernet"
local mysql = require "skynet.db.mysql"
local LIST = require "list"

require "skynet.manager"
local user_data = {} -- account -> user_data {account,score,gate_addr,ready,fd}
local conn = {} -- fd->account
local command = {} -- cmd of client
local call = {} -- cmd of other service
local Will_conn = {} -- token -> user_data {account,score,ready}
local data_base
local host = sproto.new(proto.lobbymsg):host("package")
local pack_req = host:attach(sproto.new(proto.lobbymsg))
local list

function call.Reg(args)
    Will_conn[args.token] = args.user_data
    Will_conn[args.token].ready = false
    skynet.timeout(10, function()
        Will_conn[args.token] = nil
    end)
end

local function echo(addr, fd, msg)
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

function call.clear_online()
    local req = "update account set on_line = \"false\" where account like \"%\";"
    data_base:query(req)
end

function call.sql_on_line_true(account)
    local req = "update account set on_line = \"true\" where account = \"" .. account .. "\";"
    data_base:query(req)
end

function call.sql_on_line_false(account)
    local req = "update account set on_line = \"false\" where account = \"" .. account .. "\";"
    data_base:query(req)
end

function call.sql_update_score(account)
    local req = "update account set score = \"" .. user_data[account].score .. "\" where account = \"" .. account ..
                    "\";"
    data_base:query(req)
end

function call.release_conn(addr, fd) -- 客户端断开连接时调用
    if conn[fd] then
        call.sql_on_line_false(conn[fd])
        call.sql_update_score(conn[fd])
        if user_data[conn[fd]].ready then
            list:remove(conn[fd])
        end
        user_data[conn[fd]] = nil
        conn[fd] = nil
    end
    socket.close(fd)
    echo(addr, fd, "disconnect lobby")
end

local function conn_sql()
    local conf = config.mysql_conf
    return mysql.connect(conf)
end

function command.sign_out(fd)
    local account = conn[fd]
    call.sql_on_line_false(account)
    call.sql_update_score(account)
    if user_data[account].ready then
        list:remove(account)
    end
    user_data[account] = nil
    conn[fd] = nil
    return {
        result = errorcode.ok
    }
end

function command.ready(fd)
    user_data[conn[fd]].ready = true
    list:insert(conn[fd])
    return {
        result = errorcode.ok
    }
end

function command.cancel_ready(fd)
    user_data[conn[fd]].ready = false
    list:remove(conn[fd])
    return {
        result = errorcode.ok
    }
end

function command.bind(fd, args)
    local token = args.token
    local data = Will_conn[token]
    data.fd = fd
    Will_conn[token] = nil
    conn[fd] = data.account
    if user_data[data.account] and user_data[data.account].gate_addr and user_data[data.account].gate_port then
        -- 重连到战斗
    else
        user_data[data.account] = data
    end
    call.sql_on_line_true(data.account)
    return {
        result = errorcode.ok
    }
end

function command.query_score(fd)
    local user_data = user_data[conn[fd]]
    return {
        result = errorcode.ok,
        user_data = {
            account = user_data.account,
            score = user_data.score
        }
    }
end

local function notify_to_battle(fd)
    local args
    args.address = config.gated_conf.address
    args.port = config.gated_conf.port
    pack_req("notify_to_battle", args)
end

local function go_battle()
    if list:get_length() >= 3 then
        for i = 1, 3 do
            local account = list:pop()
            notify_to_battle(user_data[account].fd)
            conn[user_data[account].fd] = nil
            user_data[account].ready = false
            user_data[account].gate_addr = config.gated_conf.address
            user_data[account].gate_port = config.gated_conf.port
        end
    end
end

local function request(func, args, response, fd, addr)
    echo(addr, fd, "require " .. func)
    local f = command[func]
    local res, pack
    if not f then
        res = {
            result = errorcode.Nofunction
        }
    else
        res = f(fd, args)
    end
    echo(addr, fd, "result = " .. res.result)
    if response then
        pack = response(res)
    end
    return pack
end

local function accept(fd, addr)
    socket.start(fd)
    -- 初始化文件描述符和解包函数
    local last = ""
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
            call.release_conn(addr, fd)
            return
        end
        go_battle()
    end
end

skynet.start(function()
    list = LIST:new()
    data_base = conn_sql()
    call.clear_online()
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
            echo(addr, fd, "connect lobby")
            accept(fd, addr)
        end)
    end)
    skynet.register("LOBBY")
end)
