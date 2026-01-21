# 学生日历 App

> 一款专为大学生设计的时间管理工具：将「课程表」与「个人日程」统一在一个日历中，支持拖拽调整、冲突检测、OCR 导入，助你高效安排学习与生活。

[![Flutter](https://img.shields.io/badge/Flutter-3.38.5-blue?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/github/license/LegendPei/calendar)](LICENSE)

## 🌟 核心功能

- **课程表 + 日程一体化**  
  在同一视图中查看课程与个人日程，避免时间冲突。
- **智能冲突检测**  
  创建日程或课程时，自动检测时间重叠，并提供处理建议。
- **OCR 拍照导入课表**  
  支持从课表截图一键识别并导入课程（在线 + 离线双引擎）。
- **灵活周次系统**  
  完整支持单周、双周、连续周课程安排，自动计算“第几周”。
- **标准 iCalendar 支持**  
  导入/导出 `.ics` 文件，与 Google Calendar、Outlook 等互通。
- **农历 & 节气显示**  
  月视图中显示农历日期、节气、传统节日（1900–2100 年）。
- **多端同步**  
  支持订阅远程日历（如节假日日历），后台自动同步。

## 🛠 技术栈

| 类别         | 技术选型                     |
|--------------|------------------------------|
| 跨平台框架   | Flutter 3.38.5               |
| 状态管理     | Riverpod 2.4.0               |
| 本地数据库   | SQLite (sqflite)             |
| OCR 引擎     | 阿里云 OCR（在线） + Google ML Kit（离线） |
| 通知系统     | flutter_local_notifications  |
| 架构         | Clean Architecture           |
| CI/CD        | GitHub Actions（格式检查、静态分析、单元测试、覆盖率） |



## 🧪 如何运行

确保已安装 [Flutter SDK](https://flutter.dev/docs/get-started/install)。

```bash
# 克隆项目
git clone https://github.com/LegendPei/calendar.git
cd calendar

# 安装依赖
flutter pub get

# 运行（连接 Android/iOS 设备或模拟器）
flutter run
