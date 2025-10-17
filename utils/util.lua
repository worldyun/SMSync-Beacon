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

-- 校验时间戳
function util.check_time_diff(timestamp, max_timestamp_diff)
    if timestamp == nil then
        return false
    end
    local current_time = os.time()
    if math.abs(current_time - timestamp) > max_timestamp_diff then
        return false
    end
    return true
end

-- 校验信令合法性
-- sms_op_json: 信令
function util.check_sms_op(sms_op_json)
    if sms_op_json == nil then
        log.error(LOG_TAG, "信令为nil")
        return false
    end

    if sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP] == nil then
        log.error(LOG_TAG, "短信信令缺少timestamp参数")
        return false
    end
    if not util.check_time_diff(sms_op_json[CONFIG.SMS_OP_COMMON_PARAM_ENUM.TIMESTAMP], CONFIG.OP.MAX_TIMESTAMP_DIFF) then
        log.error(LOG_TAG, "短信信令timestamp不合法", "当前时间: " .. tostring(os.time()),
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

function util.str_to_hex(s)
    local bytes = {}
    for i = 1, s:len() do
        bytes[#bytes + 1] = ('%2x'):format(s:byte(i, i))
    end
    return table.concat(bytes, '')
end

-- 16进制字符串转为字bytes字符串
function util.hex_to_bytes(hex_string)
    -- 使用table.insert比直接索引赋值稍快
    local bytes = {}

    -- 使用局部变量缓存全局函数以提高性能
    local char = string.char
    local sub = string.sub
    local tonumber = tonumber

    for i = 1, #hex_string, 2 do
        bytes[#bytes + 1] = char(tonumber(sub(hex_string, i, i + 1), 16))
    end
    return table.concat(bytes)
end

function util.sha256(data)
    return util.hex_to_bytes(crypto.sha256(data))
end

function util.hmac_sha256(data, key)
    return util.hex_to_bytes(crypto.hmac_sha256(data, key))
end

-- PBKDF2实现函数
-- password: 原始密码
-- salt: 盐值
-- iterations: 迭代次数
-- key_length: 期望的密钥长度
function util.pbkdf2(salt, password, iterations, key_length)

    local string_pack = string.pack
    local string_char = string.char
    local string_byte = string.byte

    local function F(password, salt, iterations, block_index)
        local U = util.hmac_sha256(salt .. string_pack(">I4", block_index), password)
        local result = {}

        -- 将初始U转换为字节表以避免重复的string.byte操作
        local u_bytes = {}
        for j = 1, #U do
            u_bytes[j] = string_byte(U, j)
        end

        -- 初始化结果表
        for j = 1, #U do
            result[j] = u_bytes[j]
        end

        for i = 2, iterations do
            U = util.hmac_sha256(U, password)

            -- 直接在字节表上进行XOR操作，避免重复的string.byte和string.char调用
            for j = 1, #U do
                result[j] = result[j] ~ string_byte(U, j)
            end
        end

        -- 一次性构建结果字符串
        local result_chars = {}
        for j = 1, #result do
            result_chars[j] = string_char(result[j])
        end

        return table.concat(result_chars)
    end

    -- 计算需要的块数
    local hash_length = #util.sha256("")
    local blocks_needed = math.ceil(key_length / hash_length)

    -- 使用table来存储各块的结果，避免字符串拼接开销
    local derived_key_parts = {}
    for i = 1, blocks_needed do
        derived_key_parts[#derived_key_parts + 1] = F(password, salt, iterations, i)
    end

    -- 一次性连接所有块
    local derived_key = table.concat(derived_key_parts)

    -- 截取所需长度
    return derived_key:sub(1, key_length)
end

-- 加密函数
function util.encrypt_and_base64(data, key, is_base64)
    -- 生成随机初始向量(IV)
    -- IV长度必须等于密钥长度
    local iv = crypto.trng(CONFIG.CRYPTO.KEY_LEN)
    local crypto_data = crypto.cipher_encrypt(CONFIG.CRYPTO.ALGORITHM, CONFIG.CRYPTO.PADDING, data, key, iv)
    if is_base64 then
        return crypto.base64_encode(iv .. crypto_data)
    else
        return iv .. crypto_data
    end
end

-- 解密函数
function util.decrypt_and_base64(data, key, is_base64)
    if is_base64 then
        data = crypto.base64_decode(data)
    end
    local iv = data:sub(1, CONFIG.CRYPTO.KEY_LEN)
    data = data:sub(CONFIG.CRYPTO.KEY_LEN + 1)
    return crypto.cipher_decrypt(CONFIG.CRYPTO.ALGORITHM, CONFIG.CRYPTO.PADDING, data, key, iv)
end

-- 获取操作密钥
function util.get_op_encrypt_key()
    if CONFIG.CRYPTO.KEY == nil then
        log.debug(LOG_TAG, "生成op加密密钥，参数", mobile.imei(), CONFIG.SMSYNC.SMSYNC_BEACON_KEY)
        CONFIG.CRYPTO.KEY = util.pbkdf2(mobile.imei(), CONFIG.SMSYNC.SMSYNC_BEACON_KEY, CONFIG.CRYPTO.PBKDF2_ITER,
            CONFIG.CRYPTO.KEY_LEN)
    end
    return CONFIG.CRYPTO.KEY
end

-- 获取ws密钥
function util.get_ws_encrypt_key(salt, access_key)
    CONFIG.WS.CRYPTO_KEY = util.pbkdf2(salt, access_key, CONFIG.CRYPTO.PBKDF2_ITER, CONFIG.CRYPTO.KEY_LEN)
    return CONFIG.WS.CRYPTO_KEY
end

-- 压缩函数
-- data: 待压缩的数据 string类型
function util.compress(data)
    -- 根据压缩字典进行压缩 一次替换
    local compressed_data = data
    for index, value in pairs(CONFIG.COMPRESS_DICT) do
        compressed_data = string.gsub(compressed_data, value, string.char(index))
    end
    return compressed_data
end

-- 解压函数
-- data: 待解压的数据 string类型
function util.decompress(data)
    -- 根据压缩字典进行解压 一次替换
    local decompressed_data = data
    for index, value in pairs(CONFIG.COMPRESS_DICT) do
        decompressed_data = string.gsub(decompressed_data, string.char(index), value)
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
