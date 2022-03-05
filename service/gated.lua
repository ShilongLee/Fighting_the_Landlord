local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local proto = require "proto"
local sproto = require "sproto"

local handler = {}
local lobby_server = {}
local battle_server = {}
local user_on = {}  --fd -> server addr

function handler.message(fd,msg,size)
    local data = netpack.tostring(msg,size)
    print(string.sub(data,1,4))     --解析出消息类型
    local res = string.sub(data,5)   
    local host = sproto.new(proto.c2s):host("package")
    print(host:dispatch(res))
end

function handler.connect(fd, ipaddr)
    gateserver.openclient(fd) 
    print(ipaddr .. "connect")
    print("fd="..fd)
end

function handler.disconnect(fd)
    --print(fd .. "disconnect")
end

function handler.error(fd, msg)
    print(fd .. "error:" .. msg)
end

function handler.open(source,conf)
    print("gateserver start...........")
end

gateserver.start(handler)

-- 包头信息：

-- 消息Id：消息的唯一id，用于区分每个消息的逻辑意义，知道这个消息是干什么的
-- 消息发送时间
-- 是否压缩
-- 是否加密
-- 服务类型，这个主要用于分布式服务。
-- crc32校验码，用于保证消息的完整性。
-- 消息序列Id:  每个用户登陆之后，从给服务器发送第一条消息起，开始累计计数，叫序列id,Id主要用于服务器判断消息的唯一性，对消息做等幂处理。
-- 包体信息

-- 消息体，向服务器发送的请求内容，这个部分可以根据自己的业务需要自行设计，可以是json，也可以是由protobuf序列化组成的。而且这部分信息可以加密码，压缩。