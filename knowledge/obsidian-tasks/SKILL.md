---
name: obsidian-tasks
description: "为 Obsidian 的 Tasks 插件编写、整理、查询、修复任务条目与 ```tasks``` 查询块。用于用户提到 Obsidian Tasks、待办汇总、截止日期、计划日期、开始日期、重复任务、按标签或路径筛选任务、生成周视图或今日任务视图、排查 Tasks 查询无结果等场景。默认假设用户启用了全局过滤 `#task`，因此新增任务必须包含 `#task`。"
license: MIT
---

# Obsidian Tasks

优先输出可以直接粘贴到 Obsidian 的 Markdown，而不是只解释概念。

## 默认假设

- 默认假设用户启用了 Tasks 的全局过滤 `#task`。
- 任何希望被 Tasks 识别的新任务，都必须包含 `#task`。
- 新建任务时，优先把 `#task` 放在复选框后面，写成 `- [ ] #task ...`，这样更符合 Tasks 的识别和自动补全习惯。
- 除非上下文明确显示使用 Dataview Task Format，否则默认使用 Tasks Emoji Format。
- 如果上下文里已经有自定义状态，例如 `[/]`、`[-]`、`[>]`，保留它们，不要擅自改回标准状态。

## 工作方式

1. 先观察用户给出的现有任务写法、查询块写法、标签习惯和状态符号。
2. 如果用户要新增或改写任务，优先生成合法的 Tasks 任务行，而不是普通 checklist。
3. 如果用户要看板、周视图、今日视图或项目视图，优先生成 `tasks` 查询块。
4. 如果查询没有结果，先排查是否缺少 `#task`、日期格式是否非法、是否在 Reading/Live Preview 中查看、是否混用了不同 task format。

## 任务行模板

优先使用这些模板：

```md
- [ ] #task 写周报
- [ ] #task 写周报 📅 2026-05-22
- [ ] #task 准备例会 ⏳ 2026-05-22 📅 2026-05-23
- [ ] #task 预习课程 🛫 2026-05-22 ⏳ 2026-05-23 📅 2026-05-25
- [ ] #task 缴水电费 ⏫ 📅 2026-05-22
- [ ] #task 写日报 🔁 every day when done
- [ ] #task 团队例会 🔁 every week on Monday
- [ ] #task 月度复盘 🔁 every month on the 1st
```

常见字段：

- `📅 YYYY-MM-DD`: due date
- `⏳ YYYY-MM-DD`: scheduled date
- `🛫 YYYY-MM-DD`: start date
- `✅ YYYY-MM-DD`: done date
- `➕ YYYY-MM-DD`: created date
- `🔁 ...`: recurrence rule
- `⏫` `🔼` `🔽` `⏬`: priority

## 查询块规则

- 查询块使用：

````md
```tasks
not done
```
````

- 查询块中每一行默认都是 `AND`。
- 如果要写 `OR`、`AND NOT` 等组合，使用大写，并把单个条件放进括号。
- 默认不需要额外写 `tags include #task`，因为全局过滤已经替用户做了这一层筛选。
- `tags include ...` 在匹配时不会把全局过滤当成普通标签。
- `description includes ...` 检索的是清洗后的描述文本；全局过滤和日期/优先级等标记不会作为描述正文参与匹配。

## 常用查询模板

### 所有未完成任务

````md
```tasks
not done
sort by due
sort by priority
```
````

### 今天到期或已逾期

````md
```tasks
not done
due before tomorrow
sort by due
group by due
```
````

### 今天需要行动的任务

`happens` 会同时考虑 start、scheduled、due：

````md
```tasks
not done
happens before tomorrow
sort by happens
```
````

### 本周任务

````md
```tasks
not done
happens this week
sort by happens
group by folder
```
````

### 只看某个项目目录

````md
```tasks
not done
path includes Projects/Alpha
sort by due
```
````

### 只看含某个标签的任务

````md
```tasks
not done
tags include #work
sort by due
```
````

### 无日期的任务收件箱

````md
```tasks
not done
no happens date
sort by description
```
````

### 已完成任务回顾

````md
```tasks
done
done this week
sort by done reverse
```
````

### 混合布尔条件

````md
```tasks
not done
((due before tomorrow) OR (scheduled before tomorrow))
(tags include #work) OR (path includes Projects/Work)
sort by due
```
````

## 重复任务

- 优先使用自然语言 recurrence rule，例如：
  - `🔁 every day when done`
  - `🔁 every week on Monday`
  - `🔁 every month on the 1st`
- 如果用户使用自定义状态，提醒自己：重复任务只有在切换到 `DONE` 类型状态后，才会生成下一条实例。
- 如果用户要“做完后第二天再出现”，优先使用 `every day when done`，而不是固定日期的 `every day`。

## 状态与查询注意点

- `not done` 匹配 `TODO`、`IN_PROGRESS`、`ON_HOLD` 类型。
- `done` 匹配 `DONE`、`CANCELLED`、`NON_TASK` 类型。
- 如果用户的 vault 使用了自定义状态，优先按 `status.type` 理解，而不是只看符号本身。
- 如果用户要查“进行中”，优先考虑：

````md
```tasks
status.type is IN_PROGRESS
```
````

## 排错清单

当 Tasks 看起来“不工作”时，优先按这个顺序排查：

1. 任务行是否包含 `#task`。
2. 日期是否为 `YYYY-MM-DD`。
3. 查询块是否真的是 ```` ```tasks ````，而不是普通代码块。
4. 用户是否在 Reading 或 Live Preview 中看结果。
5. 是否混用了 Tasks Emoji Format 和 Dataview Task Format。
6. 是否因为路径、标签或布尔条件过严导致无结果。

可直接给出这条诊断查询，用于寻找非法日期：

````md
```tasks
(cancelled date is invalid) OR (created date is invalid) OR (done date is invalid) OR (due date is invalid) OR (scheduled date is invalid) OR (start date is invalid)
group by path
```
````

## 输出偏好

- 用户要“怎么写”时，直接给可粘贴的任务行或 `tasks` 查询块。
- 用户要“整理现有笔记”时，保留原有 Markdown 结构、链接、标签和项目路径。
- 用户没说明格式时，优先给最少但可运行的方案，再附 1 到 3 个可选变体。
- 用户提到今日、明日、本周、逾期、项目、标签、重复任务时，优先从本 skill 的模板中改写，不要从零发明语法。
