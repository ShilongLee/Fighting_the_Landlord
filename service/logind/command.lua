local errorcode = require "error_code"
local config = require "server_config"
local logind = require "logind.logind"
local command = {}

function command.sign_in(user_data)
    -- 从数据库取得记录
    local req = "select * from account where account = \'" .. user_data.account .. "\';"
    local res = logind.data_base:query(req)
    -- 验证账号密码
    if next(res) == nil or user_data.password ~= res[1].password then
        return {
            result = errorcode.Signfail
        }
    end
    -- 验证重复登录
    if res[1].on_line == "true" then
        return {
            result = errorcode.Mutisign
        }
    end
    logind.token = logind.token + 1
    logind.Reg_in_lobby(res, logind.token)
    return {
        result = errorcode.ok,
        address = config.lobby_conf.address,
        port = config.lobby_conf.port,
        token = logind.token
    }
end

function command.sign_up(user_data)
    -- 写入
    local req = "insert into account(account,password,score,on_line) values( \'" .. user_data.account .. "\',\'" ..
                    user_data.password .. "\'," .. "0 ,\'false\')" .. ";"
    local res = logind.data_base:query(req)
    -- 验证重复注册
    if res.errno and res.errno == errorcode.Dupaccount then
        return {
            result = errorcode.Dupaccount
        }
    end
    logind.token = logind.token + 1
    logind.Reg_in_lobby({{
        account = user_data.account,
        score = 0
    }}, logind.token)
    return {
        result = errorcode.ok,
        address = config.lobby_conf.address,
        port = config.lobby_conf.port,
        token = logind.token
    }
end

return command
