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
	}
}

bind 2{
	request {
		token 0 : integer
	}
	response {
		result 0 : integer
	}
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
		token 3 : integer
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
		token 3 :integer
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
		token 0 : integer
	}
	response {
		.data {
			token 0 : integer
			address 1 : string
			port 2 : integer
		}
		result 0 : integer
		conf 1 : data
	}
}

query_score 3{
	request {
		account 0 : string
	}
	response {
		.data {
			account 0 : string
            score 1 : integer
		}
		result 0 : integer
		user_data 1 : data
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
		token 0 : integer
		address 1 : string
		port 2 : integer
	}
	response {}
}

quit 7{
	request {}
	response {}
}

]]

return proto
