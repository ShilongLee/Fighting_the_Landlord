local sprotoparser = require "sprotoparser"

local proto = {}

proto.gatedmsg = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

message 1 {
	request {
		msgtype 0 : string	
		time 1 : string
		cnt 2 : integer
		msg 3 : string
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
	}
}

]]

return proto
