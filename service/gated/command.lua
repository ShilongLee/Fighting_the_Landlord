local error = require "error"
local gated = require "gated.gated"
local Log = require "logger"
local command = {}

function command.bind(fd, args)
    local token = args.token
    gated.conn[fd].battle_service = gated.Will_conn[token]
    gated.Will_conn[token] = nil
    gated.conn[fd].token = token
    if not gated.battle[gated.conn[fd].battle_service] then
        gated.battle[gated.conn[fd].battle_service] = {}
    end
    table.insert(gated.battle[gated.conn[fd].battle_service], fd)
    Log.echo(gated.conn[fd].addr, fd, "bind success")
    return {
        result = error.ok
    }
end

return command
