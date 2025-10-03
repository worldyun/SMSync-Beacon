# SMSync-Beaco
一个双向短信转发器

# 短信信令格式

## 信令格式

- 以`#*`为开头，以`*#`为结尾。

- 信令内容支持加密，加密算法为`AES-128-CBC`，填充方式为`PKCS7`。密钥计算方式: `hmac_sha256(imei,设备密钥)`取前`KEY_LEN`字节（16字节）。

- 信令中间内容为`iv + base64( crypt(JSON) )`。

- 如果同时开启压缩，则信令中间内容为`iv + base64( crypt( compress(JSON) ) )`。

- `op`为操作码。

- `timestamp`为时间戳，秒级，所有信令都带。时间差大于300秒的信令将被丢弃。
  示例：
  
  ```json
  { 
      "op" : "setChannel",
      "timestamp": 1759332892,
      "phoneNum" : "18900000000",
      "syncType" : "ws/sms"
      "wsConfig" : "accessKey@url",                    //仅syncType为ws时需要
      "smsFwdList" : ["15600000000","13200000000"]     //仅syncType为sms时需要
  }
  ```

## 操作码(op)

| op         | 含义     | 备注  |
| ---------- | ------ | --- |
| setConfig  | 更新设置   |     |
| getConfig  | 获取配置   |     |
| setChannel | 设置转发通道 |     |
| sendSms    | 发送短信   |     |

### `setConfig`更新设置

| 字段             | 含义    | 类型             | 备注                                                                  | 必须
| -------------- | ----- |:-------------- | ------------------------------------------------------------------- | --- |
| fwdEnable      | 转发使能  | bool           | `true`启用；`false`禁用；默认禁用，设置转发通道时会自动打开转发，可再次关闭                        | 是 |
| netEnable      | 网络使能  | bool           | `true`启用；`false`禁用；默认禁用，设置ws转发时会自动打开网络，可再次关闭，设置sms转发时会自动关闭网络，可再次打开； | 是 |
| addBlackList   | 添加黑名单 | List\<String\> | 字符串数组形式的号码列表，也可以是短信屏蔽关键字                                            | 否 |
| rmBlackList    | 移出黑名单 | List\<String\> | 字符串数组形式的号码列表，也可以是短信屏蔽关键字                                            | 否 |
| clearBlackList | 清空黑名单 | bool           | 清空黑名单                                                               | 否 |

### `getConfig` 获取配置

| 字段         | 含义   | 类型             | 备注          | 必须 |
| ---------- | ---- | -------------- | ----------- | --- |
| configList | 配置列表 | List\<String\> | 可不设置以获取全部配置 | 否 |

### `setChannel`设置转发通道

| 字段         | 含义          | 类型             | 备注                                  | 必须 |
| ---------- | ----------- | -------------- | ----------------------------------- | --- |
| phoneNum   | 转发设备内的卡号    | String         |                                     | 是 |
| fwdChannel | 转发方式        | String         | `ws`websocket模式；`sms`短信模式           | 是 |
| wsConfig   | websocket配置 | String         | `accessKey@url`；仅`syncType`为`ws`时需要，`wsConfig`与`smsFwdList`必选其一，不可同时为空 | 否 |
| smsFwdList | 转发目标列表      | List\<String\> | 字符串数组形式的号码列表，会将收到的短信转发给列表内所有号码，仅`syncType`为`sms`时需要      | 否 |

### `sendSms`发送短信

| 字段      | 含义   | 类型     | 备注  | 必须 |
| ------- | ---- | ------ | --- | --- |
| desNum  | 目标号码 | String |     | 是 |
| content | 短信内容 | String |     | 是 |
