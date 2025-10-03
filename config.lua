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
    MAX_TIMESTAMP_DIFF = 300, -- 信令时间戳允许的最大时间差(秒)
    OP_CODE_START = "#*",     -- 信令起始
    OP_CODE_END = "*#",       -- 信令结束
    COMPRESS = true,          -- 信令压缩使能
}

-- 加密配置
CONFIG.CRYPTO = {
    ALGORITHM = "AES-128-CBC",  -- 加密算法
    KEY_LEN = 16,               -- 密钥长度
    PADDING = "PKCS7",          -- 填充方式
    PBKDF2_ITER = 1000,         -- PBKDF2迭代次数
    KEY = nil,                  -- 设备密钥, 16字节, 不可设置, 由设备密钥生成 计算方式: sha256(imei+设备密钥)取前KEY_LEN字节
}

-- WS服务配置
CONFIG.WS = {
    MAX_TIMESTAMP_DIFF = 300,       -- 时间戳允许的最大时间差(秒)
    AUTO_RECONNECT_TIME = 3000,     -- 自动重连时间间隔 单位ms 默认3000ms
    AUTO_RECONNECT_ENABLE = false,   -- 自动重连使能
    HEARTBEAT_INTERVAL  = 30000,     -- 心跳间隔 单位ms 默认30000ms
    HEADERS_KEY = {
        AUTHORIZATION = "Authorization",        -- sha512(accessKey)
        SMSYNC_BEACO_ID = "SMSYNC-Beaco-ID",    -- sha512(imei)
        SALT = "Salt"                           -- 随机盐
    },
    WS_SEND_COUNT = 0,              -- ws发送消息计数
    WS_RECV_COUNT = 0,              -- ws接收消息计数
    CRYPTO_SALT_LEN = 16,           -- 加密随机盐长度
    CRYPTO_KEY = nil,               -- 加密密钥, 运行时由accessKey生成, 请勿修改
}

-- WS服务参数枚举
CONFIG.WS_PARAM_ENUM = {
    TIMESTAMP = "timestamp",    -- 时间戳
    RES_ID = "res_id",          -- 来源ID   hmac_sha256(res, mobile.imei() .. mobile.imsi())
    MSG = "msg",                -- 消息
    ACTION = "action",          -- 操作码
    COUNT = "count",            -- mgs计数，防止重放攻击
}

-- WS服务操作码枚举
CONFIG.WS_ACTION_CODE_ENUM = {
    MSG = "msg",                 -- 消息
    HEARTBEAT = "heartbeat",     -- 心跳
}

-- 转发服务参数
CONFIG.FWD = {
    SMS_FWD_UP_TEMPLATE = "$content (SMSync:来自$res)",    -- 短信转发模板
    SMS_FWD_UP_TEMPLATE_PLACEHOLDER = {                 -- 短信转发模板占位符
        CONTENT = "$content",
        RES = "$res",
    },
}

-- 转发服务参数枚举
CONFIG.FWD_PARAM_ENUM = {
    TIMESTAMP = "timestamp",    -- 时间戳
    RES_NUM = "resNum",         -- 来源号码
    CONTENT = "content",        -- 内容
}

-- 短信信令操作码枚举
CONFIG.SMS_OP_CODE_ENUM = {
    SET_CONFIG = "setConfig",      -- 设置配置
    GET_CONFIG = "getConfig",      -- 获取配置
    SET_CHANNEL = "setChannel",     -- 设置转发通道
    SEND_SMS = "sendSms",        -- 发送短信
}

-- 短信信令操作码SET_CONFIG的参数枚举
CONFIG.SMS_OP_SET_CONFIG_PARAM_ENUM = {
    FWD_ENABLE = "fwdEnable",              -- 是否启用转发功能
    NET_ENABLE = "netEnable",              -- 是否启用网络功能
    ADD_BLACKLIST = "addBlackList",          -- 添加黑名单
    RM_BLACKLIST = "rmBlackList",           -- 移除黑名单
    CLEAR_BLACKLIST = "clearBlackList",        -- 清空黑名单
}

-- 短信信令操作码GET_CONFIG的参数枚举
CONFIG.SMS_OP_GET_CONFIG_PARAM_ENUM = {
    CONFIG_LIST = "configList",     -- 配置列表
    FWD_ENABLE = "fwdEnable",      -- 是否启用转发功能
    NET_ENABLE = "netEnable",      -- 是否启用网络功能
    BLACKLIST = "blacklist",       -- 黑名单列表
    FWD_CHANNEL = "fwdChannel",     -- 转发通道
    PHONE_NUM = "phoneNum",       -- 自身电话号码
    SMS_FWD_LIST = "smsFwdList",   -- 短信转发目标列表
    WS_CONFIG = "wsConfig",       -- WebSocket配置
}

-- 短信信令操作码SET_CHANNEL的参数枚举
CONFIG.SMS_OP_SET_CHANNEL_PARAM_ENUM = {
    PHONE_NUM = "phoneNum",       -- 自身电话号码
    FWD_CHANNEL = "fwdChannel",     -- 转发通道 ws-通过WebSocket同步, sms-通过短信同步
    WS_CONFIG = "wsConfig",       -- WebSocket配置
    SMS_FWD_LIST = "smsFwdList",   -- 短信转发目标列表
}

-- 短信信令操作码SEND_SMS的参数枚举
CONFIG.SMS_OP_SEND_SMS_PARAM_ENUM = {
    DES_NUM = "desNum",     -- 目标电话号码
    CONTENT = "content",     -- 短信内容
}

-- 短信信令通用参数枚举
CONFIG.SMS_OP_COMMON_PARAM_ENUM = {
    TIMESTAMP = "timestamp",
    OP = "op",
}

-- 转发通道枚举
CONFIG.FWD_CHANNEL_ENUM = {
    SMS = "sms",    -- 短信转发
    WS = "ws",      -- WebSocket转发
}

-- 转发方向枚举
CONFIG.FWD_DIRECTION_ENUM = {
    UP = "up",      -- 上行 接收第三方短信转发至控制端
    DOWN = "down",  -- 下行 接收控制端信息转发至目标号码
}

-- 事件枚举
CONFIG.EVENT_ENUM = {
    CONFIG = {
        LOADING = "CONFIG_LOADING", -- 配置加载中
        LOADED = "CONFIG_LOADED",   -- 配置加载完成
        RELOAD = "CONFIG_RELOAD",   -- 配置重新加载
        CHANGED = "CONFIG_CHANGED", -- 配置已修改
    },
    FWD_SERVICE = {
        FWD = "FWD_SERVICE_FWD",        -- 转发服务事件
    },
    WS_SERVICE = {
        CONNECT = "WS_SERVICE_CONNECT",                 -- WebSocket服务连接事件
        DISCONNECT = "WS_SERVICE_DISCONNECT",           -- WebSocket服务断开连接事件
        CONFIG_CHANGED = "WS_SERVICE_CONFIG_CHANGED",   -- WebSocket服务配置已修改
    },
}

-- 压缩字典 用于信令压缩 起始值为1
CONFIG.COMPRESS_DICT = {
    [["fwdEnable":true]], [["fwdEnable":false]] , [["netEnable":true]], [["netEnable":false]], [["clearBlackList":true]], [["clearBlackList":false]], [["fwdChannel":"ws"]], [["fwdChannel":"sms"]], 
    [["fwdEnable"]], [["netEnable"]], [["clearBlackList"]], [["fwdChannel"]],
    [["addBlackList":]], [["rmBlackList":]], [["blacklist"]], [["phoneNum"]], [["smsFwdList"]], [["wsConfig"]], [["desNum":]], [["content":]], [["timestamp":]], [["configList":]],
    [["op":"setConfig"]], [["op":"getConfig"]], [["op":"setChannel"]], [["op":"sendSms"]],
    [[@ws:\/\/]], [[","]], [[.com]], [[.cn]], [[106]],
}

return CONFIG
