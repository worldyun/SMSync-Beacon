local fwd_service = {}

local LOG_TAG = "FWD_SERVICE"

-- 上行转发校验是否命中黑名单
local function is_in_blacklist(phone, content)
    -- 黑名单为空则不进行校验
    if UTIL.table_is_empty(CONFIG.SMSYNC.BLACKLIST) then
        return false
    end

    -- 遍历黑名单
    for _, rule in ipairs(CONFIG.SMSYNC.BLACKLIST) do
        if rule == "*" then
            log.info(LOG_TAG, "短信来源命中黑名单, 忽略转发", "通配符匹配", rule, phone)
            return true
        end
        if string.sub(rule, 1, 1) == "*" and string.sub(rule, -1) == "*" then
            -- 如果rule为*开头结尾的字符串，则进行短信内容模糊匹配
            local pattern = string.sub(rule, 2, -2)
            if string.find(content, pattern) then
                log.info(LOG_TAG, "短信内容命中黑名单, 忽略转发", "内容模糊匹配", rule, content)
                return true
            end
        elseif string.sub(rule, -1) == "*" then
            -- 如果rule为*结尾的，则进行来源号码前缀匹配
            local pattern = string.sub(rule, 1, -2)
            if string.find(phone, pattern) then
                log.info(LOG_TAG, "短信来源命中黑名单, 忽略转发", "来源前缀匹配", rule, phone)
                return true
            end
        else
            -- 否则进行完全匹配
            if phone == rule then
                log.info(LOG_TAG, "短信来源命中黑名单, 忽略转发", "完全匹配", rule, phone)
                return true
            end
        end
    end
    return false
end


-- 转发服务实现
-- direction: 转发方向
-- content: 转发内容
-- des_num: 目标号码, 下行转发时有效
-- res_num: 源号码, 上行转发时有效
local function fwd_service_impl(direction, content, des_num, res_num)
    -- 检查转发是否启用
    if not CONFIG.SMSYNC.FWD_ENABLE then
        log.warn(LOG_TAG, "转发服务未启用, 忽略转发")
        return
    end

    if direction == CONFIG.FWD_DIRECTION_ENUM.UP then
        -- 上行转发 接收第三方短信转发至控制端
        log.info(LOG_TAG, "转发服务事件", "转发方向：上行", "内容：" .. content, "源号码：" ..res_num)
        -- 检查是否命中黑名单
        if is_in_blacklist(res_num, content) then
            return
        end
        if CONFIG.SMSYNC.FWD_CHANNEL == CONFIG.FWD_CHANNEL_ENUM.SMS then
            -- 通过短信转发
            for _, fwd_num in ipairs(CONFIG.SMSYNC.SMS_FWD_LIST) do
                SMS_SERVICE.send_sms(fwd_num, content)
            end
        elseif CONFIG.SMSYNC.FWD_CHANNEL == CONFIG.FWD_CHANNEL_ENUM.WS then
            -- 通过WebSocket转发
            log.warn(LOG_TAG, "WebSocket转发功能未实现, 忽略转发")
        else
            log.error(LOG_TAG, "未知的转发通道", tostring(CONFIG.SMSYNC.FWD_CHANNEL))
        end
    end
    if direction == CONFIG.FWD_DIRECTION_ENUM.DOWN then
        -- 下行转发 控制端转发至第三方短信
        log.info(LOG_TAG, "转发服务事件", "转发方向：下行", "内容：" .. content, "目标号码：" ..des_num)
        SMS_SERVICE.send_sms(des_num, content)
    end
end

-- 初始化
function fwd_service.init()
    sys.subscribe(CONFIG.EVENT_ENUM.FWD_SERVICE.FWD, fwd_service_impl)
    log.info(LOG_TAG, "转发服务已启动")
end

return fwd_service
