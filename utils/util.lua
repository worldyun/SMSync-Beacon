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
function util.check_sms_op(sms_op_json)
    if sms_op_json == nil then
        log.error(LOG_TAG, "信令为nil")
        return false
    end

    local current_time = os.time()
    if sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP] == nil then
        log.error(LOG_TAG, "短信信令缺少timestamp参数")
        return false
    end
    if math.abs(current_time - sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP]) > CONFIG.OP.MAX_TIMESTAMP_DIFF then
        log.error(LOG_TAG, "短信信令timestamp不合法", "当前时间: " .. tostring(current_time),
            "信令时间: " .. tostring(sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP]))
        return false
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

-- 数组去重
function util.deduplicate_array(arr)
    local result = {}
    local seen = {}

    for _, value in ipairs(arr) do
        if not seen[value] then
            table.insert(result, value)
            seen[value] = true
        end
    end

    return result
end

-- 加密函数
function util.encrypt_and_base64(data)
    local key = CONFIG.CRYPTO.KEY
    if key == nil then
        key = crypto.sha256(mobile.imei() .. CONFIG.SMSYNC.SMSYNC_BEACO_KEY):sub(1, CONFIG.CRYPTO.KEY_LEN)
        CONFIG.CRYPTO.KEY = key
    end
    -- 生成随机初始向量(IV)
    -- IV长度必须等于密钥长度
    local iv = crypto.base64_encode(crypto.trng(CONFIG.CRYPTO.KEY_LEN)):sub(1, CONFIG.CRYPTO.KEY_LEN)
    local crypto_data = crypto.cipher_encrypt(CONFIG.CRYPTO.ALGORITHM, CONFIG.CRYPTO.PADDING, data, key, iv)
    return iv .. crypto.base64_encode(crypto_data)
end

-- 解密函数
function util.decrypt_and_base64(data)
    local key = CONFIG.CRYPTO.KEY
    if key == nil then
        key = crypto.sha256(mobile.imei() .. CONFIG.SMSYNC.SMSYNC_BEACO_KEY):sub(1, CONFIG.CRYPTO.KEY_LEN)
        CONFIG.CRYPTO.KEY = key
    end
    local iv = data:sub(1, CONFIG.CRYPTO.KEY_LEN)
    local crypto_data = crypto.base64_decode(data:sub(CONFIG.CRYPTO.KEY_LEN + 1))
    return crypto.cipher_decrypt(CONFIG.CRYPTO.ALGORITHM, CONFIG.CRYPTO.PADDING, crypto_data, key, iv)
end

-- 压缩函数
-- data: 待压缩的数据 string类型
function util.compress(data)
    -- 根据压缩字典进行压缩 一次替换
    local compressed_data = data
    for index, value in pairs(CONFIG.COMPRESS_DICT) do
        compressed_data = string.gsub(compressed_data,value,string.char(index))
    end
    return compressed_data
end

-- 解压函数
-- data: 待解压的数据 string类型
function util.decompress(data)
    -- 根据压缩字典进行解压 一次替换
    local decompressed_data = data
    for index, value in pairs(CONFIG.COMPRESS_DICT) do
        decompressed_data = string.gsub(decompressed_data,string.char(index),value)
    end
    return decompressed_data
end

-- 校验号码合法性
function util.check_phone_number(phone_number)
    if phone_number == nil or type(phone_number) ~= "string" then
        return false
    end

    local pattern = "^[0-9]+$"
    local is_valid = string.match(phone_number, pattern)
    if is_valid == nil then
        return false
    end
    return true
end

-- 校验ws_config合法性
function util.check_ws_config(ws_config)
    return string.match(ws_config, "^[^@]+@ws://[^@]+$") ~= nil
end

-- 获取table长度
function util.table_length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- 判断table是否为空
function util.table_is_empty(t)
    if t == nil then
        return true
    end
    return util.table_length(t) == 0
end

-- 获取ws_config中的ws地址 返回格式ws://test.com/websocket
function util.get_ws_url(ws_config)
    return string.match(ws_config, "@(.+)$")
end

-- 获取ws_config中的accessKey
function util.get_ws_access_key(ws_config)
    return string.match(ws_config, "^(.+)@")
end

return util
