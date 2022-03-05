local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "skynet.netpack"
local proto = require "proto"
local sproto = require "sproto"
local config = require "server_config"

local handler = {}
local lobby_server = {}
local battle_server = {}
local lobby_user_on = {} -- fd -> server addr
local battle_user_on = {}
local host = sproto.new(proto.gatedmsg):host("package")
local response_func = {} -- fd 
local conn = {}

local function redirect(msgtype, msg, fd)
    if msgtype == "lobby" then
        skynet.redirect(lobby_user_on[fd], conn[fd], "client", msg)
    elseif msgtype == "battle" then
        skynet.redirect(battle_user_on[fd], conn[fd], "client", msg)
    end
end

local function lobby_select(fd)
    local lobby
    local lobby_sums = #lobby_server
    if lobby_sums == 0 or lobby_server[1].on_line == config.lobby_max_players then
        lobby = skynet.newservice("lobby")
    else
        lobby = lobby_server[fd % lobby_sums]
    end
    lobby_user_on[fd] = lobby
    lobby_server.insert({
        address = lobby,
        on_line = 1
    })
end

function handler.message(fd, msg, size)
    local data = netpack.tostring(msg, size)
    local _, packagename, args, response = host:dispatch(data)
    response_func[packagename] = response
    redirect(args.msgtype, args.msg, fd)
end

function handler.connect(fd, ipaddr)
    gateserver.openclient(fd)
    conn[fd] = ipaddr
    if not lobby_user_on then
        lobby_select(fd)
    end
end

function handler.disconnect(fd)
    -- print(fd .. "disconnect")
end

function handler.error(fd, msg)
    print(fd .. "error:" .. msg)
end

function handler.open(source, conf)
    print("gateserver start...........")
end

gateserver.start(handler)
