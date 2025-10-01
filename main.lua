_G.CONFIG = require "config"
_G.UTIL = require "util"
_G.sys = require("sys")

PROJECT = "SMSync-Beaco" -- 项目名称
VERSION = "0.0.1"        -- 版本号
log.info(PROJECT, VERSION)

local LOG_TAG = "MAIN"

sys.subscribe("IP_READY", function(ip, adapter)
    log.info(LOG_TAG, "网络已连接", "ip: " .. ip)
    log.info(LOG_TAG, "imei", mobile.imei())
    log.info(LOG_TAG, "imsi", mobile.imsi())
    log.info(LOG_TAG, "iccid", mobile.iccid())
end)

-- 初始化
require("init").init()

-- 启用调度器
sys.run()
