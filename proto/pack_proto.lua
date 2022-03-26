local sprotoparser = require "sprotoparser"

local proto = {}

proto.gatedmsg = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

message 1{
	request {
		type 0 : string
		msg 1 : string
	}
	response {
		result 0 : integer
		msg 1 : string
	}
}

bind 2{
	request {
		token 0 : string
	}
	response {
		result 0 : integer
	}
}

notify_battle_end 3{
	request {
		address 0 : string
		port 1 : integer
	}
	response {}
}

]]

proto.logindmsg = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

sign_in 1 {
	request {
		account 0 : string
		password 1 : string
	}
	response {
		result 0 : integer
		address 1 : string
		port 2 : integer
		token 3 : string
	}
}

sign_up 2 {
	request {
		account 0 : string
		password 1 : string
	}
	response {
		result 0 : integer
		address 1 : string
		port 2 : integer
		token 3 :string
	}
}

]]

proto.lobbymsg = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

sign_out 1 {
	request {}
	response {
		result 0 : integer
	}
}

bind 2{
	request {
		token 0 : string
	}
	response {
		.data {
			address 1 : string
			port 2 : integer
		}
		result 0 : integer
		conf 1 : data
	}
}

query_score 3{
	request {}
	response {
		result 0 : integer
		score 1 : integer
	}
}

ready 4{
	request {}
	response {
		result 0 : integer
	}
}

cancel_ready 5{
	request {}
	response {
		result 0 : integer
	}
}

notify_to_battle 6{
	request {
		address 1 : string
		port 2 : integer
	}
	response {}
}

]]

proto.battlemsg = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

choose_career 1 {
	request {
		career 0 : integer
	}
	response {
		result 0 : integer
	}
}

]]

return proto
