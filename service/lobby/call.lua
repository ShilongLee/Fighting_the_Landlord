local socket = require "skynet.socket"
local skynet = require "skynet"
local sql_cmd = require "sql_command"
local lobby = require "lobby.lobby"
local Log = require "logger"
local call = {}

function call.battle_end(args)
    lobby.user_data[args.account].battle = nil
    local res = args.res
    -- 更新比赛结果
end

return call
