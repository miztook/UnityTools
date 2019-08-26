
-- test 1:
co = coroutine.create(function () 
		print("Hello World") 
	end)

print(co)

print(coroutine.status(co))

-- test 2:
co = coroutine.create(function ()
    for i = 1, 3 do
        print("co", i)
        coroutine.yield()
    end
end)
----- OK，开始执行，直到第一次到达yield
coroutine.resume(co)        --> co     1
----- 此时状态再次转换为suspended
print(coroutine.status(co)) --> suspended
----- 再次运行多次
coroutine.resume(co)        --> co     2
coroutine.resume(co)        --> co     3
coroutine.resume(co)        --> prints nothing
print(coroutine.resume(co)) --> false  cannot resume dead coroutine


-- test 3:
--[[
function receive (connection)
    connection:settimeout(0)    -- 设置为非阻塞模式
    local s, status, partial = connection:receive(2^10)
    if status == "timeout" then
        coroutine.yield(connection)
    end
    return s or partial, status
end

function download (host, file)
    local c = assert(socket.connect(host, 80))
    local count = 0             -- 用于统计读取的字节数
    c:send("GET " .. file .. " HTTP/1.0\r\n\r\n")
    repeat
        local chunk, status = receive(c)
        count = count + #chunk
    until status == "closed"
    c:close()
    print(file, count)
end

threads = {}
function get (host, file)
    -- 创建协程
    local co = coroutine.create(function ()
        download(host, file)
    end)
    table.insert(threads, co)   -- 将创建的协程添加到列表中，等待被调用
end

function dispatch ()
    local i = 1
    while true do
        if threads[i] == nil then               -- 判断是否还有需要执行的线程
            if threads[1] == nil then break end -- 判断是否已经都执行完
            i = 1                               -- 还有，从头开始执行一次
        end
        local status, res = coroutine.resume(threads[i])
        if not res then   -- 返回false表示该协程已经执行完
            table.remove(threads, i)  -- 删除之
        else
            i = i + 1     -- 然后执行下一个
        end
    end
end

host = "www.w3.org"
get(host, "/TR/html401/html40.txt")
get(host, "/TR/2002/REC-xhtml1-20020801/xhtml1.pdf")
get(host, "/TR/REC-html32.html")
get(host, "/TR/2000/REC-DOM-Level-2-Core-20001113/DOM2-Core.txt")
dispatch()
]]

-- test 4:
-- 使用协程实现生产者消费者
function receive()
    local status, value = coroutine.resume(producer)
    return value
end

function send(x)
    coroutine.yield(x)
end

producer = coroutine.create(
    function()
        while true do
            local x = io.read()
            send(x)
        end
    end)

function consumer ()
    while true do
        local x = receive()
        io.write(x, "\n")
    end
end

consumer()