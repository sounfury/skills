---
name: 1panel
description: >
  通过 1Panel v2 API（API Key 签名）管理用户服务器上的 1Panel：建反向代理网站、绑 SSL、
  查/启停/删网站、查证书，以及任意 Swagger 里有的接口。Use when the user mentions 1Panel,
  1panel 面板, 反代, 反向代理, 建站, 绑证书, 给某个端口加域名, or runs /1panel.
---

# 1Panel API

思路：**接口文档看面板自带 Swagger，拿 API Key 签名后直接请求。** 本 skill 只固化签名方式和几个实测过的常用操作，其它需求查 Swagger 自己拼。

## 连接方式

- 主机清单读 `~/.ssh/config`（见 ssh skill）。每台装了 1Panel 的机器上有 `~/.config/1panel.env`（树莓派沿用 `~/.codex/1panel.env`）：
  ```
  export ONEPANEL_BASE_URL=http://127.0.0.1:<面板端口>
  export ONEPANEL_API_KEY=...
  export ONEPANEL_HOST_HEADER=<面板绑定域名>   # 可选；面板设了「绑定域名」时必须，否则返回 Access Temporarily Unavailable HTML
  ```
  **Key 只放在远端，不要读出、打印或写进本机/聊天。** 缺 env 时请用户自己创建，并在面板「用户信息 → API 接口」里开启 API、把 `127.0.0.1` 加白名单。
- 调用一律走 `scripts/1p.sh`，它 ssh 到目标机、在远端用 `md5("1panel"+Key+时间戳)` 签名并 curl 本机面板：
  ```bash
  S=~/.claude/skills/1panel/scripts/1p.sh
  bash $S <ssh别名> <METHOD> <PATH> ['<JSON>' | @本地文件.json]
  ```
- 返回 JSON 的 `code` 为 200 才算成功；`message` 里是错误原因。

## 接口文档

- 权威：面板 Swagger `http://<面板地址>/1panel/swagger/index.html`（需先登录面板），和该机 1Panel 版本严格对应。
- 前缀是 `/api/v2/`；分页/列表接口通常必须带 `orderBy` + `order`，否则 400。
- 新接口先用 GET/查询类试出结构，写操作前把请求体给用户看。

## 常用操作（请求体已实测，v2.2.x）

### 查网站
```bash
bash $S oracle POST /api/v2/websites/search '{"page":1,"pageSize":100,"name":"","websiteGroupId":0,"orderBy":"created_at","order":"descending"}'
bash $S oracle GET  /api/v2/websites/<id>
bash $S oracle GET  /api/v2/websites/<id>/https
```

### 查证书（拿 websiteSSLID / acmeAccountId）
```bash
bash $S oracle POST /api/v2/websites/ssl/search '{"page":1,"pageSize":100,"name":"","acmeAccountID":""}'
```
选 `domains` 覆盖目标域名的那张（通常是泛域名证书），记下 `id` 和 `acmeAccountId`。

### 建反向代理网站 `POST /api/v2/websites`
把 `<...>` 换掉后整体发送（字段名大小写照抄，`domains` 不能为空）：
```json
{"primaryDomain":"","type":"proxy","alias":"<域名>","remark":"<备注>","appType":"installed",
 "webSiteGroupId":1,"otherDomains":"","proxy":"http://127.0.0.1:<端口>",
 "appinstall":{"appId":0,"name":"","appDetailId":0,"params":{},"version":"","appkey":"","advanced":false,
   "cpuQuota":0,"memoryLimit":0,"memoryUnit":"MB","containerName":"","allowPort":false},
 "IPV6":true,"enableFtp":false,"ftpUser":"","ftpPassword":"",
 "proxyType":"tcp","port":0,"proxyProtocol":"http://","proxyAddress":"127.0.0.1:<端口>",
 "runtimeType":"php","taskID":"","createDb":false,"dbName":"","dbPassword":"","dbFormat":"utf8mb4",
 "dbUser":"","dbType":"mysql","dbHost":"",
 "enableSSL":true,"websiteSSLID":<证书id>,"acmeAccountID":<acmeAccountId>,
 "domains":[{"domain":"<域名>","port":<该机 HTTP 端口>,"ssl":false}],"siteDir":""}
```
- `proxy` 与 `proxyProtocol`+`proxyAddress` 要一致；后端是 HTTPS 就都改成 `https://`。
- 不绑证书：`enableSSL:false, websiteSSLID:0, acmeAccountID:0`。

### 改/绑 HTTPS `POST /api/v2/websites/<id>/https`
```json
{"enable":true,"websiteSSLID":<证书id>,"acmeAccountID":<acmeAccountId>,"httpConfig":"HTTPToHTTPS",
 "httpsPort":"443","SSLProtocol":["TLSv1.3","TLSv1.2"],"algorithm":"","hsts":true,
 "hstsIncludeSubDomains":true,"http3":false}
```

### 启停 / 删除
```bash
bash $S oracle POST /api/v2/websites/operate '{"id":<id>,"operate":"stop"}'   # start / stop
bash $S oracle POST /api/v2/websites/del '{"id":<id>,"deleteApp":false,"deleteBackup":false,"forceDelete":false}'
```
删除前必须用户明确确认。

## 流程：给某端口建反代

1. `ssh <主机> 'ss -ltnp | grep :<端口>'` 确认服务在监听。
2. DNS：用 aliyun skill 先查后加 A 记录指向该机公网 IP（RR 填子域部分，如 `xxx.oci`）。
3. 查证书拿 `id`/`acmeAccountId` → 建站（一步带上证书）。
4. 核验：`websites/search` 读回新站；`curl -sI https://<域名>` 看状态码与证书。
5. 需要自定义 location（如根路径跳转）时，在 `/opt/1panel/www/sites/<域名>/proxy/` 下加 `.conf`，再 `docker exec <openresty容器> nginx -t && nginx -s reload`。

## 各主机约定

| ssh 别名 | 面板 | 域名 / 证书 | 建站 domains.port |
|---|---|---|---|
| `oracle` | v2.2.5，`127.0.0.1:18765`，绑定域名 `1panel.oci.sounfury.top`（env 已配 Host 头）；OpenResty host 网络，反代写 `127.0.0.1:<端口>` | `*.oci.sounfury.top` 证书 id 7，acmeAccountId 1（每个子域单独 A 记录 → oracle 公网 IP，无泛解析） | 80 |
| `raspberry` | `~/.codex/1panel.env`；同目录 `~/.codex/skills/openclaw-1panel` 是旧版 TS CLI（`openclaw-1panel run websites ...`） | `*.sounfury.top` / `*.nas.sounfury.top`，证书 id 8，acmeAccountId 5 | 5000 |
