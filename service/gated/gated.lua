local gated = {
    conn = {}, -- fd -> {token,addr,battle_service}
    Will_conn = {}, -- token -> {battle}
    battle = {} -- battle_service -> {token...}
}

function gated:get_fd(token)
    for fd, tab in pairs(self.conn) do
        if tab.token == token then
            return fd
        end
    end
end

return gated
