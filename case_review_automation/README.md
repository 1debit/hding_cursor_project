# 📊 Case Review Automation

## 🎯 项目概述

**风险案例审查自动化工具** - 为Chime风险团队提供高效的案例审查流程自动化解决方案。

## 🚀 核心功能

### 1. 批量用户分析
- 支持多用户ID批量输入
- 自动从GitHub仓库获取最新SQL查询
- 智能替换用户ID参数

### 2. Snowflake数据集成
- 使用外部浏览器SSO认证
- 连接Chime RISK_WH仓库
- 支持PII角色权限

### 3. 智能数据处理
- 自动处理UPPERCASE列名
- 去除时间戳时区信息
- 数据格式标准化

### 4. Excel报告生成
- 多用户分表输出
- 专业格式化和样式
- 自动列宽调整和冻结窗格

## 🛠️ 技术架构

### 数据库连接
```python
connection_params = {
    'account': 'chime',
    'user': 'HAO.DING@CHIME.COM',
    'authenticator': 'externalbrowser',
    'warehouse': 'RISK_WH',
    'role': 'SNOWFLAKE_PROD_ANALYTICS_PII_ROLE_OKTA'
}
```

### 核心依赖
- `snowflake.connector` - 数据库连接
- `pandas` - 数据处理
- `openpyxl` - Excel文件操作
- `PyGithub` - GitHub API集成

## 📁 项目结构

```
case_review_automation/
├── python_scripts/           # Python脚本
│   └── case_review_automation.py
├── sql_queries/              # SQL查询文件
│   └── case_review_query.sql
├── output/                   # 输出文件目录
└── README.md                 # 项目说明
```

## 🚦 使用方法

### 1. 环境准备
```bash
pip install snowflake-connector-python pandas openpyxl PyGithub
```

### 2. 配置认证
- 确保有Chime Snowflake访问权限
- 配置GitHub Personal Access Token（环境变量）

### 3. 运行脚本
```bash
python case_review_automation.py
```

### 4. 输入参数
- 用户ID列表（逗号分隔）
- 输出目录路径
- 报告格式选项

## 📊 输出格式

### Excel文件结构
- **文件名**: `YYYYMMDD_Case_Review_cursor.xlsx`
- **工作表**: 每个用户一个工作表
- **列字段**: 
  - timestamp, merchant_name, type, amt
  - description, card_type, decision
  - decline_resp_cd, vrs, rules_denied
  - is_disputed, id

### 格式特性
- 专业表头样式（深蓝色背景，白色字体）
- 自动列宽调整
- 冻结首行窗格
- 数据行交替颜色

## 🔄 工作流程

1. **输入阶段**: 接收用户ID列表
2. **查询阶段**: 从GitHub获取SQL，连接Snowflake
3. **处理阶段**: 数据清洗和格式化
4. **输出阶段**: 生成Excel报告
5. **缓存阶段**: 保存结果避免重复查询

## 🎯 应用场景

- **日常风险审查**: 批量处理高风险用户案例
- **合规审计**: 生成标准化审查报告
- **数据分析**: 为机器学习模型提供训练数据
- **团队协作**: 统一报告格式，提高工作效率

## 🚨 注意事项

- 确保网络连接稳定（Snowflake SSO认证）
- 大量数据处理时注意内存使用
- 定期清理缓存文件
- 遵循Chime数据安全政策

## 🔮 未来规划

- [ ] 添加Web界面
- [ ] 集成机器学习风险评分
- [ ] 支持更多数据源
- [ ] 实时监控和告警

---

*项目状态: 开发中 | 最后更新: 2025年8月19日*
