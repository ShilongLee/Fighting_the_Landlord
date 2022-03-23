local errorcode = require "error_code"
local gated = require "gated.gated"
local command = {}

local function echo(addr, fd, msg)
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

function command.bind(fd, args)
    local token = args.token
    gated.conn[fd] = gated.Will_conn[token]
    gated.Will_conn[token] = nil
    if not gated.battle[gated.conn[fd].battle] then
        gated.battle[gated.conn[fd].battle] = {}
    end
    table.insert(gated.battle[gated.conn[fd].battle], fd)
    echo(gated.caddr[fd], fd, "bind success")
    return {
        result = errorcode.ok
    }
end

return command
