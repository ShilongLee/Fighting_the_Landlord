package.cpath = "skynet/luaclib/?.so"
package.path = "skynet/lualib/?.lua;service/?.lua"
local socket = require "client.socket"
local proto = require "pack_proto"
local sproto = require "sproto"
local host = sproto.new(proto.c2s):host "package"
local pack_req = host:attach(sproto.new(proto.c2s))
