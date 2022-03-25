local sql_cmd = require "sql_command"
local config = require "server_config"
local enum = require "enum"

local token = {}

local function check_token(res)
    local token = res[1].token
    local timediff = os.time() - tonumber(string.sub(token, -10))
    if res[1].online == enum.battle or timediff <= enum.tokendeadline then
        return true
    end
    return false
end

function token.get_token(data_base, uid, password)
    local res = sql_cmd.query_line_by_uid(data_base, config.sql_table[1], uid)
    if res[1].token and check_token(res) then
        return res[1].token
    end
    local time = os.time()
    local token = uid .. password .. time
    sql_cmd.update_token_by_uid(data_base, config.sql_table[1], res[1].uid, token)
    return token
end

return token
