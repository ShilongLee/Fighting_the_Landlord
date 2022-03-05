local str = "lishilong"
local pack = string.pack(">s2","abc")..string.pack(">s2",str)
local res,k = string.unpack(">s2", pack)
local ans = string.unpack(">s2", res)
print(ans)
print(k)