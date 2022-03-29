local error = require "error"
local config = require "server_config"
local logind = require "logind.logind"
local TOKEN = require "token"
local sql_cmd = require "sql_command"
local enum = require "enum"
local command = {}

function command.sign_in(user_data)
    -- 检查用户名和密码是否合法
    local illegal = logind.check_args(user_data)
    if illegal ~= error.ok then
        return {
            result = illegal
        }
    end
    -- 从数据库取得记录
    local res = sql_cmd.query_line_by_account(logind.data_base, config.sql_table[1], user_data.account)
    -- 验证账号密码
    if next(res) == nil or user_data.password ~= res[1].password then
        return {
            result = error.Signfail
        }
    end
    -- 验证重复登录
    if res[1].status == enum.status.lobby then
        return {
            result = error.Mutisign
        }
    end
    -- 获取token
    local token = TOKEN.get_token(logind.data_base, res[1].uid, user_data.password)
    return {
        result = error.ok,
        address = config.lobby_conf.address,
        port = config.lobby_conf.port,
        token = token
    }
end

function command.sign_up(user_data)
    -- 检查用户名和密码是否合法
    local illegal = logind.check_args(user_data)
    if illegal ~= error.ok then
        return {
            result = illegal
        }
    end
    local uid = logind:get_uid()
    -- 插入新用户
    local res = sql_cmd.insert_line_account(logind.data_base, config.sql_table[1], uid, user_data.account,
        user_data.password)
    -- 验证重复注册
    if res.errno and res.errno == error.Dupaccount then
        return {
            result = error.Dupaccount
        }
    end
    -- 获取token
    local token = TOKEN.get_token(logind.data_base, uid, user_data.password)
    return {
        result = error.ok,
        address = config.lobby_conf.address,
        port = config.lobby_conf.port,
        token = token
    }
end

return command
