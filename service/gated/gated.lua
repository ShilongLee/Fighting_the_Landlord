local gated = {
    conn = {}, -- fd -> {token,addr,battle_service}
    Will_conn = {}, -- token -> {battle}
    battle = {} -- battle_service -> {token...}
}

return gated
