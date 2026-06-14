#!/usr/bin/env python3
"""
Claude Code / Codex 屏幕氛围灯 (PyQt5 版本)
支持真正的 alpha 透明渐变
"""

import argparse
import sys
import numpy as np
from PyQt5.QtWidgets import QApplication, QWidget
from PyQt5.QtCore import Qt, QTimer
from PyQt5.QtGui import QPainter, QLinearGradient, QColor, QPen

class AmbientLightQt(QWidget):
    def __init__(self, color, duration, style, animation, width, alpha):
        super().__init__()
        self.color = self._parse_color(color)
        self.duration = duration
        self.style = style
        self.animation = animation
        self.border_width = width
        self.base_alpha = alpha

        # 动画状态
        self.current_alpha = alpha
        self.alpha_direction = 1

        # 设置窗口
        self.setWindowFlags(
            Qt.WindowStaysOnTopHint |
            Qt.FramelessWindowHint |
            Qt.Tool
        )
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setAttribute(Qt.WA_TransparentForMouseEvents)

        # 全屏
        screen = QApplication.primaryScreen().geometry()
        self.setGeometry(0, 0, screen.width(), screen.height())

        # 启动动画
        if animation == "breathe":
            self.timer = QTimer()
            self.timer.timeout.connect(self._animate_breathe)
            self.timer.start(50)  # 50ms
        elif animation == "flash":
            self.timer = QTimer()
            self.timer.timeout.connect(self._animate_flash)
            self.timer.start(500)

        # 定时关闭
        if duration > 0:
            QTimer.singleShot(duration * 1000, self._quit_app)

        self.show()

    def _parse_color(self, color):
        colors = {
            "red": "#FF0000",
            "green": "#00FF00",
            "yellow": "#FFFF00",
            "blue": "#0000FF",
            "purple": "#800080",
            "cyan": "#00FFFF",
            "white": "#FFFFFF",
        }
        return colors.get(color, color)

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)

        w = self.border_width
        screen_w = self.width()
        screen_h = self.height()

        # 解析颜色
        qcolor = QColor(self.color)
        r, g, b = qcolor.red(), qcolor.green(), qcolor.blue()

        if self.style == "border":
            # 上边框
            gradient = QLinearGradient(0, 0, 0, w)
            gradient.setColorAt(0, QColor(r, g, b, int(255 * self.current_alpha)))
            gradient.setColorAt(1, QColor(r, g, b, 0))
            painter.fillRect(0, 0, screen_w, w, gradient)

            # 下边框
            gradient = QLinearGradient(0, screen_h - w, 0, screen_h)
            gradient.setColorAt(0, QColor(r, g, b, 0))
            gradient.setColorAt(1, QColor(r, g, b, int(255 * self.current_alpha)))
            painter.fillRect(0, screen_h - w, screen_w, w, gradient)

            # 左边框
            gradient = QLinearGradient(0, 0, w, 0)
            gradient.setColorAt(0, QColor(r, g, b, int(255 * self.current_alpha)))
            gradient.setColorAt(1, QColor(r, g, b, 0))
            painter.fillRect(0, 0, w, screen_h, gradient)

            # 右边框
            gradient = QLinearGradient(screen_w - w, 0, screen_w, 0)
            gradient.setColorAt(0, QColor(r, g, b, 0))
            gradient.setColorAt(1, QColor(r, g, b, int(255 * self.current_alpha)))
            painter.fillRect(screen_w - w, 0, w, screen_h, gradient)

        else:  # band
            # 上色带
            gradient = QLinearGradient(0, 0, 0, w)
            gradient.setColorAt(0, QColor(r, g, b, int(255 * self.current_alpha)))
            gradient.setColorAt(1, QColor(r, g, b, 0))
            painter.fillRect(0, 0, screen_w, w, gradient)

            # 下色带
            gradient = QLinearGradient(0, screen_h - w, 0, screen_h)
            gradient.setColorAt(0, QColor(r, g, b, 0))
            gradient.setColorAt(1, QColor(r, g, b, int(255 * self.current_alpha)))
            painter.fillRect(0, screen_h - w, screen_w, w, gradient)

    def _animate_breathe(self):
        self.current_alpha += 0.05 * self.alpha_direction
        if self.current_alpha >= 0.8:
            self.current_alpha = 0.8
            self.alpha_direction = -1
        elif self.current_alpha <= 0.3:
            self.current_alpha = 0.3
            self.alpha_direction = 1
        self.update()

    def _animate_flash(self):
        self.current_alpha = 0.0 if self.current_alpha > 0 else self.base_alpha
        self.update()

    def _quit_app(self):
        """退出整个应用"""
        QApplication.quit()

    def keyPressEvent(self, event):
        if event.key() == Qt.Key_Escape:
            QApplication.quit()

def main():
    parser = argparse.ArgumentParser(description="屏幕氛围灯通知 (PyQt5)")
    parser.add_argument("--color", default="red")
    parser.add_argument("--duration", type=int, default=3)
    parser.add_argument("--style", choices=["border", "band"], default="border")
    parser.add_argument("--animation", choices=["breathe", "flash", "static"], default="breathe")
    parser.add_argument("--width", type=int, default=60)
    parser.add_argument("--alpha", type=float, default=0.6)

    args = parser.parse_args()

    app = QApplication(sys.argv)
    window = AmbientLightQt(
        color=args.color,
        duration=args.duration,
        style=args.style,
        animation=args.animation,
        width=args.width,
        alpha=args.alpha
    )
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
