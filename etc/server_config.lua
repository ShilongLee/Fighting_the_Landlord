local server_config = {
    logind_conf = {
        address = "127.0.0.1",
        port = 6666
    },
    lobby_conf = {
        address = "127.0.0.1",
        port = 7777
    },
    gated_conf = {
        address = "127.0.0.1",
        port = 8888,
        maxclient = 1024,
        nodelay = true
    },
    mysql_conf = {
        host = "rm-2zegwtj04xa28oh1zqo.mysql.rds.aliyuncs.com",
        port = 3306,
        database = "fighting_the_landlord",
        user = "root",
        password = "Ll20000101",
        max_packet_size = 1024 * 1024
    },
    lobby_max_players = 1024,
    players_per_battle = 2,
    init_hp = 10,
    career = {
        Warrior = 1
    },
    sql_table = {"account", "lobby"}
}

return server_config
