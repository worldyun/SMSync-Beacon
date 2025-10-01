local sms_service = {}

local LOG_TAG = "SMS_SERVICE"

local function send_sms(phone, sms)
    -- 发送短信
    if CONFIG.LOG.LEVEL == "DEBUG" then
        log.debug(LOG_TAG, "测试发送短信, 未真正发送", phone, "长度: " .. string.len(sms), sms)
    else
        log.info(LOG_TAG, "发送短信", phone, "长度: " .. string.len(sms), sms)
        sms.send(phone, sms)
    end
end

-- 短信信令setConfig的实现
local function op_set_config_impl(phone, sms_op_json)
    log.info(LOG_TAG, "信令操作码: ", CONFIG.SMS_OP_CODE_ENUM.SET_CONFIG, "解释: 设置配置")
    local config_key_list = {}
    -- 转发使能
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE] then
        -- 校验字段类型
        if type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE]) ~= "boolean" then
            log.error(LOG_TAG,
                "参数FWD_ENABLE类型错误, 期望boolean, 实际" .. type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE]))
        else
            CONFIG.SMSYNC.FWD_ENABLE = sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE]
            config_key_list[#config_key_list + 1] = "FWD_ENABLE"
        end
    end
    -- 网络使能
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE] then
        -- 校验字段类型
        if type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE]) ~= "boolean" then
            log.error(LOG_TAG,
                "参数NET_ENABLE类型错误, 期望boolean, 实际" .. type(sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE]))
        else
            CONFIG.SMSYNC.NET_ENABLE = sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE]
            config_key_list[#config_key_list + 1] = "NET_ENABLE"
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
            CONFIG.SMSYNC.BLACKLIST = UTIL.merge_and_deduplicate(CONFIG.SMSYNC.BLACKLIST,
                sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST])
            config_key_list[#config_key_list + 1] = "BLACKLIST"
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
            CONFIG.SMSYNC.BLACKLIST = UTIL.array_subtract(CONFIG.SMSYNC.BLACKLIST,
                sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.RM_BLACKLIST])
            config_key_list[#config_key_list + 1] = "BLACKLIST"
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
            config_key_list[#config_key_list + 1] = "BLACKLIST"
        end
    end
    -- 判断是否需要更新配置
    if #config_key_list > 0 then
        -- 发布配置更新事件
        sys.publish(CONFIG.EVENT_ENUM.CONFIG.CHANGED, config_key_list)
    end
end

-- 短信信令getConfig的实现
local function op_get_config_impl(phone, sms_op_json)
    log.info(LOG_TAG, "信令操作码: ", CONFIG.SMS_OP_CODE_ENUM.GET_CONFIG, "解释: 获取配置")
    local response = {}
    for key, value in pairs(CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM) do
        response[value] = CONFIG.SMSYNC[key]
        log.debug(LOG_TAG, "getConfig 相应字段", value, CONFIG.SMSYNC[key])
    end
    local response_json_string = json.encode(response)
    if response_json_string == nil then
        log.error(LOG_TAG, "生成短信信令getConfig响应失败")
        return
    end
    log.debug(LOG_TAG, "短信信令getConfig响应", response_json_string)
    local encrypt_response_json_string = UTIL.encrypt_and_base64(response_json_string)
    local sms_response = "#*#*" .. encrypt_response_json_string .. "*#*#"
    -- 发送短信响应
    send_sms(phone, sms_response)
end

-- 短信信令setChannel的实现
local function op_set_channel_impl(phone, sms_op_json)

end

-- 短信信令sendSms的实现
local function op_send_sms_impl(phone, sms_op_json)

end

-- 操作码分发表
local op_code_switch = {
    [CONFIG.SMS_OP_CODE_ENUM.SET_CONFIG] = op_set_config_impl,
    [CONFIG.SMS_OP_CODE_ENUM.GET_CONFIG] = op_get_config_impl,
    [CONFIG.SMS_OP_CODE_ENUM.SET_CHANNEL] = op_set_channel_impl,
    [CONFIG.SMS_OP_CODE_ENUM.SEND_SMS] = op_send_sms_impl,
}

-- 短信信令实现
local function sms_op_impl(phone, sms_op_json_string)
    log.info(LOG_TAG, "信令内容", phone, "长度: " .. string.len(sms_op_json_string), sms_op_json_string)
    -- 解析json字符串
    local sms_op_json, succ, err_msg = json.decode(sms_op_json_string)
    if succ ~= 1 then
        log.error(LOG_TAG, "解析短信信令失败", err_msg)
        return
    end

    -- 校验信令
    if not UTIL.check_sms_op(sms_op_json) then
        log.error(LOG_TAG, "短信信令校验失败")
        return
    end

    -- 判断操作码
    if sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP] == nil then
        log.error(LOG_TAG, "短信信令缺少操作码")
        return
    end

    local op_impl = op_code_switch[sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP]]
    if op_impl == nil then
        log.error(LOG_TAG, "不支持的短信信令操作码", sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP])
        return
    end
    op_impl(phone, sms_op_json)
end

-- 短信服务实现
local function sms_service_impl(phone, sms)
    -- 判断短信类型 是否为信令  信令以#*#*为开头，以*#*#为结尾, 中间为json字符串
    if string.sub(sms, 1, string.len(CONFIG.OP.OP_CODE_START)) == CONFIG.OP.OP_CODE_START and string.sub(sms, 0 - string.len(CONFIG.OP.OP_CODE_END)) == CONFIG.OP.OP_CODE_END then
        log.info(LOG_TAG, "收到短信信令", phone, "长度: " .. string.len(sms), sms)
        local crypto_sms_op_json_string = string.sub(sms, string.len(CONFIG.OP.OP_CODE_START) + 1,
            -1 - string.len(CONFIG.OP.OP_CODE_END))
        sms_op_impl(phone, UTIL.decrypt_and_base64(crypto_sms_op_json_string))
        return
    else
        log.info(LOG_TAG, "收到普通短信", phone, "长度: " .. string.len(sms), sms)
    end
end

local function test()
    -- 测试数据
    local test_data = {}
    test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP] = CONFIG.SMS_OP_CODE_ENUM.GET_CONFIG
    test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP] = os.time()
    local test_data_json_string = json.encode(test_data)
    log.info(LOG_TAG, "测试数据", test_data_json_string)
    local test_data_crypto_string = UTIL.encrypt_and_base64(test_data_json_string)
    log.info(LOG_TAG, "测试数据密文", test_data_crypto_string)
    sms_service_impl("13800000000", CONFIG.OP.OP_CODE_START .. test_data_crypto_string .. CONFIG.OP.OP_CODE_END)

    test_data = {}
    test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.OP] = CONFIG.SMS_OP_CODE_ENUM.SET_CONFIG
    test_data[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP] = os.time()
    test_data[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE] = true
    test_data[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE] = false
    test_data[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST] = {"138*"}
    test_data_json_string = json.encode(test_data)
    log.info(LOG_TAG, "测试数据", test_data_json_string)
    test_data_crypto_string = UTIL.encrypt_and_base64(test_data_json_string)
    log.info(LOG_TAG, "测试数据密文", test_data_crypto_string)
    sms_service_impl("13800000000", CONFIG.OP.OP_CODE_START .. test_data_crypto_string .. CONFIG.OP.OP_CODE_END)
end

function sms_service.init()
    -- 监听短信接收事件
    sys.subscribe("SMS_INC", function(phone, sms)
        log.info("LOG_TAG", "收到短信", phone, sms)
        sms_service_impl(phone, sms)
    end)

    test()
end

return sms_service
