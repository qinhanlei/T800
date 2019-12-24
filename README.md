# T800
- Based on [terminator](https://github.com/qinhanlei/terminator) which based on [skynet](https://github.com/cloudwu/skynet)


## Architecture
```
OUTSIDE <===> http:agents -- all other services 
                                               
 client <---> gateway:agents -- user:users      \
                    |       /       \         -- database:agents
               login:agents   dungeon:cells     /
                                 /   |    \  
                               hall chat  games
```
- Just one skynet node
- `gateway`
  - connect with client
  - forward websocket protobuf msg
- `login`
  - regitster
  - auth
- `dungeon`
  - the game world 
- `database`
  - major in `MongoDB`
  - minor in `Redis`
- `http`
  - outside http[s] communication
  - client, 3rd platfrom and so on



## How to use
- clone [terminator](https://github.com/qinhanlei/terminator) then build
- let `terminator` and `T800` in same path
- `sh run.sh`
