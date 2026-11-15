# 环境准备

## 需要什么

- macOS / Linux（Windows 建议 WSL2 或 ESP-IDF 官方安装器）
- Python 3.10+
- Git
- CMake / Ninja
- **ESP-IDF 6.0.1 或更高**
- 一根能传数据的 USB-C 线

## 检查

```bash
bash scripts/check-env.sh
```

如果输出 `MISSING`，先读本节，再决定是否安装。

## 安装 ESP-IDF

macOS / Linux：

```bash
mkdir -p ~/esp
cd ~/esp
git clone -b v6.0.1 --recursive https://github.com/espressif/esp-idf.git esp-idf-v6.0.1
cd esp-idf-v6.0.1
./install.sh esp32s3
```

每个新终端都要激活：

```bash
source ~/esp/esp-idf-v6.0.1/export.sh
```

也可以使用：

```bash
bash scripts/setup-env.sh --yes
```

该脚本会安装缺失的 Homebrew/apt 依赖，并在 `~/esp/esp-idf-v6.0.1` 安装 ESP-IDF。

## 中文路径问题

ESP-IDF 6.0.1 在 macOS 上遇到非 ASCII 路径可能报：

```text
cannot read spec file '.../picolibc.specs'
```

解决：

```bash
bash scripts/prepare-ascii-build.sh /path/to/firmware
```

脚本会把源码复制到 `$HOME/.cache/shanmao1-otto/build` 这类 ASCII 目录。

## Python 环境不一致

如果出现：

```text
python is currently active ... while project was configured with python3
```

在固件工程目录执行：

```bash
idf.py fullclean
idf.py build
```

不要手动改 `build/CMakeCache.txt`。

## 串口

macOS：

```bash
ls /dev/cu.usbmodem* /dev/cu.usbserial* 2>/dev/null
```

Linux：

```bash
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null
```

没有串口：

1. 换一根能传数据的 USB-C 线；
2. 直接插电脑，不要经过 Hub；
3. 拔插一次开发板；
4. 必要时按住 BOOT 再点 RST，进入下载模式。

## 目录建议

- 固件源码：`~/shanmao1-otto/firmware`
- 构建副本：`~/.cache/shanmao1-otto/build`
- 这个 Skill：任意路径，建议 ASCII 路径

不要在 ESP-IDF 安装目录里修改本项目的源码。
