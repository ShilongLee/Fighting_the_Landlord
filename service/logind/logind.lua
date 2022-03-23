local skynet = require "skynet"

local logind = {
    data_base = nil,
    token = 0
}

function logind.echo(addr, fd, msg) -- delete
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

-- 通知大厅要登录的token
function logind.Reg_in_lobby(res, token)
    skynet.send("LOBBY", "lua", "Reg", {
        token = token,
        user_data = {
            account = res[1].account,
            score = res[1].score
        }
    })
end

return logind
