local sql = {}

function sql.insert_line_account(data_base, table, uid, account, password)
    local req = "insert into " .. table .. "(uid,account,password,token,score,online) values(" .. uid .. ",\"" ..
                    account .. "\",\"" .. password .. "\",null,0,0);"
    return data_base:query(req)
end

function sql.insert_line_lobby(data_base, table, token, gated_addr, gated_fd, battle_service)
    gated_addr = gated_addr or "null"
    gated_fd = gated_fd or "null"
    battle_service = battle_service or "null"
    local req =
        "insert into " .. table .. "(token, gated_addr, gated_fd,  battle_service) values(\"" .. token .. "\"," .. "\"" ..
            gated_addr .. "\"" .. "," .. gated_fd .. "," .. battle_service .. ");"
    return data_base:query(req)
end

function sql.query_line_by_account(data_base, table, account)
    local req = "select * from " .. table .. " where account = \"" .. account .. "\";"
    return data_base:query(req)
end

function sql.query_line_by_uid(data_base, table, uid)
    local req = "select * from " .. table .. " where uid = " .. uid .. ";"
    return data_base:query(req)
end

function sql.query_line_by_token(data_base, table, token)
    local req = "select * from " .. table .. " where token = \"" .. token .. "\";"
    return data_base:query(req)
end

function sql.update_online_by_token(data_base, table, token, status)
    local req = "update " .. table .. " set online = " .. status .. " where token = \"" .. token .. "\";"
    return data_base:query(req)
end

function sql.update_score_by_token(data_base, table, token, score)
    local req = "update " .. table .. " set score = " .. score .. " where token = \"" .. token .. "\";"
    return data_base:query(req)
end

function sql.update_token_by_uid(data_base, table, uid, token)
    local req = "update " .. table .. " set token = \"" .. token .. "\" where uid = " .. uid .. ";"
    return data_base:query(req)
end

function sql.update_lobbyline_by_token(data_base, table, token, gated_addr, gated_fd, battle_service)
    local req = "update " .. table .. "set token = " .. "\"" .. token .. "\"" .. "," .. "gated_addr = " .. "\"" ..
                    gated_addr .. "\"" .. "," .. "gated_fd = " .. gated_fd .. "," .. "battle_service = " ..
                    battle_service .. " where token = " .. "\"" .. token .. "\";"
    return data_base:query(req)
end

function sql.delete_line_by_token(data_base, table, token)
    local req = "delete from " .. table .. " where token = \"" .. token .. "\";"
    return data_base:query(req)
end

function sql.clear_online(data_base, table)
    local req = "update " .. table .. " set online = 0 where account like \"%\";"
    return data_base:query(req)
end

function sql.clear_token(data_base, table)
    local req = "update " .. table .. " set token = null where account like \"%\";"
    return data_base:query(req)
end

return sql
