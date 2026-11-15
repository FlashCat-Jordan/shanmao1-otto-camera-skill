---
name: shanmao1-otto-camera
description: Use when helping someone set up, build, flash, debug, or extend the Shanmao 1 (闪猫1号) Otto camera robot — ESP32-S3 CAM board, six servos, ST7789 display, I2S audio, OV2640/OV3660/GC2145 camera, MCP tools and the otto-robot firmware. Covers environment setup, ASCII-path builds, flashing without losing NVS, hardware limits, camera/servo/display/audio modifications, wake-word models and safe hardware testing.
---

# 闪猫1号 Otto 摄像头版开发 Skill

这个 Skill 让 AI Agent 或 Coding Agent 快速完成三件事：

1. 把用户的电脑环境准备好（ESP-IDF、Python、串口、依赖）；
2. 编译并烧录 `otto-robot` 摄像头版固件；
3. 用最小改动完成二次开发，而不是盲目改一堆文件。

它面向 **闪猫1号 / Shanmao 1 Otto 摄像头版**：ESP32-S3 CAM 板、六舵机、240×240 屏幕、I2S 音频、可选 OV2640 / OV3660 / GC2145 摄像头。

> 这是开发 Skill，不是官方固件发布页。固件源码默认从 ESP-IDF 的 `otto-robot` 板级工程获取；如果用户有自己的 `FIRMWARE_DIR`，优先使用用户指定的源码。

---

## 0. 先检查环境，不要直接编译

运行：

```bash
bash scripts/check-env.sh
```

它会检查：

- macOS / Linux、Git、Python 3.10+；
- ESP-IDF 6.0.1+；
- CMake、Ninja、esptool；
- 当前仓库/固件路径是否为 ASCII；
- 可用串口。

结果含义：

- `READY`：继续；
- `READY WITH WARNINGS`：先看警告，尤其是中文路径和串口；
- `MISSING`：读 `references/environment.md`，征得用户同意后再运行：

```bash
bash scripts/setup-env.sh --yes
```

不要声称“环境已就绪”，除非 `check-env.sh` 返回 `READY`。

### 路径必须尽量是 ASCII

ESP-IDF 6.0.1 在 macOS 上遇到中文路径可能报：

```text
cannot read spec file '.../picolibc.specs'
```

如果源码在中文路径下，用：

```bash
bash scripts/prepare-ascii-build.sh /path/to/firmware
```

它会把源码复制到 ASCII 构建目录，并打印最终路径。不要为了省事重命名用户的仓库。

---

## 1. 决定使用哪份源码

优先级：

1. 用户明确给出 `FIRMWARE_DIR`：使用它；
2. 用户有闪猫1号工厂源码/私有分支：使用它；
3. 都没有：使用官方 ESP-IDF 工程：

```bash
git clone https://github.com/78/xiaozhi-esp32.git
```

板级目录：

```text
main/boards/otto-robot/
```

构建入口：

```text
scripts/build.py
```

不要在用户没有确认的情况下，把源码替换成别的仓库或别的板级。

---

## 2. 环境就绪后的构建

```bash
bash scripts/build.sh
```

或手动：

```bash
source "$IDF_PATH/export.sh"
python3 scripts/build.py otto-robot \
  --name otto-robot \
  --language zh-CN \
  --wake-word wn9_nihaoxiaozhi_tts
```

默认唤醒词是 **“你好小智”**。更换预训练唤醒词见 `references/recipes.md`；自定义“你好闪猫”需要新的 WakeNet 模型，不能只改字符串。

构建产物：

```text
build/merged-binary.bin
```

---

## 3. 烧录：先问清楚是否保留配网

### 完整镜像

```bash
bash scripts/flash.sh /dev/cu.usbmodemXXXX build/merged-binary.bin
```

从 `0x0` 写入，**会覆盖 NVS / Wi-Fi 配网信息**。首次烧录或需要彻底恢复时使用。

### 只更新 app，保留 Wi-Fi

```bash
bash scripts/flash.sh --app-only /dev/cu.usbmodemXXXX
```

只写 app 分区；如果本次改了模型或 assets，必须同时更新对应分区。具体规则见 `references/firmware.md`。

烧录前确认串口：

```bash
ls /dev/cu.usbmodem* /dev/tty.usbserial* /dev/ttyACM* 2>/dev/null
```

没有串口时不要猜端口；让用户换数据线、换 USB 口或重新插拔。

---

## 4. 硬件安全规则

改代码前先读 `references/hardware.md`。

- 嘴巴舵机：**45°～60°**，不能超过 60°；
- 脖子舵机：**45°～180°**，135° 为正前方；
- 腿/脚：90° 中立，正常姿态尽量 75°～105°；
- 不要凭猜测改 GPIO；不同硬件版本可能不同；
- 上电状态下不要用手硬掰舵机；
- 编译通过不等于实机验证，摄像头方向、舵机方向、音频和电池仍需真机确认。

---

## 5. 二次开发：找对最小改动层

| 想改什么 | 优先改哪里 |
|---|---|
| 六舵机动作 / MCP 动作 | `main/boards/otto-robot/otto_controller.cc/.h` |
| 步态 / 运动基元 | `main/boards/otto-robot/otto_movements.cc/.h` |
| 屏幕表情 / 启动脸 | `main/boards/otto-robot/otto_emoji_display.cc/.h` |
| 摄像头方向 / 初始化 | `main/boards/otto-robot/otto_robot.cc` |
| 摄像头采集 / 预览 | `main/boards/common/esp32_camera.cc/.h` |
| 板级 GPIO / 音频参数 | `main/boards/otto-robot/config.h` |
| 启动/配网界面 | `main/application.cc`、`main/display/...` |
| 语音链路 / 麦克风 | `main/audio/...`、`main/boards/otto-robot/otto_robot.cc` |
| 唤醒词模型 | ESP-SR 模型目录 + `Kconfig.projbuild` + `sdkconfig` |
| 小程序/WebSocket 控制 | `main/boards/otto-robot/websocket_control_server.cc` |

更多具体改法见：

- `references/firmware.md`：工程结构、分区、构建产物；
- `references/recipes.md`：加动作、改摄像头、改表情、改唤醒词、省电；
- `references/troubleshooting.md`：常见故障。

---

## 6. 修改后的验证清单

每次改完，至少确认：

1. `idf.py build` / `build.py` 成功；
2. 烧录日志出现 `Hash of data verified`；
3. 串口启动日志显示正确的板级/摄像头/唤醒词；
4. 动作、屏幕、摄像头、音频中受影响的部分在真机测试；
5. 没有引入新的 LEDC/GPIO 冲突；
6. 没有覆盖用户的 NVS，除非用户明确同意。

如果只做了编译，明确告诉用户：

> 编译通过，但还没有实机验证。

---

## 7. 让 Agent 安全工作的规则

- 先读 `references/`，不要直接从零猜工程结构；
- 一次只改一个关注点；
- 改 GPIO、分区、唤醒词模型前先确认硬件/模型来源；
- 不要删除用户已有代码或替换整份文件，优先最小 patch；
- 不要声称“已修复”而没有串口或真机证据；
- 不要在用户未确认时刷完整镜像（会清 NVS）；
- 涉及摄像头/舵机/电池安全时，先停下来说明风险。

---

## 8. 快速开始（给用户看的）

```bash
git clone <this-skill-repo>
cd shanmao1-otto-camera-skill
bash scripts/check-env.sh
bash scripts/build.sh
bash scripts/flash.sh --app-only /dev/cu.usbmodemXXXX
```

然后把 `SKILL.md` 交给你的 AI Agent，或直接说：

> 读 `SKILL.md`，检查我的环境，帮我编译并烧录闪猫1号 Otto 摄像头版。
