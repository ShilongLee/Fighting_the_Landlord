local sql_cmd = require "sql_command"
local config = require "server_config"
local skynet = require "skynet"
local servernet = require "servernet"
local LIST = require "list"
local proto = require "pack_proto"
local sproto = require "sproto"
local enum = require "enum"
local errorcode = require "error_code"
local host = sproto.new(proto.lobbymsg):host("package")
local pack_req = host:attach(sproto.new(proto.lobbymsg))

local lobby = {
    --                                                  account                   account
    -- user_data = {}, -- account -> user_data {account,score,gate_addr,gate_port,status,addr,fd,token,battle}
    -- conn = {}, -- fd -> account
    -- Will_conn = {}, -- token -> user_data {account,score,ready}
    conn = {}, -- fd -> token
    user_data = {}, -- token -> user_data {score,gate_addr,gate_port,ready,addr,fd,battle}
    data_base = nil,
    list = LIST:new()
}

function lobby:notify_to_battle(account, fd, battle)
    -- sql_cmd.update_online_by_token(self.data_base,token,0)
    -- sql_cmd.on_line_false(self.data_base, account)
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
        local battle_service = skynet.newservice("battle/main")
        local players_accounts = {}
        for i = 1, config.players_per_battle do
            local account = self.list:pop()
            self.user_data[account].battle_service = battle_service
            self:notify_to_battle(account, self.user_data[account].fd, battle_service)
            table.insert(players_accounts, account)
        end
        local battle = skynet.call(battle_service, "lua", "init_battle", players_accounts)
        -- skynet.fork(function()
        --     battle:start()
        -- end)
    end
end

function lobby:disconnect(fd)
    if self.conn[fd] then
        local token = self.conn[fd]
        local data = self.user_data[token]
        sql_cmd.update_score_by_token(self.data_base, config.sql_table[1], token, data.score)
        if data.status == enum.ready then
            self.list:remove(token)
        elseif data.status == enum.battle then
            local res = sql_cmd.query_line_by_token(self.data_base, config.sql_table[2], token)
            if not res then
                sql_cmd.insert_line_lobby(self.data_base, config.sql_table[2], token, data.gate_addr, data.gate_port,
                    data.battle_service)
            else
                sql_cmd.update_lobbyline_by_token(self.data_base, config.sql_table[2], token, data.gate_addr,
                    data.gate_port, data.battle_service)
            end
        else
            sql_cmd.delete_line_by_token(self.data_base, config.sql_table[2], token)
            sql_cmd.update_online_by_token(self.data_base, config.sql_table[1], token, enum.outline)
        end
        self.user_data[token] = nil
        self.conn[fd] = nil
    end
    return {
        result = errorcode.ok
    }
end

return lobby
