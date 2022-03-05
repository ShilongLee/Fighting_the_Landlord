package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;practice/?.lua" -- ?
local proto = require "proto"
local sproto = require "sproto"
local socket = require "client.socket"
local host = sproto.new(proto.c2s):host "package"   --?
local pack_req = host:attach(sproto.new(proto.c2s)) -- ?
local fd = socket.connect("127.0.0.1", 8888)
local session = 0

local function req(func, args)
    session = session + 1
    local str = pack_req(func, args, session)
    local pack = string.pack(">s2",str)
    socket.send(fd,pack)
    print("request:" .. session)
end

while true do
    local str = socket.recv(fd)
    if str ~= nil and str ~= "" then
        print(str)
    end
    local req_str = socket.readstdin()
    if req_str then
        if req_str == "quit" then
            socket.close(fd)
            return
        elseif req_str == "handshake" then
            req(req_str)
        else 
            req("say",{name = "lishilong",age = "22"})
        end
    else 
        socket.usleep(1000)
    end
end
