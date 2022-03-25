local logger = {}

function logger.echo(addr, fd, msg)
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

return logger
