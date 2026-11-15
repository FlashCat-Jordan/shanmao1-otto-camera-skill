# 固件结构、构建与烧录

## 源码结构

ESP-IDF 的 `otto-robot` 板级在：

```text
main/boards/otto-robot/
├── config.h                  # 板级 GPIO / 音频参数
├── otto_robot.cc             # 板卡初始化、摄像头、音频、WebSocket
├── otto_controller.cc        # 动作队列、MCP 工具
├── otto_movements.cc/.h      # 六舵机运动基元
├── otto_emoji_display.cc/.h  # 屏幕表情/预览
├── oscillator.cc/.h           # 舵机 PWM
├── power_manager.h            # 电池/充电
└── websocket_control_server.cc
```

通用摄像头驱动：

```text
main/boards/common/esp32_camera.cc/.h
main/boards/common/camera.h
```

## 构建

```bash
source ~/esp/esp-idf-v6.0.1/export.sh
python3 scripts/build.py otto-robot \
  --name otto-robot \
  --language zh-CN \
  --wake-word wn9_nihaoxiaozhi_tts
```

产物：

```text
build/xiaozhi.bin         # app
build/generated_assets.bin
build/merged-binary.bin   # 完整合并镜像
build/flash_args          # 本次构建的烧录地址表
```

不要假设地址永远是 `0x20000` / `0x800000`。先看：

```bash
cat build/flash_args
```

## 分区

当前工程可能存在 v1 / v2 两套 16MB 分区，例如：

```text
nvs       0x9000
otadata   0xd000
phy_init  0xf000
model     0x10000
ota_0     ...
ota_1     ...
assets    ...
```

以实际 `partitions/` 和 `build/flash_args` 为准。`model` 和 `assets` 是两个不同分区：

- 唤醒词模型 → `model`
- 表情 GIF / 提示音 / 语言资源 → `assets`

只刷 app 不会更新 model/assets。

## 烧录策略

### 首次或彻底恢复：完整镜像

```bash
esptool --chip esp32s3 -p <PORT> -b 460800 \
  write_flash 0x0 build/merged-binary.bin
```

> 会覆盖 NVS，Wi-Fi 配网信息丢失。

### 只更新 app，保留 Wi-Fi

```bash
esptool --chip esp32s3 -p <PORT> -b 460800 \
  write_flash 0x20000 build/xiaozhi.bin
```

地址必须来自 `build/flash_args`，不能死记。

### 同时更新 assets 或 model

```bash
esptool --chip esp32s3 -p <PORT> -b 460800 \
  write_flash \
  0x20000 build/xiaozhi.bin \
  <assets_offset> build/generated_assets.bin \
  <model_offset> build/model.bin
```

具体 offset 以 `build/flash_args` 和分区表为准。

### 保留 NVS 刷完整镜像

先备份 NVS，再恢复：

```bash
esptool read_flash 0x9000 0x6000 nvs_backup.bin
esptool write_flash 0x0 build/merged-binary.bin
esptool write_flash 0x9000 nvs_backup.bin
```

注意：NVS 大小随分区表变化，先读分区表确认长度。

## 启动日志要看什么

正常时会出现：

```text
Board: ...
摄像头类型: ...
AudioCodec: ...
WakeNet Model: wn9_...
StateMachine: ... -> idle
```

摄像头版如果未插摄像头：

```text
摄像头版未检测到摄像头，将跳过摄像头初始化
```

这是正常降级，不是崩溃。

## 唤醒词

预训练模型通过 `sdkconfig` 的 `CONFIG_SR_WN_*` 选择。模型文件在：

```text
managed_components/espressif__esp-sr/model/wakenet_model/
```

当前常用：

```text
wn9_nihaoxiaozhi_tts
```

自定义“你好闪猫”需要新的 WakeNet 模型，不能只改字符串。

## 版本与许可证

- 固件源码以实际仓库 LICENSE 为准；
- ESP-SR 模型有独立许可；
- 不要把第三方模型/音色素材当作自己的独占资产分发。
