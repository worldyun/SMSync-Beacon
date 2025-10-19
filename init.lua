local init = {}

local LOG_TAG = "INIT"

local function init_log()
    -- 加载日志功能模块并设置日志输出等级与风格
    log.setLevel(CONFIG.LOG.LEVEL)
    log.style(CONFIG.LOG.STYLE)
end

local function init_fskv()
    -- 初始化kv数据库 fskv 失败则重启
    log.info(LOG_TAG, "init fskv 初始化kv数据库统")
    if fskv.init() then
        log.info(LOG_TAG, "kv数据库初始化成功")
    else
        log.info(LOG_TAG, "kv数据库初始化失败, 重启中...")
        sys.restart()
    end
end

local function load_smsync_beacon_key()
    -- 判断SMSYNC_BEACON_KEY是否存在或CONFIG中默认值是否为nil, 不存在则生成一个新的
    if CONFIG.SMSYNC.DEFAULT.SMSYNC_BEACON_KEY == nil then
        log.info(LOG_TAG, "配置文件中未设置设备密钥, 尝试加载KVFS中存储的设备密钥")
        local beacon_key = fskv.get("CONFIG.SMSYNC.SMSYNC_BEACON_KEY")
        if beacon_key then
            CONFIG.SMSYNC.SMSYNC_BEACON_KEY = beacon_key
            log.info(LOG_TAG, "加载KVFS中存储的设备密钥", CONFIG.SMSYNC.SMSYNC_BEACON_KEY)
        else
            log.info(LOG_TAG, "KVFS中未存储设备密钥, 正在生成新的设备密钥")
            local random_string = crypto.trng(16);
            log.debug(LOG_TAG, "随机字符串", random_string)
            beacon_key = crypto.base64_encode(random_string):sub(1, 12)
            fskv.set("CONFIG.SMSYNC.SMSYNC_BEACON_KEY", beacon_key)
            CONFIG.SMSYNC.SMSYNC_BEACON_KEY = beacon_key
            log.info(LOG_TAG, "生成新的设备密钥", CONFIG.SMSYNC.SMSYNC_BEACON_KEY)
        end
    else
        -- 校验设备密钥长度与合法性
        if string.len(CONFIG.SMSYNC.DEFAULT.SMSYNC_BEACON_KEY) ~= 12 then
            log.error(LOG_TAG, "设备密钥长度错误, 请检查配置文件")
            sys.restart()
        end
        CONFIG.SMSYNC.SMSYNC_BEACON_KEY = CONFIG.SMSYNC.DEFAULT.SMSYNC_BEACON_KEY
        log.info(LOG_TAG, "使用配置文件中已设置的设备密钥", CONFIG.SMSYNC.SMSYNC_BEACON_KEY)
    end
end

local function load_smsync_config(config_key, default_value)
    local value = fskv.get("CONFIG.SMSYNC." .. config_key)
    if value ~= nil then
        CONFIG.SMSYNC[config_key] = value
        -- table类型需要序列化
        if type(default_value) == "table" then
            log.info(LOG_TAG, "加载KVFS中存储的配置", "CONFIG.SMSYNC." .. config_key,
                UTIL.table_to_str(CONFIG.SMSYNC[config_key]))
        else
            log.info(LOG_TAG, "加载KVFS中存储的配置", "CONFIG.SMSYNC." .. config_key, tostring(CONFIG.SMSYNC[config_key]))
        end
    else
        CONFIG.SMSYNC[config_key] = default_value
        -- table类型需要序列化
        if type(default_value) == "table" then
            log.info(LOG_TAG, "使用默认配置", "CONFIG.SMSYNC.DEFAULT." .. config_key,
                UTIL.table_to_str(CONFIG.SMSYNC[config_key]))
        else
            log.info(LOG_TAG, "使用默认配置", "CONFIG.SMSYNC.DEFAULT." .. config_key, tostring(CONFIG.SMSYNC[config_key]))
        end
    end
end

local function update_smsync_config(config_changed_table)
    log.info(LOG_TAG, "update config 更新配置")
    log.debug(LOG_TAG, "配置更新", json.encode(config_changed_table))
    -- 更新配置
    -- 遍历config_changed_table 写入配置
    for config_key, config_value in pairs(config_changed_table) do
        CONFIG.SMSYNC[config_key] = config_value
        -- 持久化配置
        fskv.set("CONFIG.SMSYNC." .. config_key, CONFIG.SMSYNC[config_key])
        if type(CONFIG.SMSYNC[config_key]) == "table" then
            log.info(LOG_TAG, "更新配置", "CONFIG.SMSYNC." .. config_key, UTIL.table_to_str(CONFIG.SMSYNC[config_key]))
        else
            log.info(LOG_TAG, "更新配置", "CONFIG.SMSYNC." .. config_key, tostring(CONFIG.SMSYNC[config_key]))
        end
        if config_key == "WS_CONFIG" or config_key == "FWD_CHANNEL" or config_key == "NET_ENABLE" then
            sys.publish(CONFIG.EVENT_ENUM.WS_SERVICE.CONFIG_CHANGED)
        end
    end
end

local function load_config()
    -- 加载配置
    log.info(LOG_TAG, "load config 加载配置")
    -- 发布配置加载事件
    sys.publish(CONFIG.EVENT_ENUM.CONFIG.LOADING)
    load_smsync_beacon_key()
    load_smsync_config("PHONE_NUM", CONFIG.SMSYNC.DEFAULT.PHONE_NUM)
    load_smsync_config("FWD_CHANNEL", CONFIG.SMSYNC.DEFAULT.FWD_CHANNEL)
    load_smsync_config("WS_CONFIG", CONFIG.SMSYNC.DEFAULT.WS_CONFIG)
    load_smsync_config("SMS_FWD_LIST", CONFIG.SMSYNC.DEFAULT.SMS_FWD_LIST)
    load_smsync_config("FWD_ENABLE", CONFIG.SMSYNC.DEFAULT.FWD_ENABLE)
    load_smsync_config("NET_ENABLE", CONFIG.SMSYNC.DEFAULT.NET_ENABLE)
    load_smsync_config("BLACKLIST", CONFIG.SMSYNC.DEFAULT.BLACKLIST)
    log.info(LOG_TAG, "load config 加载配置完成")
    -- 发布配置加载完成事件
    sys.publish(CONFIG.EVENT_ENUM.CONFIG.LOADED)
end

function init.init()
    init_log()
    init_fskv()
    load_config()
    log.debug(LOG_TAG, json.encode(CONFIG.SMSYNC))
    -- 监听配置重新加载事件
    sys.subscribe(CONFIG.EVENT_ENUM.CONFIG.RELOAD, load_config)
    sys.subscribe(CONFIG.EVENT_ENUM.CONFIG.CHANGED, update_smsync_config)
    SMS_SERVICE.init()
    FWD_SERVICE.init()
    WS_SERVICE.init()
    if CONFIG.LOG.LEVEL == "DEBUG" then
        for index, value in pairs(CONFIG.COMPRESS_DICT) do
            log.debug(LOG_TAG, "压缩字典", index, value)
        end
    end
end

return init
