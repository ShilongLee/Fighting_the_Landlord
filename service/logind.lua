require "skynet.manager"
local skynet = require "skynet"
local socket = require "skynet.socket"
local config = require "server_config"
local sproto = require "sproto"
local proto = require "pack_proto"
local errorcode = require "error_code"

local Req_func = {}

function Req_func.sign_in(args)
    -- 连接数据库
    -- 验证账号密码
    return {
        result = errorcode.ok,
        address = config.gated_conf.address,
        port = config.gated_conf.port
    }
end

function Req_func.sign_up(args)
    -- 连接数据库
    -- 写入
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
    if not r then
        return nil, last
    end
    return recv(fd, last .. r)
end

local function request(func, args, response)
    local f = Req_func[func]
    local res
    if not f then
        if response then
            res = response({
                result = errorcode.Nofunction
            })
        end
        return res
    end
    local ans = f(args)
    if response then
        res = response(ans)
    end
    return res
end

local function send(fd, msg)
    local pack = string.pack(">s2", msg)
    socket.write(fd, pack)
end

local function accept(fd)
    local last = ""
    socket.start(fd)
    local host = sproto.new(proto.logindmsg):host("package")
    while true do
        local str
        str, last = recv(fd, last)
        if str then
            local type, func, args, response = host:dispatch(str)
            if type == "REQUEST" then
                local res = request(func, args, response)
                if res then
                    send(fd, res)
                end
            end
        else
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
            accept(fd)
        end)
    end)
    skynet.register("LOGIND")
end)
