# 常见二次开发配方

## 1. 加一个 MCP 动作

入口：`main/boards/otto-robot/otto_controller.cc`

步骤：

1. 在 `ActionType` 增加枚举；
2. 在 `ActionTask()` 的 `switch` 里调用 `otto_` 的运动函数；
3. 在 `QueueAction()` 的字符串映射里增加动作名；
4. 在 `self.otto.action` 的说明/参数里更新可选动作；
5. 编译并用 MCP/语音测试。

不要直接复制一个动作却不处理“动作结束后是否 Home”的逻辑。

## 2. 改摄像头初始化/方向

入口：

```text
main/boards/otto-robot/otto_robot.cc
main/boards/common/esp32_camera.cc
```

常见改动：

- GC2145 关闭 `hmirror` / `vflip`；
- 预览旋转补偿 180°；
- 摄像头初始化失败时降级，不影响开机。

注意：**传感器翻转和预览旋转是两个独立层面**，不要同时翻转两次。

## 3. 改屏幕表情/启动脸

入口：

```text
main/boards/otto-robot/otto_emoji_display.cc
main/application.cc
```

- 默认表情：`OttoEmojiDisplay::SetupUI()`；
- 配网/启动时的提示图标：`Application::Alert(..., "gear", ...)`；
- `robot_2` / `gear` 可映射到 `neutral`，避免中间出现小图标；
- 表情 GIF 来自 assets 分区，改图后必须更新 assets。

## 4. 改舵机空闲省电

思路：

1. 动作结束后记录时间；
2. 空闲超过阈值、动作队列为空、设备处于 idle；
3. `Otto::PauseServos()` 停六路 PWM；
4. 下一个动作前 `Otto::ResumeServos()`。

关键实现：

- `Oscillator::Pause()`：`ledc_stop(..., 0)`；
- `Oscillator::Resume()`：重新 `Write(pos_)`，由 `ledc_update_duty` 重新打开输出；
- 不要用重复 `AttachServos()`，否则会重复占用 LEDC/GPIO。

注意：这只省“保持电流”，舵机 VCC 仍然通电；完全断电需要硬件负载开关。

## 5. 改唤醒词

### 使用预训练词

改 `sdkconfig`：

```text
CONFIG_SR_WN_WN9_XIAOYAXIAOYA_TTS2=y
# CONFIG_SR_WN_WN9_NIHAOXIAOZHI_TTS is not set
```

重新编译，并更新 **model 分区**。

### 自定义“你好闪猫”

pinyin：

```text
nihaoshanmao
```

但必须由 Espressif 的 TTS Pipeline / 定制服务生成 WakeNet 模型，放到 model 分区，不能只改字符串。

参考：

- https://github.com/espressif/esp-sr/issues/88
- https://docs.espressif.com/projects/esp-sr/en/latest/esp32s3/wake_word_engine/ESP_Wake_Words_Customization.html

## 6. 改麦克风/音频

入口：

```text
main/boards/otto-robot/config.h
main/audio/engines/afe_audio_engine.cc
main/audio/codecs/no_audio_codec.cc
```

- 双工 I2S 必须保持输入/输出采样率一致；
- AFE 可开 AGC；NS 可能降低识别率，需实测；
- 不要只看“声音大”，要看是否削顶；
- 麦克风增益不要和 AGC 同时猛加。

## 7. 改配网/启动 UI

入口：

```text
main/application.cc
main/boards/common/wifi_board.cc
main/display/lcd_display.cc
```

- 配网提示来自 `WifiBoard::StartWifiConfigMode()`；
- 启动提示来自 `Application` 的 startup hint；
- 改动会跨板级生效，优先做 board-specific 处理。

## 8. 加一个 Web/WebSocket 控制

入口：

```text
main/boards/otto-robot/websocket_control_server.cc
```

- 端口 8080；
- MCP JSON-RPC；
- 小程序/网页都要处理首帧 client 注册；
- 动作走同一个队列，避免绕过限位和安全检查。
