package.cpath = "skynet/luaclib/?.so"
package.path = "skynet/lualib/?.lua;./src/?.lua"
local socket = require "client.socket"
local proto = require "proto"
local sproto = require "sproto"
local host = sproto.new(proto.c2s):host "package"
local pack_req = host:attach(sproto.new(proto.c2s))

local fd = socket.connect("127.0.0.1",8888)
local str = "handshake"
local size = "nine"
local pack = size..pack_req(str)
local msg = string.pack(">s2",pack)
socket.send(fd,msg)