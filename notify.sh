#!/bin/bash
# Claude Code / Codex 通知脚本 (macOS/Linux)

event="${1:-stop}"

# 读取配置
config_path="$HOME/.claude/ambient-light-config.yaml"
enable_overlay=true
enable_sound=true
enable_flash=true
overlay_color="red"
overlay_style="border"
overlay_animation="breathe"
overlay_duration=3
overlay_width=60
overlay_alpha=0.6

if [ -f "$config_path" ]; then
    enable_overlay=$(grep "enable_overlay:" "$config_path" | awk '{print $2}')
    enable_sound=$(grep "enable_sound:" "$config_path" | awk '{print $2}')
    enable_flash=$(grep "enable_flash:" "$config_path" | awk '{print $2}')
    overlay_style=$(grep -A 20 "display:" "$config_path" | grep "style:" | awk '{print $2}')
    overlay_animation=$(grep -A 20 "display:" "$config_path" | grep "animation:" | awk '{print $2}')
    overlay_duration=$(grep -A 20 "display:" "$config_path" | grep "duration:" | awk '{print $2}')
    overlay_width=$(grep -A 20 "display:" "$config_path" | grep "width:" | awk '{print $2}')

    # 根据事件获取颜色
    case "$event" in
        stop)
            overlay_color=$(grep -A 2 "stop:" "$config_path" | grep "color:" | awk '{print $2}')
            ;;
        input)
            overlay_color=$(grep -A 2 "input:" "$config_path" | grep "color:" | awk '{print $2}')
            ;;
        task_complete)
            overlay_color=$(grep -A 2 "task_complete:" "$config_path" | grep "color:" | awk '{print $2}')
            ;;
    esac
fi

# 启动氛围灯
if [ "$enable_overlay" = "true" ]; then
    python3 "$HOME/.claude/ambient-light-qt.py" \
        --color "$overlay_color" \
        --duration "$overlay_duration" \
        --style "$overlay_style" \
        --animation "$overlay_animation" \
        --width "$overlay_width" \
        --alpha "$overlay_alpha" &
fi

# 播放声音（macOS）
if [ "$enable_sound" = "true" ] && [ "$(uname)" = "Darwin" ]; then
    case "$event" in
        stop)
            afplay /System/Library/Sounds/Glass.aiff &
            ;;
        input)
            afplay /System/Library/Sounds/Ping.aiff &
            ;;
        task_complete)
            afplay /System/Library/Sounds/Tink.aiff &
            ;;
    esac
fi

# Linux 声音支持（需要 paplay）
if [ "$enable_sound" = "true" ] && [ "$(uname)" = "Linux" ]; then
    case "$event" in
        stop)
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga &
            ;;
        input)
            paplay /usr/share/sounds/freedesktop/stereo/message.oga &
            ;;
        task_complete)
            paplay /usr/share/sounds/freedesktop/stereo/bell.oga &
            ;;
    esac
fi
