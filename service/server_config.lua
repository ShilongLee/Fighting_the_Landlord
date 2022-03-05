local server_config = {}

server_config.gated_conf = {
    address = "127.0.0.1",
    port = 8888,
    maxclient = 1024,
    nodelay = true
}
server_config.logind_conf = {
    address = "127.0.0.1",
    port = 6666
}
server_config.lobby_max_players = 1024

return server_config
