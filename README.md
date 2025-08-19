# Hao Ding's Cursor Projects

这个仓库包含了我在Chime工作期间使用Cursor IDE开发的各种数据分析、机器学习和自动化项目。

## 🚀 项目总览

### 📊 [Case Review Automation](./case_review_automation/)
**风险案例审查自动化工具**
- 自动化案例审查流程，提高风险分析效率
- 集成Snowflake数据库，支持批量用户分析
- 生成格式化的Excel报告，包含多用户数据

### �� [DWN Analysis](./dwn_analysis/)
**Darwinium设备智能分析工具**
- 会话重放攻击检测分析
- 设备智能信号分析
- Nonce验证失败调查

### �� [Experiment Analysis](./experiment_analysis/)
**实验分析工具集**
- A/B测试功效分析
- 统计建模和假设检验
- 实验结果分析和报告生成

### 🎭 [Session Replay Simulation](./session_replay_simulation/)
**会话重放模拟工具**
- 模拟和分析会话重放攻击场景
- 包含Snowflake SQL查询和分析脚本

## 🛠️ 技术栈

- **Python 3.8+** - 主要开发语言
- **Snowflake** - 数据仓库和分析
- **pandas, numpy, matplotlib** - 数据处理和可视化
- **GitHub API** - 代码仓库集成
- **Excel自动化** - 报告生成和格式化

## 🚦 快速开始

1. **克隆仓库**
   ```bash
   git clone https://github.com/1debit/hding_cursor_project.git
   cd hding_cursor_project
   ```

2. **安装依赖**
   ```bash
   pip install -r requirements.txt
   ```

3. **配置Snowflake连接**
   - 确保有Chime Snowflake访问权限
   - 使用外部浏览器SSO认证

4. **运行项目**
   - 进入相应项目目录
   - 查看README了解具体使用方法

## 📁 项目结构

```
hding_cursor_project/
├── 📊 case_review_automation/          # 案例审查自动化
├── 🔍 dwn_analysis/                    # Darwinium分析
├── 🧪 experiment_analysis/             # 实验分析
├── 🎭 session_replay_simulation/       # 会话重放模拟
├── 📚 README.md                        # 项目说明
└── 🚫 .gitignore                       # Git忽略文件
```

## 🔐 安全说明

- 所有敏感信息（如API密钥、数据库密码）已从代码中移除
- 使用环境变量或配置文件存储敏感信息
- 遵循Chime的安全最佳实践

## 🤝 贡献指南

这是我在Chime的个人项目仓库，主要用于：
- 数据分析和风险建模
- 机器学习工作流程
- 自动化工具开发
- 知识管理和文档化

## 📞 联系方式

- **开发者**: Hao Ding
- **公司**: Chime
- **邮箱**: HAO.DING@CHIME.COM

---

*最后更新: 2025年8月19日*
