local sql_cmd = require "sql_command"
local config = require "server_config"
local skynet = require "skynet"
local servernet = require "servernet"
local LIST = require "list"
local proto = require "pack_proto"
local sproto = require "sproto"
local host = sproto.new(proto.lobbymsg):host("package")
local pack_req = host:attach(sproto.new(proto.lobbymsg))

local lobby = {
    user_data = {}, -- account -> user_data {account,score,gate_addr,gate_port,ready,addr,fd,token,battle}
    conn = {}, -- fd -> account
    Will_conn = {},
    data_base = nil, -- token -> user_data {account,score,ready}
    list = LIST:new()
}

function lobby.echo(addr, fd, msg) -- delete
    print("ip:" .. addr .. " fd:" .. fd .. "\t" .. msg)
end

function lobby:notify_to_battle(account, fd, battle)
    sql_cmd.on_line_false(self.data_base, account)
    self.conn[self.user_data[account].fd] = nil
    self.user_data[account].ready = false
    self.user_data[account].gate_addr = config.gated_conf.address
    self.user_data[account].gate_port = config.gated_conf.port
    local args = {}
    args.token = self.user_data[account].token
    args.address = config.gated_conf.address
    args.port = config.gated_conf.port
    local msg = pack_req("notify_to_battle", args)
    skynet.call("GATED", "lua", "Reg", {
        token = self.user_data[account].token,
        account = account,
        battle = battle
    })
    servernet.send(fd, msg)
end

function lobby:go_battle()
    if self.list:get_length() >= config.players_per_battle then
        local battle = skynet.newservice("battle")
        for i = 1, config.players_per_battle do
            local account = self.list:pop()
            self.user_data[account].battle = battle
            self:notify_to_battle(account, self.user_data[account].fd, battle)
        end
    end
end

return lobby
