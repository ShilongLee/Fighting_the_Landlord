package.cpath = "skynet/luaclib/?.so;luaclib/?.so"
package.path = "skynet/lualib/?.lua;service/?.lua;etc/?.lua;lualib/?.lua;proto/?.lua;"
local socket = require "client.socket"
local sproto = require "sproto"
local proto = require "pack_proto"
local errorcode = require "error_code"
local host = sproto.new(proto.logindmsg):host("package")
local pack_req = host:attach(sproto.new(proto.logindmsg))
local addr = "127.0.0.1"
local port = 6666
local fd = socket.connect(addr, port)
local session = 1
local last = ""
local logged = false
local command = {}
-- local RPC = {}

local function show(res)
    for k, v in pairs(res) do
        print(k, v)
    end
end

local function show_command()
    print("sign_in\tsign_up\tready\tquit")
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

local function read_fd() -- 从socket读取数据
    local str
    while not str do
        str = socket.recv(fd)
    end
    return str
end

local function recv(last) -- recv从socket读取的数据
    local result
    result, last = unpack(last)
    if result then
        return result, last
    end
    local r = read_fd()
    if r == "" then
        return nil, last
    end
    return recv(last .. r)
end

local function get_response()
    local str
    str, last = recv(last)
    if not str then
        print("Lost connection with server !")
        return
    end
    local _, _, res = host:dispatch(str)
    return res
end

local function send_pack(msg)
    local pack = string.pack(">s2", msg)
    socket.send(fd, pack)
end

local function call_RPC(func, args)
    local msg = pack_req(func, args, session)
    session = session + 1
    send_pack(msg)
    local res = get_response()
    return res
end

local function echo_error(args)
    if args.result == errorcode.Dupaccount then
        print("Error: username exists !")
    elseif args.result == errorcode.Longaccount then
        print("Error: account cannot longger than 12 characters !")
    elseif args.result == errorcode.Longpasswd then
        print("Error: Password cannot longger than 12 characters !")
    elseif args.result == errorcode.Mutisign then
        print("Error: Repeat Login !")
    elseif args.result == errorcode.Nilaccount then
        print("Error: account is nil !")
    elseif args.result == errorcode.Signfail then
        print("Error: account or password is wrong !")
    else
        print("Unknown error !")
    end
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

function command.sign_in()
    local account, password = log_input()
    local res = call_RPC("sign_in", {
        account = account,
        password = password
    })
    if not res then -- 失去与服务端的连接
        return
    end
    if res.result ~= errorcode.ok then
        echo_error(res)
        return
    end
    -- connect 大厅
    logged = true -- 掉线重连问题
end

function command.sign_up()
    local account, password = log_input()
    local res = call_RPC("sign_up", {
        account = account,
        password = password
    })
    if not res then -- 失去与服务端的连接
        return
    end
    if res.result ~= errorcode.ok then
        echo_error(res)
        return
    end
    -- connect 大厅
    logged = true -- 掉线重连问题
end

local function check_cmd(cmd)
    if not command[cmd] then
        print("Command not found !")
        return false
    end
    if cmd ~= "sign_in" and cmd ~= "sign_up" and cmd ~= "quit" and not logged then
        print("Please log in first !")
        return false
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

main()
