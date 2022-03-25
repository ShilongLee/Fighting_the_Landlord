local errorcode = require "error_code"

local logind = {
    data_base = nil,
    sign_up_cnt = 0
}

-- 检查用户名和密码是否合法
function logind.check_args(user_data)
    user_data.account = string.gsub(user_data.account, ' ', '')
    user_data.password = string.gsub(user_data.password, ' ', '')
    if user_data.account == nil or user_data.account == "" then
        return errorcode.Nilaccount
    end
    if #user_data.account > 12 then
        return errorcode.Longaccount
    end
    if #user_data.password > 12 then
        return errorcode.Longpasswd
    end
    return errorcode.ok
end

function logind:get_uid()
    local time = os.time()
    local uid = time * 100000 + self.sign_up_cnt % 100000
    self.sign_up_cnt = self.sign_up_cnt + 1
    return uid
end

return logind
