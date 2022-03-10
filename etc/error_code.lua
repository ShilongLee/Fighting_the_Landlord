local error_code = {
    ok = 0,
    Nofunction = 1, --没有此方法
    Nilaccount = 2, --空的用户名
    Longaccount = 3,   --账号过长
    Longpasswd = 4, --密码过长
    Signfail = 5,   --账号或者密码错误
    Mutisign = 6,    --重复登录
    Dupaccount = 1062,  --重复的用户名
}

return error_code