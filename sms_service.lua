local sms_service = {}

local LOG_TAG = "SMS_SERVICE"

-- 发送短信函数封装
function sms_service.send_sms(phone, sms)
    -- 发送短信
    if CONFIG.LOG.LEVEL == "DEBUG" then
        log.debug(LOG_TAG, "测试发送短信, 未真正发送", phone, "长度: " .. string.len(sms), sms)
    else
        log.info(LOG_TAG, "发送短信", phone, "长度: " .. string.len(sms), sms)
        sms.send(phone, sms)
    end
end

-- 信令setConfig的实现
local function op_set_config_impl(phone, sms_op_json)
    log.info(LOG_TAG, "信令操作码: ", CONFIG.SMS_OP_CODE_ENUM.SET_CONFIG, "解释: 设置配置")
    local config_changed_table = {}
    -- 转发使能
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE] then
        -- 校验字段类型
        if type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE]) ~= "boolean" then
            log.error(LOG_TAG,
                "参数FWD_ENABLE类型错误, 期望boolean, 实际" .. type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE]))
        else
            config_changed_table["FWD_ENABLE"] = sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE]
        end
    end
    -- 网络使能
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE] then
        -- 校验字段类型
        if type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE]) ~= "boolean" then
            log.error(LOG_TAG,
                "参数NET_ENABLE类型错误, 期望boolean, 实际" .. type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE]))
        else
            config_changed_table["NET_ENABLE"] = sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE]
        end
    end
    -- 添加黑名单
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST] then
        -- 校验字段类型
        if type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST]) ~= "table" then
            log.error(LOG_TAG,
                "参数ADD_BLACKLIST类型错误, 期望table, 实际" ..
                type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST]))
        else
            config_changed_table["BLACKLIST"] = UTIL.merge_and_deduplicate(CONFIG.SMSYNC.BLACKLIST,
                sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST])
        end
    end
    -- 移除黑名单
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.RM_BLACKLIST] then
        -- 校验字段类型
        if type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.RM_BLACKLIST]) ~= "table" then
            log.error(LOG_TAG,
                "参数RM_BLACKLIST类型错误, 期望table, 实际" ..
                type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.RM_BLACKLIST]))
        else
            if config_changed_table["BLACKLIST"] ~= nil then
                config_changed_table["BLACKLIST"] = UTIL.array_subtract(config_changed_table["BLACKLIST"],
                    sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.RM_BLACKLIST])
            else
                config_changed_table["BLACKLIST"] = UTIL.array_subtract(CONFIG.SMSYNC.BLACKLIST,
                    sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.RM_BLACKLIST])
            end
        end
    end
    -- 清空黑名单
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.CLEAR_BLACKLIST] then
        -- 校验字段类型
        if type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.CLEAR_BLACKLIST]) ~= "boolean" then
            log.error(LOG_TAG,
                "参数CLEAR_BLACKLIST类型错误, 期望boolean, 实际" ..
                type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.CLEAR_BLACKLIST]))
        elseif sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.CLEAR_BLACKLIST] then
            CONFIG.SMSYNC.BLACKLIST = {}
            config_changed_table["BLACKLIST"] = {}
        end
    end
    -- 发布配置更新事件
    if not UTIL.table_is_empty(config_changed_table) then
        sys.publish(CONFIG.EVENT_ENUM.CONFIG.CHANGED, config_changed_table)
    end
end

-- 信令getConfig的实现
local function op_get_config_impl(phone, sms_op_json)
    log.info(LOG_TAG, "信令操作码: ", CONFIG.SMS_OP_CODE_ENUM.GET_CONFIG, "解释: 获取配置")
    local response = {}
    if sms_op_json[CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM.CONFIG_LIST] == nil then
        -- 获取所有配置
        for key, value in pairs(CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM) do
            if value ~= CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM.CONFIG_LIST then
                response[value] = CONFIG.SMSYNC[key]
            end
            log.debug(LOG_TAG, "getConfig 响应字段", value, CONFIG.SMSYNC[key])
        end
    else
        -- 获取指定配置
        if type(sms_op_json[CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM.CONFIG_LIST]) ~= "table" then
            log.error(LOG_TAG,
                "参数CONFIG_LIST类型错误, 期望table, 实际" ..
                type(sms_op_json[CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM.CONFIG_LIST]))
            return
        end
        for _, value in ipairs(sms_op_json[CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM.CONFIG_LIST]) do
            if type(value) ~= "string" then
                log.error(LOG_TAG,
                    "参数CONFIG_LIST元素类型错误, 期望string, 实际" ..
                    type(value))
            else
                for config_index, config_value in pairs(CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM) do
                    if config_value == value and config_value ~= CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM.CONFIG_LIST then
                        response[config_value] = CONFIG.SMSYNC[config_index]
                        log.debug(LOG_TAG, "getConfig 响应字段", response[config_value], CONFIG.SMSYNC[config_index])
                    end
                end
            end
        end
    end

    local response_json_string = json.encode(response)
    if response_json_string == nil then
        log.error(LOG_TAG, "生成信令getConfig响应失败")
        return
    end
    log.debug(LOG_TAG, "信令getConfig响应", response_json_string)
    local encrypt_response_json_string = UTIL.encrypt_and_base64(response_json_string, CONFIG.CRYPTO.KEY)
    local sms_response = "#*#*" .. encrypt_response_json_string .. "*#*#"
    -- 发送响应
    if phone == CONFIG.FWD_CHANNEL_ENUM.WS then
        
    else
        sys.publish(CONFIG.EVENT_ENUM.FWD_SERVICE.FWD, CONFIG.FWD_DIRECTION_ENUM.DOWN, sms_response, phone, nil)
    end
end

-- 信令setChannel的实现
local function op_set_channel_impl(phone, sms_op_json)
    log.info(LOG_TAG, "信令操作码: ", CONFIG.SMS_OP_CODE_ENUM.SET_CHANNEL, "解释: 设置转发通道")
    -- 校验转发通道 自身电话号码 以及 转发通道配置是否存在
    if sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL] == nil or sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.PHONE_NUM] == nil then
        log.error(LOG_TAG, "参数FWD_CHANNEL或PHONE_NUM为空")
        return
    end
    if sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL] ~= CONFIG.FWD_CHANNEL_ENUM.WS and sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL] ~= CONFIG.FWD_CHANNEL_ENUM.SMS then
        log.error(LOG_TAG, "参数FWD_CHANNEL错误, 仅支持ws和sms")
        return
    end
    if sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL] == CONFIG.FWD_CHANNEL_ENUM.WS and sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.WS_CONFIG] == nil then
        log.error(LOG_TAG, "参数WS_CONFIG为空")
        return
    end
    if sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL] == CONFIG.FWD_CHANNEL_ENUM.SMS and (sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.SMS_FWD_LIST] == nil or #sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.SMS_FWD_LIST] == 0) then
        log.error(LOG_TAG, "参数SMS_FWD_LIST为空")
        return
    end

    local config_changed_table = {}
    -- 启用转发
    config_changed_table["FWD_ENABLE"] = true
    -- 自身电话号码
    if type(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.PHONE_NUM]) ~= "string" then
        log.error(LOG_TAG,
            "参数PHONE_NUM类型错误, 期望string, 实际" .. type(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.PHONE_NUM]))
        return
    elseif not UTIL.check_phone_number(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.PHONE_NUM]) then
        log.error(LOG_TAG, "参数PHONE_NUM格式错误")
        return
    end
    config_changed_table["PHONE_NUM"] = sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.PHONE_NUM]
    -- 转发通道
    config_changed_table["FWD_CHANNEL"] = sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL]
    -- WebSocket配置
    if sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL] == CONFIG.FWD_CHANNEL_ENUM.WS then
        if type(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.WS_CONFIG]) ~= "string" then
            log.error(LOG_TAG,
                "参数WS_CONFIG类型错误, 期望string, 实际" ..
                type(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.WS_CONFIG]))
            return
        elseif not UTIL.check_ws_config(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.WS_CONFIG]) then
            log.error(LOG_TAG, "参数WS_CONFIG格式错误")
            return
        end
        config_changed_table["WS_CONFIG"] = sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.WS_CONFIG]
        -- 启用网络
        config_changed_table["NET_ENABLE"] = true
    end
    -- 短信转发列表
    if sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL] == CONFIG.FWD_CHANNEL_ENUM.SMS then
        if type(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.SMS_FWD_LIST]) ~= "table" then
            log.error(LOG_TAG,
                "参数SMS_FWD_LIST类型错误, 期望table, 实际" .. type(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.SMS_FWD_LIST])
            )
            return
        end
        for index, value in ipairs(sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.SMS_FWD_LIST]) do
            if type(value) ~= "string" then
                log.error(LOG_TAG,
                    "参数SMS_FWD_LIST类型错误, 期望string, 实际" ..
                    type(value))
                return
            elseif not UTIL.check_phone_number(value) then
                log.error(LOG_TAG, "参数SMS_FWD_LIST格式错误", value)
                return
            end
        end
        config_changed_table["SMS_FWD_LIST"] = sms_op_json[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.SMS_FWD_LIST]
        -- 关闭网络
        config_changed_table["NET_ENABLE"] = false
    end

    -- 发布配置更新事件
    if not UTIL.table_is_empty(config_changed_table) then
        sys.publish(CONFIG.EVENT_ENUM.CONFIG.CHANGED, config_changed_table)
    end
end

-- 信令sendSms的实现
local function op_send_sms_impl(phone, sms_op_json)
    log.info(LOG_TAG, "信令操作码: ", CONFIG.SMS_OP_CODE_ENUM.SEND_SMS, "解释: 发送短信")
    -- 目标号码
    local des_num = sms_op_json[CONFIG.SMS_OP_SEND_SMS_PARAM_ENUM.DES_NUM]
    -- 短信内容
    local content = sms_op_json[CONFIG.SMS_OP_SEND_SMS_PARAM_ENUM.CONTENT]
    -- 校验字段类型
    if type(des_num) ~= "string" or type(content) ~= "string" then
        log.error(LOG_TAG,
            "参数DES_NUM或CONTENT类型错误, 期望string, 实际" ..
            type(des_num) .. " " .. type(content))
        return
    end
    -- 发送短信
    sys.publish(CONFIG.EVENT_ENUM.FWD_SERVICE.FWD, CONFIG.FWD_DIRECTION_ENUM.DOWN, content, des_num, phone)
end

-- 操作码分发表
local op_code_switch = {
    [CONFIG.SMS_OP_CODE_ENUM.SET_CONFIG] = op_set_config_impl,
    [CONFIG.SMS_OP_CODE_ENUM.GET_CONFIG] = op_get_config_impl,
    [CONFIG.SMS_OP_CODE_ENUM.SET_CHANNEL] = op_set_channel_impl,
    [CONFIG.SMS_OP_CODE_ENUM.SEND_SMS] = op_send_sms_impl,
}

-- 信令实现
function sms_service.sms_op_impl(phone, sms_op_json_string)
    log.info(LOG_TAG, "信令内容", phone, "长度: " .. string.len(sms_op_json_string), sms_op_json_string)
    -- 解析json字符串
    local sms_op_json, succ, err_msg = json.decode(sms_op_json_string)
    if succ ~= 1 then
        log.error(LOG_TAG, "解析信令失败", err_msg)
        return
    end

    -- 校验信令
    if not UTIL.check_sms_op(sms_op_json) then
        log.error(LOG_TAG, "信令校验失败")
        return
    end

    -- 判断操作码
    if sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP] == nil then
        log.error(LOG_TAG, "信令缺少操作码")
        return
    end

    local op_impl = op_code_switch[sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP]]
    if op_impl == nil then
        log.error(LOG_TAG, "不支持的信令操作码", sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP])
        return
    end
    op_impl(phone, sms_op_json)
end

-- 短信服务实现
local function sms_service_impl(phone, sms)
    -- 判断短信类型 是否为信令  信令以#*#*为开头，以*#*#为结尾, 中间为json字符串
    if string.sub(sms, 1, string.len(CONFIG.OP.OP_CODE_START)) == CONFIG.OP.OP_CODE_START and string.sub(sms, 0 - string.len(CONFIG.OP.OP_CODE_END)) == CONFIG.OP.OP_CODE_END then
        log.info(LOG_TAG, "收到信令", phone, "长度: " .. string.len(sms), sms)
        local crypto_sms_op_json_string = string.sub(sms, string.len(CONFIG.OP.OP_CODE_START) + 1,
            -1 - string.len(CONFIG.OP.OP_CODE_END))
        local sms_op_json_string = UTIL.decrypt_and_base64(crypto_sms_op_json_string, CONFIG.CRYPTO.KEY)
        if sms_op_json_string == nil then
            log.error(LOG_TAG, "解密信令失败")
            return
        end
        log.debug(LOG_TAG, "解密信令", "长度: " .. string.len(sms_op_json_string), sms_op_json_string)
        if CONFIG.OP.COMPRESS then
            sms_op_json_string = UTIL.decompress(sms_op_json_string)
            if sms_op_json_string == nil then
                log.error(LOG_TAG, "解压信令失败")
                return
            end
            log.debug(LOG_TAG, "解压信令", "长度: " .. string.len(sms_op_json_string), sms_op_json_string)
        end
        sms_service.sms_op_impl(phone, sms_op_json_string)
        return
    else
        log.info(LOG_TAG, "收到普通短信", phone, "长度: " .. string.len(sms), sms)
        sys.publish(CONFIG.EVENT_ENUM.FWD_SERVICE.FWD, CONFIG.FWD_DIRECTION_ENUM.UP, sms, nil, phone)
    end
end

local function test()
    -- -- 测试数据
    -- local LOG_TAG = "SMS_SERVICE_TEST"

    -- -- getConfig
    -- local test_data = {}
    -- test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP] = CONFIG.SMS_OP_CODE_ENUM.GET_CONFIG
    -- test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP] = os.time()
    -- test_data[CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM.CONFIG_LIST] = { "fE", "nE", "bL", "cL" }
    -- local test_data_json_string = json.encode(test_data)
    -- log.info(LOG_TAG, "测试数据", test_data_json_string)
    -- if CONFIG.OP.COMPRESS then
    --     test_data_json_string = UTIL.compress(test_data_json_string)
    --     log.info(LOG_TAG, "测试数据压缩后", test_data_json_string)
    -- end
    -- local test_data_crypto_string = UTIL.encrypt_and_base64(test_data_json_string)
    -- log.info(LOG_TAG, "测试数据密文", test_data_crypto_string)
    -- sms_service_impl("13800000000", CONFIG.OP.OP_CODE_START .. test_data_crypto_string .. CONFIG.OP.OP_CODE_END)

    -- -- setConfig
    -- test_data = {}
    -- test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP] = CONFIG.SMS_OP_CODE_ENUM.SET_CONFIG
    -- test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP] = os.time()
    -- test_data[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE] = true
    -- test_data[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE] = false
    -- test_data[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST] = { "138*", "*中国联通*" }
    -- test_data_json_string = json.encode(test_data)
    -- log.info(LOG_TAG, "测试数据", test_data_json_string)
    -- if CONFIG.OP.COMPRESS then
    --     test_data_json_string = UTIL.compress(test_data_json_string)
    --     log.info(LOG_TAG, "测试数据压缩后", test_data_json_string)
    -- end
    -- test_data_crypto_string = UTIL.encrypt_and_base64(test_data_json_string)
    -- log.info(LOG_TAG, "测试数据密文", test_data_crypto_string)
    -- sms_service_impl("13800000000", CONFIG.OP.OP_CODE_START .. test_data_crypto_string .. CONFIG.OP.OP_CODE_END)

    -- -- sendSms
    -- test_data = {}
    -- test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP] = CONFIG.SMS_OP_CODE_ENUM.SEND_SMS
    -- test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP] = os.time()
    -- test_data[CONFIG.SMS_OP_SEND_SMS_PARAM_ENUM.DES_NUM] = "13900000000"
    -- test_data[CONFIG.SMS_OP_SEND_SMS_PARAM_ENUM.CONTENT] = [[测试
    -- asd
    -- 短信测试数据测试数据测试数据测试数据]]
    -- test_data_json_string = json.encode(test_data)
    -- log.info(LOG_TAG, "测试数据", test_data_json_string)
    -- if CONFIG.OP.COMPRESS then
    --     test_data_json_string = UTIL.compress(test_data_json_string)
    --     log.info(LOG_TAG, "测试数据压缩后", test_data_json_string)
    -- end
    -- test_data_crypto_string = UTIL.encrypt_and_base64(test_data_json_string)
    -- log.info(LOG_TAG, "测试数据密文", test_data_crypto_string)
    -- sms_service_impl("13800000000", CONFIG.OP.OP_CODE_START .. test_data_crypto_string .. CONFIG.OP.OP_CODE_END)

    -- -- setChannel
    -- test_data = {}
    -- test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP] = CONFIG.SMS_OP_CODE_ENUM.SET_CHANNEL
    -- test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP] = os.time()
    -- test_data[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.FWD_CHANNEL] = CONFIG.FWD_CHANNEL_ENUM.WS
    -- test_data[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.WS_CONFIG] = "testAccessKey@ws://echo.airtun.air32.cn/ws/echo"
    -- test_data[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.PHONE_NUM] = "13800000000"
    -- -- test_data[CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM.SMS_FWD_LIST] = { "13800000000" }
    -- test_data_json_string = json.encode(test_data)
    -- log.info(LOG_TAG, "测试数据", test_data_json_string)
    -- if CONFIG.OP.COMPRESS then
    --     test_data_json_string = UTIL.compress(test_data_json_string)
    --     log.info(LOG_TAG, "测试数据压缩后", test_data_json_string)
    -- end
    -- test_data_crypto_string = UTIL.encrypt_and_base64(test_data_json_string)
    -- log.info(LOG_TAG, "测试数据密文", test_data_crypto_string)
    -- sms_service_impl("13800000000", CONFIG.OP.OP_CODE_START .. test_data_crypto_string .. CONFIG.OP.OP_CODE_END)

    -- 普通短信
    sys.timerStart(sms_service_impl, 4000, "13900000000", "测试短信")
    sys.timerStart(sms_service_impl, 1000, "13800000000", "测试短信")
    sys.timerStart(sms_service_impl, 7000, "13900000000", "测试短信中国联通")
end

function sms_service.init()
    -- 监听短信接收事件
    sys.subscribe("SMS_INC", function(phone, sms)
        log.info("LOG_TAG", "收到短信", phone, sms)
        sms_service_impl(phone, sms)
    end)
    log.info(LOG_TAG, "短信服务已启动")

    if CONFIG.LOG.LEVEL == "DEBUG" then
        sys.timerStart(test, 10000)
    end
end

return sms_service
