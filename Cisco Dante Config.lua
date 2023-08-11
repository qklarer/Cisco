doSave = false
showInt = false
saveCount = 0
Buffer = {}
NamedControl.SetText("Debug", "")
for i = 1, 18 do
    NamedControl.SetPosition("int" .. i, 0)
end


NamedControl.SetPosition("saveLED", 0)
SSH = Ssh.New()
SSH.ReadTimeout = 15
SSH.WriteTimeout = 15
SSH.ReconnectTimeout = 10

SSH.IsInteractive = true

function Split(s, delimiter)
    local result = {}

    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end

    local function setPosition(index, value)
        NamedControl.SetPosition("int" .. index, value)
    end

    for k, v in pairs(result) do
        local index = tonumber(v:match("gi(%d+)"))
        local direction = v:match("(Up)") or v:match("(Down)")

        if index and direction then
            setPosition(index, direction == "Up" and 1 or 0)
        end
    end
end

function ParseResponse()            -- function that reads the SSH TCP socket
    rx = SSH:Read(SSH.BufferLength) -- assign the contents of the buffer to a variable
    table.insert(Buffer, rx)
    NamedControl.SetValue("buffFlip", #Buffer)
    NamedControl.SetText("Debug", rx)
    print(rx)
    Split(rx, "\n")
end

--#region SSH Callback
SSH.Connected = function() -- function called when the TCP socket is connected
    print("Socket connected")
end

SSH.Reconnect = function() -- function called when the TCP socket is reconnected
    print("Socket reconnecting...")
end

SSH.Closed = function() -- function called when the TCP socket is closed
    print("Socket closed")
end

SSH.Error = function() -- function called when the TCP socket has an error
    print("Socket error")
end

SSH.Timeout = function() -- function called when the TCP socket times out
    print("Socket timeout")
end

SSH.LoginFailed = function() -- function called when SSH login fails
    print("SSH login failed")
end

SSH.Data = ParseResponse -- ParseResponse is called when the SSH object has data




function TimerClick()
    if NamedControl.GetPosition("Connect") == 1 then
        SSH:Connect(NamedControl.GetText("IP"), 22, NamedControl.GetText("userName"), "Iamlefthanded1!")
        NamedControl.SetPosition("Connect", 0)
    elseif NamedControl.GetPosition("Disconnect") == 1 then
        NamedControl.SetPosition("Disconnect", 0)
        SSH:Disconnect()
        doSave = false
        showInt = false
        saveCount = 0
        NamedControl.SetText("Debug", "")
        for i = 1, 18 do
            NamedControl.SetPosition("int" .. i, 0)
        end

        NamedControl.SetPosition("saveLED", 0)
    end

    if NamedControl.GetPosition("Clear") == 1 then
        Buffer = {}
        NamedControl.SetText("Debug", "")
        NamedControl.SetPosition("Clear", 0)
    end

    if NamedControl.GetPosition("sendCustom") == 1 then
        SSH:Write(NamedControl.GetText("customCommand") .. "\r")
        NamedControl.SetPosition("sendCustom", 0)
    end

    if NamedControl.GetPosition("Space") == 1 then
        SSH:Write(" \r")
        NamedControl.SetPosition("Space", 0)
    end

    if NamedControl.GetValue("buffFlip") > #Buffer then
        NamedControl.SetValue("buffFlip", #Buffer)
    end




    NamedControl.SetText("Debug", Buffer[NamedControl.GetValue("buffFlip")])



    if SSH.IsConnected then
        if showInt == false then
            SSH:Write("end\r")
            SSH:Write("show interface status\r")
            SSH:Write("q\r")
            showInt = true
        end


        NamedControl.SetPosition("connectedLED", 1)

        -- DSCP
        if NamedControl.GetPosition("configDSCP") == 1 then
            SSH:Write("end\r")
            SSH:Write("config t\r")
            SSH:Write("qos map dscp-queue 56 to 8\r")
            SSH:Write("y\r")
            SSH:Write("qos map dscp-queue 46 to 7\r")
            SSH:Write("qos map dscp-queue 8 to 6\r")
            --
            for i = 0, 7 do
                SSH:Write("qos map dscp-queue " .. i .. " to 1\r")
            end
            for i = 9, 45 do
                SSH:Write("qos map dscp-queue " .. i .. " to 1\r")
            end
            for i = 47, 55 do
                SSH:Write("qos map dscp-queue " .. i .. " to 1\r")
            end
            for i = 57, 63 do
                SSH:Write("qos map dscp-queue " .. i .. " to 1\r")
            end
            SSH:Write("end\r")
            doSave = true
            NamedControl.SetPosition("configDSCP", 0)
        end

        -- Multicast
        if NamedControl.GetPosition("configMulticast") == 1 then
            SSH:Write("end\r")
            SSH:Write("config t\r")
            SSH:Write("bridge multicast filtering\r")
            SSH:Write("int vlan 1\r")
            SSH:Write("bridge multicast mode ipv4-group\r")
            SSH:Write("bridge multicast ipv6 mode ip-group\r")
            SSH:Write("end\r")
            doSave = true
            NamedControl.SetPosition("configMulticast", 0)
        end

        -- IGMP
        if NamedControl.GetPosition("configIGMP") == 1 then
            SSH:Write("end\r")
            SSH:Write("config t\r")
            SSH:Write("ip igmp query-interval 30\r")
            SSH:Write("ip igmp snooping\r")
            SSH:Write("ip igmp snooping querier\r")
            SSH:Write("ip igmp snooping vlan 1\r")
            SSH:Write("ip igmp snooping vlan 1 querier\r")
            SSH:Write("end\r")
            doSave = true
            NamedControl.SetPosition("configIGMP", 0)
        end

        -- POE
        for i = 1, 18 do
            if NamedControl.GetPosition("offPower" .. i) == 1 then
                SSH:Write("end\r")
                SSH:Write("config t\r")
                SSH:Write("int g" .. i .. "\r")
                SSH:Write("power inline never\r")
                SSH:Write("end\r")
                NamedControl.SetPosition("offPower" .. i, 0)
            end

            if NamedControl.GetPosition("onPower" .. i) == 1 then
                SSH:Write("end\r")
                SSH:Write("config t\r")
                SSH:Write("int g" .. i .. "\r")
                SSH:Write("power inline auto\r")
                SSH:Write("end\r")
                NamedControl.SetPosition("onPower" .. i, 0)
            end
        end

        -- Write
        if NamedControl.GetPosition("doWrite") == 1 then
            SSH:Write("do write\r")
            SSH:Write("y\r")
            SSH:Write("end\r")
            NamedControl.SetPosition("doWrite", 0)
            doSave = false
            saveCount = 0
            NamedControl.SetPosition("saveLED", 0)
        end
    else
        NamedControl.SetPosition("connectedLED", 0)
    end

    if doSave then
        NamedControl.SetPosition("saveLED", 1)
        saveCount = saveCount + 1
    end
    if saveCount == 60 then
        saveCount = 0
        NamedControl.SetPosition("saveLED", 0)
        doSave = false
    end
end

MyTimer = Timer.New()
MyTimer.EventHandler = TimerClick
MyTimer:Start(.25)
