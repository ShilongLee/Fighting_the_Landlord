-- package.cpath = "luaclib/?.so;skynet/luaclib/?.so;"
-- package.path = "skynet/lualib/?.lua;proto/?.lua;"
-- local socket = require "clientsocket"
-- local sproto = require "sproto"
-- local proto = require "pack_proto"
-- local host = sproto.new(proto.logindmsg):host("package")
-- local pack_req = host:attach(sproto.new(proto.logindmsg))
-- -- local addr = "39.106.6.167"
-- local addr = "127.0.0.1"
-- local port = 6666
-- local fd = socket.connect(addr, port)       ---------------
-- local session = 1

-- local function unpack(str)
--     local size = #str
--     if size < 2 then
--         return nil, str
--     end
--     local len = str:byte(1) * 256 + str:byte(2)
--     if size < len + 2 then
--         return nil, str
--     end
--     return str:sub(3, 2 + len), str:sub(3 + len)
-- end

-- print("输入:")
-- local str = io.read()
-- print(str)

-- -- 发送消息
-- local msg = pack_req("sign_in", {
--     account = "lishilong1",
--     password = "asdas"
-- }, session)
-- local pack = string.pack(">s2", msg)
-- socket.send(fd, pack)               ---------------------

-- -- 接收回复
-- local str = socket.recv(fd)     ----------------
-- local res = unpack(str)
-- local _, _, res = host:dispatch(res)

-- -- 输出回复
-- print("输出回复:")
-- for k, v in pairs(res) do
--     print(k, v)
-- end

-- print("输入:")
-- str = io.read()
-- print(str)