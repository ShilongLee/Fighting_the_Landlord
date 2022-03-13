package.path = "etc/?.lua"
local str_errcode = require "str_errcode"
local error = {}

function error.strerror(error_code)
    print(str_errcode[error_code])
end

return error
