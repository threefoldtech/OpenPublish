--local host, port = "127.0.0.1", 8001
--local socket = require("socket")
--local tcp = assert(socket.tcp())
--tcp:connect(host, port)

local redis = require 'redis'
local json = require "cjson"
local client = redis.connect('127.0.0.1', 8888)

local server = require "resty.websocket.server"
local wb, err = server:new {
    timeout = 5000,
    max_payload_len = 65535
}
if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
end
while true do
    local data, type, err = wb:recv_frame()
    if wb.fatal then
        ngx.log(ngx.ERR, "failed to receive frame: ", err)
        return ngx.exit(444)
    end
    if type == "close" then
        break
    elseif type == "text" then
        --        tcp:send(data);
        --        local res, _, partial = tcp:receive("*l")
        --        if string.sub(res, 1, 1) == "$" then
        --            local bytes = tcp:receive(string.sub(res, 2))
        --            res = res .. "\r\n" .. bytes
        --        end
        data = json.decode(data)
        client["gedis"] = redis.command(data['command'])
        local response, args, headers
        if data['args'] then
            args = json.encode(data['args'])
        end
        if data['headers'] then
            headers = json.encode(data['headers'])
        end

        if args and headers then
            response = client:gedis(args, headers)
        elseif args then
            response = client:gedis(args)
        else
            response = client:gedis()
        end

        local bytes, err = wb:send_text(response)
        if not bytes then
            ngx.log(ngx.ERR, "failed to send text: ", err)
        end
        ngx.log(ngx.ERR, response)
    end
end