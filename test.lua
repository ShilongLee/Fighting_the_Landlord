package.cpath = "/root/Fighting_the_Landlord/skynet/luaclib/?.so;/root/Fighting_the_Landlord/luaclib/?.so"
package.path = "/root/Fighting_the_Landlord/skynet/lualib/?.lua;/root/Fighting_the_Landlord/service/?.lua;/root/Fighting_the_Landlord/etc/?.lua;/root/Fighting_the_Landlord/lualib/?.lua;/root/Fighting_the_Landlord/proto/?.lua;"
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

local socket = require "client.socket"
print("输入:")
local str = io.read()
print(str)

-- 发送消息
local msg = pack_req("sign_in", {
    account = "lishilong1",
    password = "asdas"
}, session)
local pack = string.pack(">s2", msg)
socket.send(fd, pack)

-- 接收回复
local str = socket.recv(fd)
local res = unpack(str)
local _, _, res = host:dispatch(res)

-- 输出回复
print("输出回复:")
for k, v in pairs(res) do
    print(k, v)
end

print("输入:")
local str = io.read()
print(str)
