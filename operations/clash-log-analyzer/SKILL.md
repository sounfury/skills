---
name: clash-log-analyzer
description: 分析 Clash 日志，提取域名并自动将其分类到当前项目的代理规则列表中。如果无法确定合适的列表或该域名更适合独立为一个新列表，在添加前主动询问用户。
---

# 分析 Clash 日志并添加规则 (clash-log-analyzer)

本技能用于从 mihomo-party 日志中提取被"漏网之鱼"命中的域名，构建分类映射表后由用户确认，再写入对应的 `.list` 文件。

---

## 项目固定信息

- **日志文件路径**：`C:\Users\Administrator\AppData\Roaming\mihomo-party\logs\core-<YYYY-MM-DD>.log`
  - 默认读取今日日志，日期从系统时间中获取
- **规则列表目录**：`d:\clash-git\sounfury-Clash_rules\list\`
- **提取脚本**：`C:\Users\Administrator\.gemini\antigravity\skills\clash-log-analyzer\scripts\extract_leaky_domains.ps1`

---

## 触发标志

以下任意情况下触发本技能：
1. 用户粘贴了包含 `match Match using 🐟 漏网之鱼` 的日志文本片段
2. 用户说"分析今天的漏网之鱼日志"或类似意图

---

## 执行步骤

### 第 1 步：获取域名列表

**情况 A：用户直接粘贴了日志文本**
- 直接从粘贴内容中提取所有含 `match Match using 🐟 漏网之鱼` 的行
- 正则提取域名：`--> ([^\s:]+):端口 match Match`

**情况 B：用户要求从日志文件分析**
- 运行提取脚本（PowerShell）：
  ```powershell
  # 今日日志（默认）
  & "C:\Users\Administrator\.gemini\antigravity\skills\clash-log-analyzer\scripts\extract_leaky_domains.ps1"

  # 指定日期
  & "...extract_leaky_domains.ps1" -Date "2026-03-15"

  # 指定完整路径
  & "...extract_leaky_domains.ps1" -LogPath "C:\...\core-xxx.log"
  ```
- 脚本会自动去重、排序后输出不重复的域名列表

**无论哪种情况，都需要对提取到的域名做去重处理，纯 IP 地址（包括 IPv4 和 IPv6）直接忽略，不加入列表。**

---

### 第 2 步：分析现有规则列表

在分类前，先了解各个 `.list` 的作用：
- **`proxy.list`** → 代理（国外通用网站，不在其他专项分类中的）
- **`direct.list`** → 直连（国内访问、Steam 下载 CDN、Bitwarden 等需要直连的域名）
- **`ai.list`** → AI 工具（ChatGPT、Claude、OpenAI、Copilot 等 AI 服务）
- **`Spotify.list`** → Spotify 音乐相关
- **`Emby.list`** → Emby 媒体服务相关
- **`sexy.list`** → 成人内容相关（由 `🥵 不许涩涩` 分组控制）
- **`low.list`** → 低倍率流量（大文件下载等）
- **`env-repo.list`** → 开发环境/软件仓库（包管理器镜像等）

可以用 `view_file` 查看具体内容来辅助判断边界。

---

### 第 3 步：构建映射表格（⚠️ 必须先展示，再写入）

对提取到的每个不重复域名逐一分析，**生成如下格式的 Markdown 表格**后，立即展示给用户：

```markdown
| 域名 | 建议归属 list | 理由 | 状态 |
|------|-------------|------|------|
| mapify.so | proxy.list | AI 效率工具，非专项分类 | ✅ 建议添加 |
| detectportal.firefox.com | direct.list | Firefox 网络检测接口，应直连 | ✅ 建议添加 |
| dellupdater.dell.com | proxy.list | Dell 更新服务，需代理访问 | ✅ 建议添加 |
| sdk.split.io | proxy.list | 功能标志服务（Termius 使用） | ✅ 建议添加 |
| content-signature-2.cdn.mozilla.net | ❓ 待确认 | Mozilla CDN，可直连也可代理 | ⚠️ 需用户决定 |
| 1panel.nas.sounfury.top | ❓ 待确认 | 用户自有 NAS 服务器，建议建专项或加直连 | ⚠️ 需用户决定 |
```

**状态说明**：
- `✅ 建议添加`：分类明确，等待用户整体确认后写入
- `⚠️ 需用户决定`：分类模糊，或适合独立建 list，**单独等待用户针对此条目给出指令后才处理**

---

### 第 4 步：等待用户确认

展示完表格后，询问：

> 以上是本次分析的域名映射表，你可以：
> 1. 回复"全部确认"直接按表格写入所有 `✅` 条目
> 2. 修改某条域名的目标 list（如"把 xxx 改加到 direct.list"）
> 3. 跳过某条（如"跳过 detectportal.firefox.com"）
> 4. 对 `⚠️` 条目给出你的决定

---

### 第 5 步：执行写入

用户确认后，按以下规则写入：

1. **格式参考与前缀合并**：
   - 尽量走前缀匹配（如归纳多个子域名到一个父级域名：`a.test.com` 和 `b.test.com` 归并为 `DOMAIN-SUFFIX,test.com`）
   - 如果是特定单个主机用 `DOMAIN,sub.domain.com`，通用后缀用 `DOMAIN-SUFFIX,domain.com`
2. **写入位置**：追加到文件末尾，或根据已有分组结构插入合适位置，并可根据需要加上注释
3. **写入完成后**：输出最终报告，列出每条写入结果

---

### 第 6 步：输出报告

```
✅ 写入完成！本次共处理 N 个域名：
- mapify.so → proxy.list（新增）
- detectportal.firefox.com → direct.list（新增）
- dellupdater.dell.com → proxy.list（新增）
- sdk.split.io → proxy.list（新增）
⏩ 已跳过：content-signature-2.cdn.mozilla.net
⚠️ 待用户决定：1panel.nas.sounfury.top（未写入）
```

---

### 第 7 步：推送到远程

在确保所有文件的修改都已写入且用户对结果满意之后：
1. 运行 `git add .`将所有更新进入暂存区
2. 运行 `git commit -m "漏网之鱼更新"`（强制使用此 Commit message）
3. 运行 `git push` 将改动推送到远程仓库

---

## 核心原则

| 原则 | 说明 |
|------|------|
| **先表格后写入** | 每次操作前必须展示映射表格，用户确认后才可写入 |
| **提取要干净** | IP 地址不加入，去重，只取域名部分 |
| **先问后写** | `⚠️` 条目不可自行决定，必须等用户明确给出指令 |
| **前缀合并** | **尽量将多个同根且同逻辑的子域名合并为一个 `DOMAIN-SUFFIX` 规则** |
| **格式一致** | 按目标 list 的既有格式写入，复杂项需配以注释 |
| **完成即推送** | 写入完成后必须执行 Git 提交 `漏网之鱼更新` 并推送 |
| **全程中文** | 所有对话和报告使用中文 |
