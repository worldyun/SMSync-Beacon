_G.CONFIG = require "config"
_G.UTIL = require "util"
_G.SMS_SERVICE = require "sms_service"
_G.FWD_SERVICE = require "fwd_service"
_G.WS_SERVICE = require "ws_service"
_G.sys = require("sys")

PROJECT = "SMSync-Beaco" -- 项目名称
VERSION = "0.0.1"        -- 版本号
log.info(PROJECT, VERSION)

local LOG_TAG = "MAIN"

-- 初始化

sys.subscribe("SIM_IND", function(status, value)
    if status == "RDY" then
        log.info(LOG_TAG, "sim卡已就绪")
        log.info(LOG_TAG, "imei", mobile.imei())
        log.info(LOG_TAG, "imsi", mobile.imsi())
        log.info(LOG_TAG, "iccid", mobile.iccid())
    end
    if status == "NORDY" then
        log.info(LOG_TAG, "请插入sim卡")
    end
    if status == "SIM_PIN" then
        log.info(LOG_TAG, "sim卡需要pin码, 请解除")
    end
end)

sys.subscribe("IP_READY", function(ip, adapter)
    log.info(LOG_TAG, "网络已连接", "ip: " .. ip)
end)

sys.subscribe("IP_LOST", function(adapter)
    log.info(LOG_TAG, "网络已断开")
end)

sys.subscribe("NTP_UPDATE", function()
    log.info(LOG_TAG, "时间已同步", os.date())
    sys.taskInit(function()
        require("init").init()
    end)
end)

local test = UTIL.pbkdf2("123456", "7890", CONFIG.CRYPTO.PBKDF2_ITER, CONFIG.CRYPTO.KEY_LEN)
-- 16进制打印
log.info(LOG_TAG, "test: " .. UTIL.str_to_hex(test))

-- 启用调度器
sys.run()
