require "skynet.manager"
local skynet = require "skynet"
local socket = require "skynet.socket"
local config = require "server_config"
local sproto = require "sproto"
local proto = require "pack_proto"
local errorcode = require "error_code"
local mysql = require "skynet.db.mysql"

local Req_func = {}

local function conn_sql()
    local conf = config.mysql_conf
    return mysql.connect(conf)
end

local function echo(addr, fd, msg)
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

local function check(user_data)
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

function Req_func.sign_in(user_data)
    local illegal = check(user_data)
    if illegal ~= errorcode.ok then
        return {
            result = illegal
        }
    end
    -- 从数据库取得记录
    local data_base = conn_sql()
    local req = "select * from account where account = \'" .. user_data.account .. "\';"
    local res = data_base:query(req)
    -- 验证账号密码
    if next(res) == nil or user_data.password ~= res[1].password then
        return {
            result = errorcode.Signfail
        }
    end
    if res[1].on_line == "true" then
        return {
            result = errorcode.Mutisign,
            address = config.gated_conf.address,
            port = config.gated_conf.port
        }
    end
    return {
        result = errorcode.ok,
        address = config.gated_conf.address,
        port = config.gated_conf.port
    }
end

function Req_func.sign_up(user_data)
    -- 检查用户名和密码是否合法
    local illegal = check(user_data)
    if illegal ~= errorcode.ok then
        return {
            result = illegal
        }
    end
    -- 连接数据库并发送请求
    local data_base = conn_sql()
    -- 写入
    local req = "insert into account(account,password,score,on_line) values( \'" .. user_data.account .. "\',\'" ..
                    user_data.password .. "\'," .. "0 ,\'false\')" .. ";"
    local res = data_base:query(req)
    if res.errno and res.errno == errorcode.Dupaccount then
        return {
            result = errorcode.Dupaccount
        }
    end
    return {
        result = errorcode.ok,
        address = config.gated_conf.address,
        port = config.gated_conf.port
    }
end

local function unpack(str)
    local size = #str
    if size < 2 then
        return nil, str
    end
    local len = str:byte(1) * 256 + str:byte(2)
    if size < len + 2 then
        return nil, str
    end
    return str:sub(3, 2 + len), str:sub(3 + len)
end

local function recv(fd, last)
    local result
    result, last = unpack(last)
    if result then
        return result, last
    end
    local r = socket.read(fd)
    if not r or r == "" then
        return nil, last
    end
    return recv(fd, last .. r)
end

local function request(func, args, response, fd, addr)
    echo(addr, fd, "require " .. func)
    local f = Req_func[func]
    local res, pack
    if not f then
        res = {
            result = errorcode.Nofunction
        }
    else
        res = f(args)
    end
    echo(addr, fd, "result = " .. res.result)
    if response then
        pack = response(res)
    end
    return pack
end

local function send(fd, msg)
    local pack = string.pack(">s2", msg)
    socket.write(fd, pack)
end

local function accept(fd, addr)
    -- 初始化文件描述符和解包函数
    local last = ""
    socket.start(fd)
    local host = sproto.new(proto.logindmsg):host("package")
    -- 收包
    while true do
        local str
        str, last = recv(fd, last)
        if str then
            -- 拆包
            local type, func, args, response = host:dispatch(str)
            if type == "REQUEST" then
                -- 调用
                local res = request(func, args, response, fd, addr)
                -- 响应结果
                if res then
                    send(fd, res)
                end
            end
        else
            echo(addr, fd, "disconnect")
            socket.close(fd)
            return
        end
    end
end

skynet.start(function()
    local conf = config.logind_conf
    local listen_fd = socket.listen(conf.address, conf.port)
    socket.start(listen_fd, function(fd, addr)
        skynet.fork(function()
            echo(addr, fd, "connected")
            accept(fd, addr)
        end)
    end)
    skynet.register("LOGIND")
end)

-- command gate -> self change userstatus on_line
