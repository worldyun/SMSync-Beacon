local util = {}

local LOG_TAG = "UTIL"

local function to_string_ex(value)
    if type(value) == 'table' then
        return util.table_to_str(value)
    elseif type(value) == 'string' then
        return "\'" .. value .. "\'"
    else
        return tostring(value)
    end
end

function util.table_to_str(t)
    if t == nil then return "" end
    local retstr = "{"

    local i = 1
    for key, value in pairs(t) do
        local signal = ","
        if i == 1 then
            signal = ""
        end

        if key == i then
            retstr = retstr .. signal .. to_string_ex(value)
        else
            if type(key) == 'number' or type(key) == 'string' then
                retstr = retstr .. signal .. '[' .. to_string_ex(key) .. "]=" .. to_string_ex(value)
            else
                if type(key) == 'userdata' then
                    retstr = retstr .. signal ..
                        "*s" .. util.table_to_str(getmetatable(key)) .. "*e" .. "=" .. to_string_ex(value)
                else
                    retstr = retstr .. signal .. key .. "=" .. to_string_ex(value)
                end
            end
        end

        i = i + 1
    end

    retstr = retstr .. "}"
    return retstr
end

function util.str_to_table(str)
    if str == nil or type(str) ~= "string" then
        return
    end

    local func, err = load("return " .. str)
    if not func then
        error("Invalid string for StrToTable: " .. err)
    end

    return func()
end

-- 校验信令合法性
-- sms_op_json: 信令
-- is_ws: 是否为websocket信令 默认为true
function util.check_sms_op_json_sign(sms_op_json, ...)
    if sms_op_json == nil then
        log.error(LOG_TAG, "短信信令为nil")
        return false
    end

    local is_ws = true
    if select("#", ...) > 0 then
        is_ws = select(1, ...)
    end

    if sms_op_json.sign == nil then
        log.error(LOG_TAG, "短信信令缺少sign参数")
        return false
    end

    -- 只有websocket信令需要校验timestamp
    if is_ws then
        -- 校验timestamp合法性, 允许上下误差5分钟
        local current_time = os.time()
        if sms_op_json.timestamp == nil then
            log.error(LOG_TAG, "短信信令缺少timestamp参数")
            return false
        end
        if math.abs(current_time - sms_op_json.timestamp) > CONFIG.OP.MAX_TIMESTAMP_DIFF then
            log.error(LOG_TAG, "短信信令timestamp不合法", "current_time: " .. tostring(current_time),
                "sms_op_json.timestamp: " .. tostring(sms_op_json.timestamp))
            return false
        end
    else
        -- 短信信令不需要校验timestamp
        -- 计算sign sha256(imei+设备密钥)，取前8位，大写字母
        local sign = crypto.sha256(mobile.imei() .. CONFIG.SMSYNC.SMSYNC_BEACO_KEY)
        sign = string.sub(sign, 1, 8)
        sign = string.upper(sign)
        if sms_op_json.sign ~= sign then
            log.error(LOG_TAG, "短信信令sign不合法", "calc sign: " .. sign, "sms_op_json.sign: " .. sms_op_json.sign)
            return false
        end
    end

    return true
end

-- 合并去重两个数组
-- arr1: 数组1
-- arr2: 数组2
function util.merge_and_deduplicate(arr1, arr2)
    local result = {}
    local seen = {}

    local function processArray(arr)
        for _, value in ipairs(arr) do
            if not seen[value] then
                table.insert(result, value)
                seen[value] = true
            end
        end
    end

    processArray(arr1)
    processArray(arr2)

    return result
end

-- 两个数组相减, 返回在arr1中但不在arr2中的元素
-- arr1: 数组1
-- arr2: 数组2
function util.array_subtract(arr1, arr2)
    local result = {}
    local toRemove = {}
    
    -- 构建要移除的元素集合
    for _, value in ipairs(arr2) do
        toRemove[value] = true
    end
    
    -- 遍历第一个数组，只保留不在第二个数组中的元素
    for _, value in ipairs(arr1) do
        if not toRemove[value] then
            table.insert(result, value)
        end
    end
    
    return result
end

return util
