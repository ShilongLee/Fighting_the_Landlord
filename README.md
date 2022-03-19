# Fighting_the_Landlord
## Start up
- server : ./skynet/skynet ./service/config
- clinet : lua ./client.lua

## directory
- etc : Config files
- examples : Skynet usage example
- luaclib : C library for lua
- lualib : Lua library
- proto : Communication protocol between server and client
- service : Server main service
- skynet : Skynet frame
- client.lua : client program

## 服务器流程
客户端连接logind服务进行登录操作，登录成功后连接到lobby，准备游戏后，每满2(config.players_per_battle)人开启战斗，玩家连接战斗网关，网关进行消息分发，并支持断线重连。
