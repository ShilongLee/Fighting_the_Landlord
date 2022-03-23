local gated = {
    conn = {}, -- fd -> {token,account,battle}
    Will_conn = {}, -- token -> {token,account,battle}
    caddr = {}, -- fd -> addr
    battle = {} -- battle -> fd
}

function gated.echo(addr, fd, msg)
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

return gated
