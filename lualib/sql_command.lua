local sql = {}

function sql.clear_online(data_base)
    local req = "update account set on_line = \"false\" where account like \"%\";"
    data_base:query(req)
end

function sql.on_line_true(data_base, account)
    local req = "update account set on_line = \"true\" where account = \"" .. account .. "\";"
    data_base:query(req)
end

function sql.on_line_false(data_base, account)
    local req = "update account set on_line = \"false\" where account = \"" .. account .. "\";"
    data_base:query(req)
end

function sql.update_score(data_base, account, score)
    local req = "update account set score = \"" .. score .. "\" where account = \"" .. account .. "\";"
    data_base:query(req)
end

return sql
