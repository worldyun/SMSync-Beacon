local ws_service = {}

local LOG_TAG = "WS_SERVICE"

local ws_client = nil

local function ws_send(data)
    if ws_client == nil or not ws_client:ready() then
        log.error(LOG_TAG, "WS服务未初始化或未就绪!")
        return
    end
    if CONFIG.LOG.LEVEL == "DEBUG" then
        log.info(LOG_TAG, "测试模式ws发送数据", (json.encode({ action = "echo", msg = data })))
        ws_client:send((json.encode({ action = "echo", msg = data })))
    else
        ws_client:send(data)
    end
end


-- ws recv data处理函数
local function ws_recv_data_process(data)
    -- 解密
    if CONFIG.LOG.LEVEL == "DEBUG" then
        data = json.decode(data)["msg"]
    end
    data = UTIL.decrypt_and_base64(data, CONFIG.WS.CRYPTO_KEY)
    log.debug(LOG_TAG, "WS收到数据(解密后)", data)
    if data == nil then
        log.error(LOG_TAG, "WS数据解密失败")
        return
    end

    data = json.decode(data)
    if UTIL.table_is_empty(data) then
        log.error(LOG_TAG, "WS数据解析失败")
        return
    end
    if not UTIL.check_time_diff(data[CONFIG.WS_PARAM_ENUM.TIMESTAMP], CONFIG.WS.MAX_TIMESTAMP_DIFF) then
        log.error(LOG_TAG, "WS数据时间戳错误")
        return
    end

    local msg = data[CONFIG.WS_PARAM_ENUM.MSG]
    if not msg then
        log.error(LOG_TAG, "WS数据缺少msg字段")
        return
    end

    msg = UTIL.decrypt_and_base64(msg, CONFIG.CRYPTO.KEY)
    log.debug(LOG_TAG, "WS MSG 解密后", msg)
    if not msg then
        log.error(LOG_TAG, "WS MSG数据解密失败")
        return
    end

    SMS_SERVICE.sms_op_impl(CONFIG.FWD_CHANNEL_ENUM.WS, msg)
end


-- ws事件回调函数
local function ws_event_cb(wsc, event, data)
    log.debug(LOG_TAG, "WS事件", event)
    if event == "recv" then
        log.debug(LOG_TAG, "WS收到数据", data)
        ws_recv_data_process(data)
    end
end

local function get_ws_crypto_key()
    if CONFIG.WS.CRYPTO_KEY == nil then
        CONFIG.WS.CRYPTO_KEY = crypto.sha256(UTIL.get_ws_access_key(CONFIG.SMSYNC.WS_CONFIG)):sub(1,
            CONFIG.CRYPTO.KEY_LEN)
    end
    return CONFIG.WS.CRYPTO_KEY
end

function ws_service.send_msg(res, msg)
    if ws_client == nil or not ws_client:ready() then
        log.error(LOG_TAG, "WS服务未初始化或未就绪!")
        return
    end
    local send_msg = {}
    send_msg[CONFIG.WS_PARAM_ENUM.TIMESTAMP] = os.time()
    send_msg[CONFIG.WS_PARAM_ENUM.RES_ID] = crypto.sha256(res)
    send_msg[CONFIG.WS_PARAM_ENUM.MSG] = UTIL.encrypt_and_base64(msg, CONFIG.CRYPTO.KEY)
    local send_msg_str = json.encode(send_msg)
    log.debug(LOG_TAG, "WS发送消息: " .. send_msg_str)
    send_msg_str = UTIL.encrypt_and_base64(send_msg_str, CONFIG.WS.CRYPTO_KEY)
    ws_send(send_msg_str)
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
    if not CONFIG.SMSYNC.FWD_ENABLE or CONFIG.SMSYNC.FWD_CHANNEL ~= CONFIG.FWD_CHANNEL_ENUM.WS or not CONFIG.SMSYNC.NET_ENABLE then
        log.info(LOG_TAG, "WS服务无需初始化")
        return
    end

    -- 解析ws服务配置
    local accessKey = UTIL.get_ws_access_key(CONFIG.SMSYNC.WS_CONFIG)
    local ws_url = UTIL.get_ws_url(CONFIG.SMSYNC.WS_CONFIG)

    -- 校验accessKey与ws_url
    if not accessKey or not ws_url then
        log.error(LOG_TAG, "WS服务配置错误")
        return
    end

    -- 获取ws服务加密密钥
    get_ws_crypto_key()

    log.info(LOG_TAG, "WS服务初始化")
    ws_client = websocket.create(nil, ws_url)
    ws_client:autoreconn(CONFIG.WS.AUTO_RECONNECT_ENABLE, CONFIG.WS.AUTO_RECONNECT_TIME)
    ws_client:on(ws_event_cb)
    local ws_headers = {}
    ws_headers[CONFIG.WS.HEADERS_KEY.AUTHORIZATION] = crypto.sha256(accessKey)
    ws_headers[CONFIG.WS.HEADERS_KEY.SMSYNC_BEACO_ID] = crypto.sha256(mobile.imei())
    ws_client:headers(ws_headers)
    ws_client:connect()
end

function ws_service.init()
    sys.subscribe(CONFIG.EVENT_ENUM.WS_SERVICE.CONFIG_CHANGED, ws_service_init)
    sys.subscribe("IP_READY", function(ip, adapter)
        ws_service_init()
    end)
    sys.subscribe("IP_LOSE", function(adapter)
        log.info(LOG_TAG, "IP_LOSE, 关闭WS客户端")
        if ws_client ~= nil then
            ws_client:close()
            ws_client = nil
        end
    end)
    ws_service_init()
end

return ws_service
