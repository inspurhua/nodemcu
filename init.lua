pin = 1
gpio.mode(pin, gpio.OUTPUT)

--wifi
wifi.setmode(wifi.STATION)
wifi.startsmart(
  0,
  function(ssid, password)
    print(string.format("Success:%s,%s", ssid, password))
    wifi.sta.connect()
    local mytimer = tmr.create()
    mytimer:register(
      5000,
      tmr.ALARM_SINGLE,
      function(t)
        local ip = wifi.sta.getip() 
        if ip== nil then
          print(string.format("Fail:%s,%s", ssid, password))
        else
          print(string.format("Connected,IP is %s",ip))
        end
        t:unregister()
      end
    )
    mytimer:start()
  end
)
--mqtt
m =
  mqtt.Client(
  "5e82c09b53efb708b42bdcbc_node3_0_0_2020033114",
  120,
  "5e82c09b53efb708b42bdcbc_node3",
  "cc06eb9cbd4383f64c921e5b449981165f1e62a5c019ba94e117eae205c3b3dd"
)
m:on(
  "connect",
  function(client)
    print("connected")
  end
)
m:on(
  "offline",
  function(client)
    print("offline")
  end
)

m:on(
  "message",
  function(client, topic, data)
    --$oc/devices/5e82c09b53efb708b42bdcbc_node3/sys/commands/request_id=fabca79e-4f26-4e83-bcca-2c59da824a45:
    --{"paras":{"type":"ON"},"service_id":"light","command_name":"ON_OFF"}

    print(topic .. ":")
    if data ~= nil then
      print(data)
      local request_id = string.gsub(topic, "$oc/devices/5e82c09b53efb708b42bdcbc_node3/sys/commands/request_id=", "")
      local cmd = sjson.decode(data)
      if cmd.service_id == "light" and cmd.command_name == "ON_OFF" then
        local type = cmd.paras.type
        if type == "ON" then
          gpio.write(pin, gpio.HIGH)
        else
          gpio.write(pin, gpio.LOW)
        end
        --push
        local result =
          [[
{        
"result_code": 0,
"response_name": "COMMAND_RESPONSE",
"paras": {
"result": "success"
}
}
        ]]
        client:publish(
          "$oc/devices/5e82c09b53efb708b42bdcbc_node3/sys/commands/response/request_id=" .. request_id,
          result,
          0,
          0,
          function(client)
            print("sent")
          end
        )
      end
    end
  end
)
m:connect(
  "iot-mqtts.cn-north-4.myhuaweicloud.com",
  1883,
  false,
  function(client)
    print("connected")
    client:subscribe(
      "$oc/devices/5e82c09b53efb708b42bdcbc_node3/sys/commands/#",
      0,
      function(client)
        print("subscribe success")
      end
    )
    local T1 = tmr.create()
    T1:register(
      60000,
      tmr.ALARM_AUTO,
      function(t)
        local data = {}
        data["services"] = {}
        data["services"][1] = {["service_id"] = "wendu", ["properties"] = {}}
        data["services"][1]["properties"] = {["sheshidu"] = math.random(1, 100), ["huashidu"] = math.random(1, 100)}
        data["services"][2] = {["service_id"] = "shidu", ["properties"] = {}}
        data["services"][2]["properties"] = {["value"] = math.random(1, 100)}

        local updata = sjson.encode(data)
        print(updata)
        client:publish(
          "$oc/devices/5e82c09b53efb708b42bdcbc_node3/sys/properties/report",
          updata,
          0,
          0,
          function(client)
            print("sent")
          end
        )
      end
    )
    T1:start()
  end,
  function(client, reason)
    print("failed reason: " .. reason)
  end
)
