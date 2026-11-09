[paths]
# 默认：~/agent_workspace（Windows 展开为 C:\Users\<user>\agent_workspace）
# 作者本机自定义示例（默认注释；需要时手动取消注释）：
# workspace = "D:/agent_workspace"

# 能力表固定为同目录 AGENT_CAPABILITIES.md（不支持自定义路径）

[defaults]
# 挡位：suspend = local | commit | push；probe = static | live；post = new | next；doc = guard | init
# --gear <key>[=<值>] 写入挡位；--gear list 查看可写键（值非法不修改）
suspend = "local"
probe = "static"
# --doc 默认挡位：guard = 只读扫描；init = 显式创建
doc = "guard"
# --post 目标：new = 新建会话后投递；next = 投递到已有会话（必须给 --next，可填会话 ID 或会话名）
post = "new"

# 不设 github 开关：README 固定在项目根目录，GitHub 首页直接显示；不生成 .github/README.md
