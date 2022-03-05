package.cpath = "skynet/luaclib/?.so"
package.path = "skynet/lualib/?.lua;service/?.lua" -- ?
local socket = require "client.socket"
local sproto = require "sproto"
local proto = require "pack_proto"
local host = sproto.new(proto.logindmsg):host("package")
local pack_req = host:attach(sproto.new(proto.logindmsg))
local session = 0;
local fd = socket.connect("127.0.0.1",6666)

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

local msg = pack_req("sign_in", {
    account = "lishilong",
    password = "123456"
},session)

local pack = string.pack(">s2",msg)
socket.send(fd,pack)
local str = socket.recv(fd)
while not str do
    str = socket.recv(fd)
end
local res = unpack(str)
local a,b,c = host:dispatch(res)
print(a,b,c)
print(c.address,c.port)