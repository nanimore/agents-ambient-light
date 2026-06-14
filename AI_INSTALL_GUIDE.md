# AI 安装指南

本文档供 AI 助手（Claude Code、Codex 等）参考，快速完成屏幕氛围灯系统的安装。

## 安装任务理解

当用户粘贴以下文本时：
- "将本项目安装到 Claude Code，配置屏幕氛围灯通知系统"
- "将本项目安装到 Codex，配置屏幕氛围灯通知系统"

需要执行完整的安装流程。

## 安装步骤（通用）

### 1. 检查 Python 环境
```bash
python --version
pip show PyQt5
```

如果 PyQt5 未安装：
```bash
pip install PyQt5
```

### 2. 克隆/下载项目
```bash
git clone <repo-url>
cd agents-ambient-light
```

### 3. 根据目标系统安装

---

## Claude Code 安装（Windows）

### 步骤 1：复制文件
```powershell
Copy-Item ambient-light-qt.py "$env:USERPROFILE\.claude\"
Copy-Item ambient-light-config.yaml "$env:USERPROFILE\.claude\"
Copy-Item notify.ps1 "$env:USERPROFILE\.claude\"
```

### 步骤 2：配置 hooks
编辑 `~/.claude/settings.json`，添加：
```json
{
  "hooks": {
    "stop": "powershell -NoProfile -File \"$env:USERPROFILE/.claude/notify.ps1\" -event stop",
    "notification": "powershell -NoProfile -File \"$env:USERPROFILE/.claude/notify.ps1\" -event input",
    "task_complete": "powershell -NoProfile -File \"$env:USERPROFILE/.claude/notify.ps1\" -event task_complete"
  }
}
```

如果 `settings.json` 已有其他配置，合并 hooks 部分。

### 步骤 3：测试
```bash
python "$env:USERPROFILE\.claude\ambient-light-qt.py" --color red --duration 3
```

---

## Codex 安装（Windows）

### 步骤 1：复制文件
```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\.codex" -Force -ErrorAction SilentlyContinue
Copy-Item ambient-light-qt.py "$env:USERPROFILE\.codex\"
Copy-Item ambient-light-config.yaml "$env:USERPROFILE\.codex\"
Copy-Item notify.ps1 "$env:USERPROFILE\.codex\"
```

### 步骤 2：更新路径
编辑 `~/.codex/notify.ps1`：

**第 4 行**：
```powershell
$configPath = "$env:USERPROFILE/.codex/ambient-light-config.yaml"
```

**第 87 行**（搜索 `ambient-light-qt.py`）：
```powershell
$ambientLightPath = "$env:USERPROFILE/.codex/ambient-light-qt.py"
```

### 步骤 3：配置 hooks
编辑或创建 `~/.codex/hooks.json`：

如果文件已存在，**添加**以下 hooks（保留已有的 EMDASH hooks）：
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File \"$env:USERPROFILE\\.codex\\notify.ps1\" -event stop",
            "timeout": 10
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -File \"$env:USERPROFILE\\.codex\\notify.ps1\" -event input",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

**重要**：
- 如果 `hooks.json` 已有 `Stop` 或 `PermissionRequest` hooks，在其 `hooks` 数组中**追加**新的 hook，不要覆盖
- 每个事件可以有多个 hooks，它们会按顺序执行

### 步骤 4：测试
```bash
python "$env:USERPROFILE\.codex\ambient-light-qt.py" --color red --duration 3
```

---

## macOS/Linux 安装

### Claude Code
```bash
# 复制文件
cp ambient-light-qt.py ~/.claude/
cp ambient-light-config.yaml ~/.claude/
cp notify.sh ~/.claude/
chmod +x ~/.claude/notify.sh

# 配置 hooks（编辑 ~/.claude/settings.json）
{
  "hooks": {
    "stop": "~/.claude/notify.sh stop",
    "notification": "~/.claude/notify.sh input",
    "task_complete": "~/.claude/notify.sh task_complete"
  }
}

# 测试
python3 ~/.claude/ambient-light-qt.py --color red --duration 3
```

### Codex
```bash
# 复制文件
mkdir -p ~/.codex
cp ambient-light-qt.py ~/.codex/
cp ambient-light-config.yaml ~/.codex/
cp notify.sh ~/.codex/
chmod +x ~/.codex/notify.sh

# 更新 notify.sh 中的路径
sed -i 's|/.claude/|/.codex/|g' ~/.codex/notify.sh

# 配置 hooks（编辑 ~/.codex/hooks.json）
# 同 Windows，但使用 bash 命令
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.codex/notify.sh stop",
            "timeout": 10
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.codex/notify.sh input",
            "timeout": 10
          }
        ]
      }
    ]
  }
}

# 测试
python3 ~/.codex/ambient-light-qt.py --color red --duration 3
```

---

## 验证安装

### 1. 测试脚本运行
应该看到 3 秒钟的红色氛围灯。

### 2. 重启 AI 助手
重启 Claude Code 或 Codex，使 hooks 配置生效。

### 3. 触发测试
- 发送一条消息给 AI
- AI 回复完成后，应看到氛围灯效果

### 4. 验证颜色映射
- **Claude Code**：
  - AI 完成 → 🔴 红色
  - 等待输入 → 🟡 黄色
  - 任务完成 → 🟢 绿色

- **Codex**：
  - AI 完成 → 🔴 红色
  - 请求权限 → 🟡 黄色

---

## 故障排查

### 问题：没有看到氛围灯
1. 检查 Python 和 PyQt5 是否安装
2. 手动运行测试命令，查看错误信息
3. 检查 hooks 配置文件路径是否正确
4. 确认 AI 助手已重启

### 问题：Codex hooks 不生效
1. 检查 `hooks.json` 格式是否正确（JSON 语法）
2. 确认没有覆盖已有的 EMDASH hooks
3. 查看 Codex 日志是否有 hook 执行错误

### 问题：路径错误
- Windows 使用 `\` 或 `\\`：`$env:USERPROFILE\.codex\file.ps1`
- macOS/Linux 使用 `/`：`~/.codex/file.sh`

---

## 安装完成确认

向用户报告：

```
✅ 屏幕氛围灯系统安装完成！

已配置：
- Python 脚本：ambient-light-qt.py
- 配置文件：ambient-light-config.yaml
- 集成脚本：notify.ps1 / notify.sh
- Hooks：[列出配置的 hooks]

测试通过：
- [✓] 脚本可以独立运行
- [✓] Hooks 配置已生效

下次我回复时，你将看到屏幕边缘的彩色氛围灯！🎨✨

可自定义：编辑 ambient-light-config.yaml 调整颜色、宽度、动画等。
```
