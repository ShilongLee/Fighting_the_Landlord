local errorcode = require "error_code"
local config = require "server_config"
local skynet = require "skynet"
local sql_cmd = require "sql_command"
local lobby = require "lobby.lobby"
local command = {}

function command.quit(fd, addr, args)
    if lobby.conn[fd] then
        sql_cmd.on_line_false(lobby.data_base, lobby.conn[fd])
        sql_cmd.update_score(lobby.data_base, lobby.conn[fd], lobby.user_data[lobby.conn[fd]].score)
        if lobby.user_data[lobby.conn[fd]].ready then
            lobby.list:remove(lobby.conn[fd])
        end
        lobby.user_data[lobby.conn[fd]] = nil
        lobby.conn[fd] = nil
    end
    return {
        result = errorcode.ok
    }
end

function command.ready(fd, addr, args)
    lobby.user_data[lobby.conn[fd]].ready = true
    lobby.list:insert(lobby.conn[fd])
    return {
        result = errorcode.ok
    }
end

function command.cancel_ready(fd, addr, args)
    lobby.user_data[lobby.conn[fd]].ready = false
    lobby.list:remove(lobby.conn[fd])
    return {
        result = errorcode.ok
    }
end

function command.sign_out(fd, addr, args)
    local account = lobby.conn[fd]
    sql_cmd.on_line_false(lobby.data_base, lobby.conn[fd])
    sql_cmd.update_score(lobby.data_base, lobby.conn[fd], lobby.user_data[lobby.conn[fd]].score)
    if lobby.user_data[account].ready then
        lobby.list:remove(account)
    end
    lobby.user_data[account] = nil
    lobby.conn[fd] = nil
    return {
        result = errorcode.ok
    }
end

function command.bind(fd, addr, args)
    local token = args.token
    local data = lobby.Will_conn[token]
    data.fd = fd
    data.addr = addr
    lobby.Will_conn[token] = nil
    lobby.conn[fd] = data.account
    if lobby.user_data[data.account] and lobby.user_data[data.account].battle then
        -- 重连到战斗
        local account = data.account
        lobby.user_data[account].fd = fd
        lobby.user_data[account].addr = addr
        lobby.conn[lobby.user_data[account].fd] = nil
        lobby.user_data[account].gate_addr = config.gated_conf.address
        lobby.user_data[account].gate_port = config.gated_conf.port
        skynet.call("GATED", "lua", "Reg", {
            token = lobby.user_data[account].token,
            account = account,
            battle = lobby.user_data[account].battle
        })
        return {
            result = errorcode.Reconnect,
            conf = {
                token = lobby.user_data[account].token,
                address = config.gated_conf.address,
                port = config.gated_conf.port
            }
        }
    else
        sql_cmd.on_line_true(lobby.data_base, data.account)
        lobby.user_data[data.account] = data
    end
    return {
        result = errorcode.ok,
        conf = nil
    }
end

function command.query_score(fd, addr, args)
    local account = args.account
    local user_data = lobby.user_data[account]
    return {
        result = errorcode.ok,
        user_data = {
            account = user_data.account,
            score = user_data.score
        }
    }
end

return command
