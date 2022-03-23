local str_errcode = {
    ok = 0,
    Nofunction = 1, -- 没有此方法
    Nilaccount = 2, -- 空的用户名
    Longaccount = 3, -- 账号过长
    Longpasswd = 4, -- 密码过长
    Signfail = 5, -- 账号或者密码错误
    Mutisign = 6, -- 重复登录
    Dupaccount = 1062 -- 重复的用户名
}
str_errcode[0] = "All the best !"
str_errcode[1] = "Error: Function not exist !"
str_errcode[2] = "Error: account is nil !"
str_errcode[3] = "Error: account cannot longger than 12 characters !"
str_errcode[4] = "Error: Password cannot longger than 12 characters !"
str_errcode[5] = "Error: account or password is wrong  !"
str_errcode[6] = "Error: Repeat Login !"
str_errcode[7] = "Warning: Reconnect !"
str_errcode[1062] = "Error: account exists !"

return str_errcode
