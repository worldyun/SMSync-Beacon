local ws_service = {}

local LOG_TAG = "WS_SERVICE"

local ws_client = nil

-- ws事件回调函数
local function ws_event_cb(wsc, event, data)

end


local function ws_service_init()
    if not websocket then
        log.error(LOG_TAG, "WS服务依赖websocket模块, 但未能加载!")
        return
    end
    if ws_client ~= nil then
        ws_client:close()
        ws_client = nil
    end

    -- 判断是否需要初始化
    if not CONFIG.SMSYNC.FWD_ENABLE or CONFIG.SMSYNC.FWD_CHANNEL ~= CONFIG.FWD_CHANNEL_ENUM.WS or CONFIG.SMSYNC.NET_ENABLE then
        log.info(LOG_TAG, "WS服务无需初始化")
    end

    -- 解析ws服务配置
    local accessKey = UTIL.get_ws_access_key(CONFIG.SMSYNC.WS_CONFIG)
    local ws_url = UTIL.get_ws_url(CONFIG.SMSYNC.WS_CONFIG)

    -- 校验accessKey与ws_url
    if not accessKey or not ws_url then
        log.error(LOG_TAG, "WS服务配置错误")
        return
    end

    log.info(LOG_TAG, "WS服务初始化")
    ws_client = websocket.create(nil, ws_url)
    ws_client:autoreconn(CONFIG.WS.AUTO_RECONNECT_ENABLE, CONFIG.WS.AUTO_RECONNECT_TIME)
    ws_client:on(ws_event_cb)
end

function ws_service.init()
    sys.subscribe(CONFIG.EVENT_ENUM.WS_SERVICE.CONFIG_CHANGED, ws_service_init)
    sys.subscribe("IP_READY", function(ip, adapter)
        ws_service_init()
    end)
    sys.subscribe("IP_LOSE", function(adapter)
        ws_service_init()
    end)
    ws_service_init()
end

return ws_service
