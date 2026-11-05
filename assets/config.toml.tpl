version = 1

[paths]
# 默认：~/agent_workspace（Windows 展开为 C:\Users\<user>\agent_workspace）
# 作者本机自定义示例（默认注释，首次运行会询问）：
# workspace = "D:/agent_workspace"

# 能力表固定为同目录 AGENT_CAPABILITIES.md（不支持自定义路径）

[defaults]
# 挡位：suspend = local | commit | push；probe = static | live
suspend = "local"
probe = "static"

# 不设 github 开关：有 GitHub remote 即从 handoff/README.md 生成 .github/README.md
