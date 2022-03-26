local error = {
    ok = 0,
    Nofunction = 1, -- 没有此方法
    Nilaccount = 2, -- 空的用户名
    Longaccount = 3, -- 账号过长
    Longpasswd = 4, -- 密码过长
    Signfail = 5, -- 账号或者密码错误
    Mutisign = 6, -- 重复登录
    Reconnect = 7, -- 重新连接 
    Invalidtoken = 8, -- 无效token
    Dupaccount = 1062 -- 重复的用户名
}
error[0] = "All the best !"
error[1] = "Error: Function not exist !"
error[2] = "Error: account is nil !"
error[3] = "Error: account cannot longger than 12 characters !"
error[4] = "Error: Password cannot longger than 12 characters !"
error[5] = "Error: account or password is wrong  !"
error[6] = "Error: Repeat Login !"
error[7] = "Warning: Reconnect !"
error[8] = "Error: Invalid token !"
error[1062] = "Error: account exists !"

function error.print_error(error_code)
    print(error[error_code])
end

return error
