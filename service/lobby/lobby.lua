local sql_cmd = require "sql_command"
local config = require "server_config"
local skynet = require "skynet"
local servernet = require "servernet"
local LIST = require "list"
local proto = require "pack_proto"
local sproto = require "sproto"
local enum = require "enum"
local socket = require "skynet.socket"
local error = require "error"
local host = sproto.new(proto.lobbymsg):host("package")
local pack_req = host:attach(sproto.new(proto.lobbymsg))

local lobby = {
    conn = {}, -- fd -> token
    user_data = {}, -- token -> user_data {score,gate_addr,gate_port,status,addr,fd,battle}
    data_base = nil,
    list = LIST:new()
}

function lobby:notify_to_battle(fd, battle_service)
    local token = self.conn[fd]
    sql_cmd.update_status_by_token(self.data_base, config.sql_table[1], token, enum.status.battle)

    self.user_data[token].status = enum.status.battle
    self.user_data[token].gate_addr = config.gated_conf.address
    self.user_data[token].gate_port = config.gated_conf.port
    self.user_data[token].battle_service = battle_service
    sql_cmd.update_lobbyline_by_token(self.data_base, config.sql_table[2], token, self.user_data[token].gate_addr,
        self.user_data[token].gate_port, self.user_data[token].battle_service)
    local args = {}
    args.address = config.gated_conf.address
    args.port = config.gated_conf.port
    local msg = pack_req("notify_to_battle", args)
    skynet.call("GATED", "lua", "register", {
        token = token,
        battle_service = battle_service
    })
    servernet.send(fd, msg)
end

function lobby:go_battle()
    if self.list:get_length() >= config.players_per_battle then
        local battle_service = skynet.newservice("battle/main")
        local players_accounts = {}
        for _ = 1, config.players_per_battle do
            local token = self.list:pop()
            self:notify_to_battle(self.user_data[token].fd, battle_service)
            table.insert(players_accounts, token)
        end
        -- local battle = skynet.call(battle_service, "lua", "init_battle", players_accounts)
        -- skynet.fork(function()
        --     battle:start()
        -- end)
    end
end

function lobby:init_user_data(fd, addr, token)
    local data_account = sql_cmd.query_line_by_token(self.data_base, config.sql_table[1], token)
    local data_lobby = sql_cmd.query_line_by_token(self.data_base, config.sql_table[2], token)
    if not next(data_account) then
        return {
            result = error.Invalidtoken,
            conf = nil
        }
    end
    if not next(data_lobby) then
        sql_cmd.insert_line_lobby(self.data_base, config.sql_table[2], token)
        data_lobby = sql_cmd.query_line_by_token(self.data_base, config.sql_table[2], token)
    end
    self.user_data[token] = data_lobby[1]
    self.user_data[token].score = data_account[1].score
    self.user_data[token].status = data_account[1].status
    self.user_data[token].addr = addr
    self.user_data[token].fd = fd
end

function lobby:extra(func, fd, addr)
    if func == "ready" then
        self:go_battle()
    elseif func == "sign_out" then
        return true
    end
end

function lobby:disconnect(fd)
    if self.conn[fd] then
        local token = self.conn[fd]
        local data = self.user_data[token]
        sql_cmd.update_score_by_token(self.data_base, config.sql_table[1], token, data.score)
        if data.status ~= enum.status.battle then
            if data.status == enum.status.ready then
                self.list:remove(token)
            end
            sql_cmd.delete_line_by_token(self.data_base, config.sql_table[2], token)
            sql_cmd.update_status_by_token(self.data_base, config.sql_table[1], token, enum.status.outline)
        end
        self.user_data[token] = nil
        self.conn[fd] = nil
    end
    socket.close(fd)
end

return lobby
