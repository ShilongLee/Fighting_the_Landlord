local socket = require "skynet.socket"
local skynet = require "skynet"
local sql_cmd = require "sql_command"
local lobby = require "lobby.lobby"
local Log = require "logger"
local enum = require "enum"
local config = require "server_config"
local call = {}

function call.battle_end(args)
    local token = args.token
    local res = args.res
    lobby.user_data[token].score = lobby.user_data[token].score + res
    lobby.user_data[token].battle_service = nil
    lobby.user_data[token].status = enum.status.lobby
    lobby.user_data[token].battle_service = nil
    lobby.user_data[token].gate_addr = nil
    lobby.user_data[token].gate_port = nil
    sql_cmd.update_status_by_token(lobby.data_base, config.sql_table[1], token, enum.status.lobby)
    sql_cmd.update_score_by_token(lobby.data_base, config.sql_table[1], token, lobby.user_data[token].score)
    sql_cmd.update_lobbyline_by_token(lobby.data_base, config.sql_table[2], token)
    -- 更新比赛结果
end

return call
