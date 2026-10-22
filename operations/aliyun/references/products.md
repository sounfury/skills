# 其它产品（非 DNS）

一律：`aliyun <product> <Action> --Param value`  
或 helper：`aliyun.ps1 run <product> <Action> --Param value`

参数不明：`aliyun help <product>` / `aliyun help <product> <Action>`。

| 产品码 | 用途 | 先查再动 |
|--------|------|----------|
| `sts` | 身份 | `GetCallerIdentity` |
| `alidns` | 云解析 | 见 `dns.md` |
| `domain` | 域名注册/信息 | `QueryDomainList` `QueryDomainByDomainName` |
| `ecs` | 云服务器 | `DescribeRegions` `DescribeInstances` |
| `vpc` | 专有网络 | `DescribeVpcs` `DescribeVSwitches` |
| `ecs`/`vpc` | 安全组 | `DescribeSecurityGroups` `DescribeSecurityGroupAttribute` |
| `slb` | 传统负载均衡 | `DescribeLoadBalancers` |
| `alb` | 应用型负载均衡 | `ListLoadBalancers` |
| `oss` | 对象存储 | `aliyun oss ls`（独立子命令，不是 RPC Action） |
| `cdn` | CDN | `DescribeUserDomains` |
| `cas` | SSL 证书 | `ListUserCertificateOrder` |
| `ram` | 用户/策略/AK | `ListUsers` `ListPolicies` |
| `cms` | 云监控 | `DescribeMetricList` |
| `pvtz` | 内网 PrivateZone | `DescribeZones` |

OSS 是例外：

```
aliyun oss ls
aliyun oss ls oss://bucket/
```

创建/释放实例、改安全组、删 Bucket 等写操作必须用户点名。Region 以资源所在为准，不要默认死用 `cn-hangzhou`（DNS 除外）。
