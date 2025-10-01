local CONFIG = {}

-- SMSYNC配置
CONFIG.SMSYNC = {
    -- 默认配置, 可不设置, 由短信信令修改。信令配置优先级高于默认配置
    DEFAULT = {
        SMSYNC_BEACO_KEY = nil,              -- 设备密钥, 可不设置, 由设备自动生成, 设备启动时会打印出来, 使用Luatools可查看; 也可修改为自定义密钥, 长度12位, 只能包含大小写字母和数字, 使用半角双引号包裹, 例如"FBA57224295A"
        PHONE_NUM = "13333333333",           -- 自身电话号码
        FWD_CHANNEL = "ws",                  -- 同步类型 ws-通过WebSocket同步, sms-通过短信同步
        WS_CONFIG = "accessKey@url",         -- WebSocket配置, FWD_CHANNEL为ws时生效 格式: 访问密钥@链接地址 例如"my_access_key@ws://example.com/websocket"
        SMS_FWD_LIST = {"1890000000"},       -- 短信转发目标列表, FWD_CHANNEL为sms时生效
        FWD_ENABLE = false,                  -- 是否启用转发功能
        NET_ENABLE = false,                  -- 是否启用网络功能
        BLACKLIST = {"132*"},                -- 黑名单列表, 可以为手机号码, 也可以为号码段, 号码段以*结尾, 例如138*, 或者关键字, 以*开头结尾, 例如*测试*
        -- 添加黑名单后, 收到短信时会先判断是否在黑名单中, 如果在黑名单中则不转发
        -- 注意: 黑名单只针对转发功能, 不影响正常发送短信
        -- 示例: {"13800000000", "13900000000", "137*", "*测试*"}
    },

    -- 以下内容为运行时配置, 请勿修改
    SMSYNC_BEACO_KEY = nil, -- 设备密钥, 可不设置, 由设备自动生成, 设备启动时会打印出来, 使用Luatools可查看; 也可修改为自定义密钥, 长度12位
    PHONE_NUM = nil,        -- 自身电话号码
    FWD_CHANNEL = nil,      -- 同步类型 ws-通过WebSocket同步, sms-通过短信同步
    WS_CONFIG = nil,        -- WebSocket配置, FWD_CHANNEL为ws时生效,
    SMS_FWD_LIST = {},      -- 短信转发目标列表, FWD_CHANNEL为sms时生效
    FWD_ENABLE = false,     -- 是否启用转发功能
    NET_ENABLE = false,     -- 是否启用网络功能
    BLACKLIST = {},         -- 黑名单列表, 可以为手机号码, 也可以为号码段, 号码段以*结尾, 例如138*, 或者关键字, 以*开头结尾, 例如*测试*
}

-- 日志配置
CONFIG.LOG = {
    LEVEL = "DEBUG",       -- 日志等级 SILENT, DEBUG, INFO, WARN, ERROR, FATAL   0~5
    STYLE = 1,            -- 日志风格
}

-- 信令配置
CONFIG.OP = {
    MAX_TIMESTAMP_DIFF = 300,   -- 信令时间戳允许的最大时间差(秒)
    OP_CODE_START = "#*#*",     -- 信令起始
    OP_CODE_END = "*#*#",       -- 信令结束
}

CONFIG.CRYPTO = {
    ALGORITHM = "AES-128-CBC",  -- 加密算法
    KEY_LEN = 16,               -- 密钥长度
    PADDING = "PKCS7",          -- 填充方式
    KEY = nil,                  -- 加密密钥, 16字节, 可不设置, 由设备密钥生成 计算方式: sha256(imei+设备密钥)取前KEY_LEN字节
}

-- 短信信令操作码枚举
CONFIG.SMS_OP_CODE_ENUM = {
    SET_CONFIG = "setConfig",   -- 设置配置
    GET_CONFIG = "getConfig",   -- 获取配置
    SET_CHANNEL = "setChannel", -- 设置转发通道
    SEND_SMS = "sendSms",       -- 发送短信
}

-- 短信信令操作码SET_CONFIG的参数枚举
CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM = {
    FWD_ENABLE = "fwdEnable",           -- 是否启用转发功能
    NET_ENABLE = "netEnable",           -- 是否启用网络功能
    ADD_BLACKLIST = "addBlackList",     -- 添加黑名单
    RM_BLACKLIST = "rmBlackList",       -- 移除黑名单
    CLEAR_BLACKLIST = "clearBlackList", -- 清空黑名单
}

-- 短信信令操作码GET_CONFIG的参数枚举
CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM = {
    FWD_ENABLE = "fwdEnable", -- 是否启用转发功能
    NET_ENABLE = "netEnable", -- 是否启用网络功能
    BLACKLIST = "blackList",  -- 黑名单列表
    FWD_CHANNEL = "fwdChannel", -- 转发通道
    PHONE_NUM = "phoneNum",   -- 自身电话号码
    SMS_FWD_LIST = "smsFwdList", -- 短信转发目标列表
    WS_CONFIG = "wsConfig",   -- WebSocket配置
}

-- 短信信令操作码SET_CHANNEL的参数枚举
CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM = {
    PHONE_NUM = "phoneNum",      -- 自身电话号码
    FWD_CHANNEL = "fwdChannel",  -- 转发通道 ws-通过WebSocket同步, sms-通过短信同步
    WS_CONFIG = "wsConfig",      -- WebSocket配置
    SMS_FWD_LIST = "smsFwdList", -- 短信转发目标列表
}

-- 短信信令操作码SEND_SMS的参数枚举
CONFIG.SMS_OP_SEND_SMS_PARAM_ENUM = {
    DES_NUM = "desNum",  -- 目标电话号码
    CONTENT = "content", -- 短信内容
}

-- 短信信令通用参数枚举
CONFIG.SMS_OP_COMMON_PARAM_ENUM = {
    SIGN = "sign",          -- 签名 sha256(imei+设备密钥)，取前8位，大写字母。每一条信令都必须携带sign
    TIMESTAMP = "timestamp",
    OP = "op",
}

-- 事件枚举
CONFIG.EVENT_ENUM = {
    CONFIG = {
        LOADING = "CONFIG_LOADING", -- 配置加载中
        LOADED = "CONFIG_LOADED",   -- 配置加载完成
        RELOAD = "CONFIG_RELOAD",   -- 配置重新加载
        CHANGED = "CONFIG_CHANGED", -- 配置已修改
    }
}

return CONFIG
