local sms_service = {}

local LOG_TAG = "SMS_SERVICE"

-- 短信信令setConfig的实现
local function op_set_config_impl(sms_op_json)
    log.info(LOG_TAG, "收到短信信令setConfig")
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE] then
        CONFIG.SMSYNC.FWD_ENABLE = sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.FWD_ENABLE]
    end
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE] then
        CONFIG.SMSYNC.NET_ENABLE = sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.NET_ENABLE]
    end
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST] then
        CONFIG.SMSYNC.BLACK_LIST = UTIL.merge_and_deduplicate(CONFIG.SMSYNC.BLACK_LIST,
            sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.ADD_BLACKLIST])
    end
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.RM_BLACKLIST] then
        CONFIG.SMSYNC.BLACK_LIST = UTIL.array_subtract(CONFIG.SMSYNC.BLACK_LIST,
            sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.RM_BLACKLIST])
    end
    if sms_op_json[CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM.CLEAR_BLACKLIST] then
        CONFIG.SMSYNC.BLACK_LIST = {}
    end
end

-- 短信信令getConfig的实现
local function op_get_config_impl(sms_op_json)

end

-- 短信信令setChannel的实现
local function op_set_channel_impl(sms_op_json)

end

-- 短信信令sendSms的实现
local function op_send_sms_impl(sms_op_json)

end

-- 操作码分发表
local op_code_switch = {
    [CONFIG.SMS_OP_CODE_ENUM.SET_CONFIG] = op_set_config_impl,
    [CONFIG.SMS_OP_CODE_ENUM.GET_CONFIG] = op_get_config_impl,
    [CONFIG.SMS_OP_CODE_ENUM.SET_CHANNEL] = op_set_channel_impl,
    [CONFIG.SMS_OP_CODE_ENUM.SEND_SMS] = op_send_sms_impl,
}

-- 短信信令实现
local function sms_op_impl(sms_op_json_string)
    -- 解析json字符串
    local sms_op_json, succ, err_msg = json.decode(sms_op_json_string)
    if succ ~= 1 then
        log.error(LOG_TAG, "解析短信信令失败", err_msg)
        return
    end

    -- 校验信令sing合法性
    if not UTIL.check_sms_op_sign(sms_op_json, false) then
        log.error(LOG_TAG, "短信信令签名校验失败")
        return
    end

    -- 判断操作码
    if sms_op_json.op_code == nil then
        log.error(LOG_TAG, "短信信令缺少操作码")
        return
    end

    local op_impl = op_code_switch[sms_op_json.op_code]
    if op_impl == nil then
        log.error(LOG_TAG, "不支持的短信信令操作码", sms_op_json.op_code)
        return
    end
    op_impl(sms_op_json)
end

-- 短信服务实现
local function sms_service_impl(phone, sms)
    -- 判断短信类型 是否为信令  信令以#*#*为开头，以*#*#为结尾, 中间为json字符串
    if string.sub(sms, 1, 3) == "#*#*" and string.sub(sms, -3) == "*#*#" then
        local sms_op_json_string = string.sub(sms, 4, -4)
        log.info(LOG_TAG, "收到短信信令", phone, sms_op_json_string)
        sms_op_impl(sms_op_json_string)
        return
    end
end

function sms_service.init()
    -- 监听短信接收事件
    sys.subscribe("SMS_INC", function(phone, sms)
        log.info("LOG_TAG", "收到短信", phone, sms)
        sms_service_impl(phone, sms)
    end)
end

return sms_service
