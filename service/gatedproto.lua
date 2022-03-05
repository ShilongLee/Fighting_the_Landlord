local sprotoparser = require "sprotoparser"

local proto = {}

proto.app = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

Sign_in 1 {
	request {
		account 0 : string
		password 1 : string
	}
	response {
		result 0 : string
	}
}

Sign_up 2 {
	request {
		account 0 : string
		password 1 : string
	}
	response {
		result 0 : string
	}
}

]]

return proto
