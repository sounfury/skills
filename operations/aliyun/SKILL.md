---
name: aliyun
description: >
  用本机阿里云 CLI 管理该账号资源，默认做云解析 DNS（查/加/改/删/暂停记录），
  也可调 ECS、OSS、域名、CDN 等其它 OpenAPI。Use when the user mentions 阿里云,
  aliyun, 云解析, DNS解析, 解析记录, 添加A记录, CNAME, 域名解析, sounfury.top,
  阿里云ECS, OSS, 或 runs /aliyun.
triggers:
  - 阿里云
  - aliyun
  - 云解析
  - DNS解析
  - 解析记录
  - 添加A记录
  - CNAME
  - 域名解析
  - sounfury.top
  - 阿里云ECS
  - OSS
---

# 阿里云资源（aliyun）

本机已装官方 CLI，凭证在 `%USERPROFILE%\.aliyun\config.json`（profile `default`）。
**不要把 AccessKey 写进 skill、聊天或日志。** 密钥只活在那份 config。

权威入口：`C:\Users\Administrator\.grok\skills\aliyun\SKILL.md`

## 固定参数

| 项 | 值 |
|----|----|
| CLI | `%LOCALAPPDATA%\AliyunCLI\aliyun.exe`（3.4.11+） |
| Profile | `default`，region `cn-hangzhou`，language `zh` |
| 账号 | 主账号 `1268985673689163`（`sts GetCallerIdentity` 的 AccountId） |
| 已知域名 | `sounfury.top`（免费版云解析，NS `dns21/22.hichina.com`，阿里云注册） |
| Helper | `C:\Users\Administrator\.grok\skills\aliyun\scripts\aliyun.ps1` |

本机不一定有 `pwsh`，用 `powershell`。CLI 不在当前 PATH 时直接跑 helper（它会自己找 `aliyun.exe`）。

```powershell
$ali = "$env:USERPROFILE\.grok\skills\aliyun\scripts\aliyun.ps1"
powershell -NoProfile -File $ali whoami
powershell -NoProfile -File $ali domains
powershell -NoProfile -File $ali records sounfury.top
```

## 铁律

1. **先查后改。** 写操作前必须拉当前记录，用 `RecordId` 改/删，不要猜。
2. **写操作必须用户明确要求**（加/改/删/暂停解析，或创建/释放其它资源）。只说「看一下」就只读。
3. **主机记录填 RR，不要填 FQDN。** `nas.sounfury.top` → DomainName=`sounfury.top`，RR=`nas`。根域 RR=`@`。多级如 `1panel.nas.sounfury.top` → RR=`1panel.nas`。
4. **同 RR + 同线路下 CNAME 与 A/AAAA/MX/TXT 冲突。** `@` 上已有 CNAME，不要再往 `@` 加 A/AAAA。
5. 免费版 TTL 最小 **600**。默认线路用 `default`。MX 必须带 `Priority`（1–50，越小越高）。
6. 不要动 Google 站点验证 TXT（`google-site-verification=...`），除非用户点名。
7. 改完立刻再查一遍同一条记录，把新旧值回报用户。公网生效还受 TTL 缓存影响。
8. 解析不确定主域名时先 `GetMainDomainName`。账号下目前只有 `sounfury.top`，未点名就用它。

## 工作流：DNS

### 查

```powershell
powershell -NoProfile -File $ali domains
powershell -NoProfile -File $ali records sounfury.top
powershell -NoProfile -File $ali records sounfury.top -RR nas
powershell -NoProfile -File $ali subdomain nas.sounfury.top
powershell -NoProfile -File $ali info -RecordId 1944450472887261184
powershell -NoProfile -File $ali ns sounfury.top
```

用户说某个主机名时，先 `records`/`subdomain` 看现有 Type/Value/RecordId/Status。

### 加 / 改 / 删 / 暂停

用户明确要求后：

```powershell
# 新增
powershell -NoProfile -File $ali add sounfury.top -RR www -Type A -Value 1.2.3.4
powershell -NoProfile -File $ali add sounfury.top -RR www -Type AAAA -Value 2408:8215:4042:e8e0:6aea:e5e4:9a66:47c4
powershell -NoProfile -File $ali add sounfury.top -RR blog -Type CNAME -Value example.cdn.com
powershell -NoProfile -File $ali add sounfury.top -RR '@' -Type MX -Value mx1.qiye.aliyun.com -Priority 5
powershell -NoProfile -File $ali add sounfury.top -RR _acme-challenge -Type TXT -Value 'xxxx'

# 改（必须带现有 RecordId，且 RR/Type/Value 都要传）
powershell -NoProfile -File $ali update -RecordId <id> -RR nas -Type AAAA -Value <new>

# 暂停 / 启用
powershell -NoProfile -File $ali status -RecordId <id> -Status Disable
powershell -NoProfile -File $ali status -RecordId <id> -Status Enable

# 删
powershell -NoProfile -File $ali delete -RecordId <id>
```

同一 RR+Type+Line 已存在 → **update**，不要再 add（会重复或冲突）。
「把 nas 指到新 IP」= 查到 RecordId 后 update，不是先删后加。

### 常见意图

| 用户说法 | 做法 |
|----------|------|
| 查/列出解析 | `records`，按 RR 过滤 |
| `xxx.sounfury.top` 指到 IPv4 | Type=`A` |
| 指到 IPv6 | Type=`AAAA`（现有 nas 系记录多数是这个） |
| 指到别的域名 / CDN / Vercel | Type=`CNAME`，Value 不要带 `http://` |
| 证书验证 | Type=`TXT`，RR 用平台给的（常是 `_acme-challenge` / `_dnsauth`） |
| 暂时关掉 | `status Disable`，不要删 |
| 邮箱 | MX + 厂商要求的 CNAME/TXT，按厂商文档 |

记录类型、线路码、冲突规则：读 `references/dns.md`。

## 其它云产品

DNS 以外走同一 CLI，产品码见 `references/products.md`。

```powershell
powershell -NoProfile -File $ali run sts GetCallerIdentity
powershell -NoProfile -File $ali run ecs DescribeInstances --RegionId cn-hangzhou
powershell -NoProfile -File $ali run domain QueryDomainList --PageNum 1 --PageSize 20
# 参数不明先看帮助
& "$env:LOCALAPPDATA\AliyunCLI\aliyun.exe" help ecs
& "$env:LOCALAPPDATA\AliyunCLI\aliyun.exe" help ecs DescribeInstances
```

先 List/Describe，再对用户点名的资源动手。创建/释放/改配置同样要明确授权。

未知产品：`aliyun help` 找产品码，再 `aliyun help <product> <Action>`。元数据没有的接口加 `--force --version <日期> --endpoint <host>`。

## 凭证坏了时

`configure list` 显示 Invalid，或 API 报 `InvalidAccessKeyId` / `SignatureDoesNotMatch`：

1. 不要把密钥贴进聊天。
2. 让用户在 RAM 控制台建新 AK，然后本机执行（密钥只进命令，不进 skill）：

```powershell
& "$env:LOCALAPPDATA\AliyunCLI\aliyun.exe" configure set --profile default --mode AK --access-key-id <ID> --access-key-secret <SECRET> --region cn-hangzhou --language zh
```

3. 再 `whoami` 验证。

CLI 丢失则重新下载 `https://aliyuncli.alicdn.com/aliyun-cli-windows-latest-amd64.zip`，解压 `aliyun.exe` 到 `%LOCALAPPDATA%\AliyunCLI`。
