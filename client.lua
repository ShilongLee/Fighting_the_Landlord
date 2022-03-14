package.cpath = "skynet/luaclib/?.so;luaclib/?.so"
package.path = "skynet/lualib/?.lua;service/?.lua;etc/?.lua;lualib/?.lua;proto/?.lua;"
local socket = require "clientsocket"
local sproto = require "sproto"
local proto = require "pack_proto"
local errorcode = require "error_code"
local error = require "error"
local logind_host = sproto.new(proto.logindmsg):host("package")
local logind_pack_req = logind_host:attach(sproto.new(proto.logindmsg))
local lobby_host = sproto.new(proto.lobbymsg):host("package")
local lobby_pack_req = lobby_host:attach(sproto.new(proto.lobbymsg))
local fd
local session = 1
local last = ""
local logged = false
local command = {}
-- local RPC = {}

local function send_pack(msg)
    local pack = string.pack(">s2", msg)
    socket.send(fd, pack)
end

local function connect(conf) -- {address,port}
    if fd then
        socket.close(fd)
    end
    fd = socket.connect(conf.address, conf.port)
end

local function show_command()
    if logged then
        print("ready\tsign_out\tquit")
    else
        print("sign_in\tsign_up")
    end
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

local function recv(last) -- recv从socket读取的数据
    local result
    result, last = unpack(last)
    if result then
        return result, last
    end
    local r = socket.recv(fd)
    if r == "" then
        return nil, last
    end
    return recv(last .. r)
end

local function get_response(host)
    local str
    str, last = recv(last)
    if not str then
        print("Lost connection with server !")
        os.exit()
        return
    end
    local _, _, res = host:dispatch(str)
    return res
end

local function call_RPC(host, pack_req, func, args)
    local msg = pack_req(func, args, session)
    session = session + 1
    send_pack(msg)
    local res = get_response(host)
    return res
end

local function log_input()
    local account, password
    while true do
        print("Enter your account:")
        print("(Whitespace will be ignored)")
        ::account::
        account = io.read("l")
        account = string.gsub(account, ' ', '')
        if account == "" or account == nil then
            print("Account cannot be empty !")
            goto account
        end
        if #account > 12 then
            print("Account length cannot be greater than 12 !")
            goto account
        end
        print("Enter your password:")
        print("(Whitespace will be ignored)")
        ::password::
        password = io.read("l")
        password = string.gsub(password, ' ', '')
        if password == "" or password == nil then
            print("Password cannot be empty !")
            goto password
        end
        if #password > 12 then
            print("Password length cannot be greater than 12 !")
            goto password
        end
        break
    end
    return account, password
end

local function sign(arg)
    local account, password = log_input()
    local cmd, args
    args = {
        account = account,
        password = password
    }
    if arg == "in" then
        cmd = "sign_in"
    elseif arg == "up" then
        cmd = "sign_up"
    end
    local res = call_RPC(logind_host, logind_pack_req, cmd, args)
    if not res then -- 失去与服务端的连接
        socket.close(fd)
        logged = false
        return
    end
    if res.result ~= errorcode.ok then
        error.strerror(res.result)
        return
    end
    connect({
        address = res.address,
        port = res.port
    })
    call_RPC(lobby_host, lobby_pack_req, "bind", {
        token = res.token
    })
    command.query_score()
    logged = true -- 防止没登陆就发出指令
end

function command.sign_in()
    sign("in")
end

function command.sign_up()
    sign("up")
end

function command.sign_out()
    call_RPC(lobby_host, lobby_pack_req, "sign_out")
    logged = false -- 防止没登陆就发出指令
    connect({
        address = "127.0.0.1",
        port = 6666
    })
end

function command.query_score()
    local res = call_RPC(lobby_host, lobby_pack_req, "query_score")
    if res.result == errorcode.ok then
        print("user:"..res.user_data.account.."\nscore:"..res.user_data.score)
    else
        error.strerror(res.result)
    end
end

local function check_cmd(cmd)
    if not command[cmd] then
        print("Command not found !")
        return false
    end
    if cmd ~= "sign_in" and cmd ~= "sign_up" and cmd ~= "quit" and not logged then
        print("Please sign in first !")
        return false
    end
    if logged then
        if cmd == "sign_in" or cmd == "sign_up" then
            print("Please sign out first !")
            return false
        end
    end
    return true
end

function command.quit()
    if fd then
        socket.close(fd)
    end
end

local function main()
    while true do
        show_command()
        local cmd = io.read("l")
        if not check_cmd(cmd) then
            goto main_continue
        end
        local func = command[cmd]
        func()
        if cmd == "quit" then
            return
        end
        ::main_continue::
    end
end

connect({
    address = "127.0.0.1",
    port = 6666
})

main()
