local socket = require "skynet.socket"

local last = ""
local servernet = {}

local function unpack(str)
    local size = #str
    if size < 2 then
        return nil, str
    end
    local len = str:byte(1) * 256 + str:byte(2)
    if size < len + 2 then
        return nil, str
    end
    return str:sub(3, 2 + len), str:sub(3 + len)
end

function servernet.recv(fd, last)
    local result
    result, last = unpack(last)
    if result then
        return result, last
    end
    local r = socket.read(fd)
    if not r or r == "" then
        return nil, last
    end
    return servernet.recv(fd, last .. r)
end

function servernet.send(fd, msg)
    local pack = string.pack(">s2", msg)
    local res = socket.write(fd, pack)
    return res
end

return servernet