local error = require "error"
local config = require "server_config"
local skynet = require "skynet"
local sql_cmd = require "sql_command"
local lobby = require "lobby.lobby"
local enum = require "enum"
local command = {}

function command.ready(fd, addr, args)
    lobby.user_data[lobby.conn[fd]].status = enum.status.ready
    sql_cmd.update_status_by_token(lobby.data_base,config.sql_table[1],lobby.conn[fd],enum.status.ready)
    lobby.list:insert(lobby.conn[fd])
    return {
        result = error.ok
    }
end

function command.cancel_ready(fd, addr, args)
    lobby.user_data[lobby.conn[fd]].status = enum.status.lobby
    sql_cmd.update_status_by_token(lobby.data_base,config.sql_table[1],lobby.conn[fd],enum.status.lobby)
    lobby.list:remove(lobby.conn[fd])
    return {
        result = error.ok
    }
end

function command.sign_out(fd, addr, args)
    return {
        result = error.ok
    }
end

-- 绑定token和tcp连接
function command.bind(fd, addr, args)
    local token = args.token
    lobby.conn[fd] = token
    -- 从数据库取得记录
    local res = lobby:init_user_data(fd, addr, token)
    if res then
        return res
    end

    if lobby.user_data[token].status == enum.status.battle then
        -- 重连到战斗
        skynet.call("GATED", "lua", "register", {
            token = token,
            battle_service = lobby.user_data[token].battle_service
        })
        return {
            result = error.Reconnect,
            conf = {
                address = config.gated_conf.address,
                port = config.gated_conf.port
            }
        }
    else
        -- 更改状态为在大厅中
        sql_cmd.update_status_by_token(lobby.data_base, config.sql_table[1], token, enum.status.lobby)
        lobby.user_data[token].status = enum.status.lobby
    end

    return {
        result = error.ok,
        conf = nil
    }
end

function command.query_score(fd, addr, args)
    local score = lobby.user_data[lobby.conn[fd]].score
    return {
        result = error.ok,
        score = score
    }
end

return command
