# 云解析 Alidns（2015-01-09）

产品码：`alidns`。RPC。常规 endpoint：`alidns.aliyuncs.com`，region 用 `cn-hangzhou`。

主域名拆分：`aliyun alidns GetMainDomainName --InputString nas.sounfury.top`

## 记录操作

| 动作 | API | 必填 |
|------|-----|------|
| 列域名 | `DescribeDomains` | |
| 域名详情 | `DescribeDomainInfo` | `DomainName` |
| NS | `DescribeDomainNs` | `DomainName` |
| 列记录 | `DescribeDomainRecords` | `DomainName`；可选 `RRKeyWord` `Type` `ValueKeyWord` `Line` `Status` `PageSize`(≤500) |
| 按子域列 | `DescribeSubDomainRecords` | `SubDomain`（FQDN，如 `nas.sounfury.top`） |
| 单条 | `DescribeDomainRecordInfo` | `RecordId` |
| 加 | `AddDomainRecord` | `DomainName` `RR` `Type` `Value`；可选 `TTL` `Line` `Priority` |
| 改 | `UpdateDomainRecord` | `RecordId` `RR` `Type` `Value`；可选 `TTL` `Line` `Priority` |
| 删 | `DeleteDomainRecord` | `RecordId` |
| 启停 | `SetDomainRecordStatus` | `RecordId` `Status`=`Enable`\|`Disable` |
| 操作日志 | `DescribeRecordLogs` | `DomainName` |

`UpdateDomainRecord` 不能只改 Value：RR/Type/Value 都要带上（用查询结果填）。

## Type

| Type | Value |
|------|--------|
| `A` | IPv4 |
| `AAAA` | IPv6 |
| `CNAME` | 另一域名，不要带协议/路径 |
| `MX` | 邮件主机，必须 `Priority` 1–50 |
| `TXT` | 验证/SPF 等，≤512 字符 |
| `NS` | 子域委派；根域 `@` 不能用 NS 托管 |
| `SRV` | `优先级 权重 端口 目标` |
| `CAA` | `0 issue "ca.example.com"` |
| `REDIRECT_URL` / `FORWARD_URL` | 显性/隐性 URL，目标不能是 IP；免费版不保证 SLA |
| `ALIAS` | 仅旗舰/尊享，本账号免费版不可用 |

同主机 + 同线路：CNAME 与几乎所有其它类型冲突。`@` 已有 CNAME 时不要再加 A/AAAA。

## Line（常用）

`default`（必留一条兜底）、`telecom`、`unicom`、`mobile`、`oversea`、`edu`。
完整枚举：`DescribeSupportLines --DomainName <域>`。

## TTL

本账号 `sounfury.top` 是免费版：默认且最小 **600** 秒。不要传更小的值。

## 已知 zone 取向（以 API 为准，此表会过期）

`sounfury.top` 上常见主机：

- CNAME：`@` → 太航/静态站；`blog`；`comments` → vercel
- AAAA → 树莓派 IPv6 `2408:8215:4042:e8e0:6aea:e5e4:9a66:47c4`：`nas`、`1panel.nas`、`webui.nas`、`clash`、`ddns`、`alist`、`ccs`、`ccc`、`sub`、`test`、`vscode`、`gopeed`
- `pc` / `ipv6` → 另一组家庭宽带地址
- `@` TXT：Google 站点验证，勿删

改这些记录前先 `records` 取当前 `RecordId`。
