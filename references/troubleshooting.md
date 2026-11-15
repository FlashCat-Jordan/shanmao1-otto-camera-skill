# 常见故障排查

## 1. 编译报 picolibc.specs

```text
cannot read spec file '.../picolibc.specs'
```

原因：源码路径含中文/非 ASCII。

解决：

```bash
bash scripts/prepare-ascii-build.sh /path/to/firmware
```

或复制到 `~/shanmao1-otto/firmware` 再构建。

## 2. Python 环境不一致

```text
python is currently active ... project was configured with python3
```

解决：

```bash
idf.py fullclean
idf.py build
```

## 3. 串口不存在

```text
/dev/cu.usbmodem* not found
```

- 换能传数据的 USB-C 线；
- 直接插 Mac，不要过 Hub；
- 换 USB 口；
- 拔插开发板；
- 仍无：按住 BOOT，点 RST，再松开 BOOT。

## 4. USB 设备在但串口不出现

macOS `ioreg` 能看到 Espressif，但 `/dev/cu.usbmodem*` 没有：

- 拔插一次；
- 换数据线；
- 复位；
- 不要反复 `esptool`，先恢复串口节点。

## 5. LEDC / GPIO 冲突

```text
GPIO x is not usable, maybe conflict with others
```

常见原因：`AttachServos()` 被重复调用，重复占用同一批 LEDC/GPIO。

检查：

- `Otto::Init()` 是否已经 Attach；
- `ActionTask` 是否又 Attach 一次；
- 删掉重复挂载，不要靠改 GPIO 绕过。

## 6. 舵机不动

按顺序排查：

1. 串口是否有 `执行动作`；
2. 动作队列是否收到；
3. 是否重复 AttachServos；
4. 舵机供电/电池是否足够；
5. 机械是否卡住；
6. 限位是否超范围。

不要直接用大角度测试堵转。

## 7. 摄像头方向反了

不要同时改三个地方：

- `hmirror`；
- `vflip`；
- 预览旋转。

先确认是 180° 倒置、镜像还是 90°。GC2145 在不同批次可能需要单独处理。

## 8. 摄像头一直显示画面

说明固件里有 **连续预览/视觉任务**，不是普通拍照逻辑。

- 检查是否引入了手势识别/视觉任务；
- 普通 `self.camera.take_photo` 只应在拍照时显示预览；
- 不要把手势识别分支刷进普通双眼睛固件。

## 9. 配网后屏幕出现小图标

配网提示可能调用：

```cpp
Alert(..., "gear", ...)
```

如果 `gear` 没有 GIF，会回退成小图标。可在 board display 中把 `gear` 映射为 `neutral`。

## 10. 唤醒词不生效

- 当前模型是否包含目标词；
- 是否只改了 Kconfig 但没更新 `model` 分区；
- `sdkconfig` 是否仍选中旧模型；
- 串口是否打印 `Set WakeNet Model`；
- 自定义“你好闪猫”需要训练模型，不能用拼音直接替换。

## 11. 麦克风听不清

先测原始电平，不要直接加增益：

- 如果 RMS 很低：硬件/增益问题；
- 如果 peak 经常 `32767`：削顶，应该减增益，不是加；
- NS 可能降低识别率；
- 双工 I2S 输入/输出采样率必须一致。

## 12. 完整烧录后 Wi-Fi 丢了

完整 `merged-binary.bin` 从 `0x0` 写会覆盖 NVS。

解决：

- 只刷 app；
- 或先备份 `0x9000` 的 NVS，刷完再恢复；
- 备份大小按实际分区表确认。

## 13. 改了模型/表情但没生效

检查是否只刷了 app：

- 唤醒词 → model 分区；
- GIF/提示音/语言 → assets 分区；
- 两者都不会随 app 自动更新。
