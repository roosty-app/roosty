# Pre-Opensource Audit Guide

> **目的**：在仓库**首次公开**或**新 Release 发布**前，跑一遍 secret 泄漏审计，避免把 API key、token、本地密码等推到 GitHub。

---

## 何时使用

- [ ] 即将首次 `git push` 到公开 GitHub 仓库
- [ ] 即将发 GitHub Release 或上传 zip 到公开渠道
- [ ] 把仓库从 private 改成 public 之前
- [ ] 接受外部贡献者首次合并前

任何"代码即将被陌生人看到"的节点都跑一遍。**5 分钟工作量，省下被 GitHub Push Protection 踢回 / 半夜紧急 force-push 的痛苦。**

---

## 必查项

### 1. git 全历史扫常见 key 字面量

```bash
git log --all -p 2>&1 | grep -oE "sk-[a-zA-Z0-9]{20,}" | sort -u
git log --all -p 2>&1 | grep -oE "ghp_[a-zA-Z0-9]{30,}" | sort -u   # GitHub PAT
git log --all -p 2>&1 | grep -oE "AIza[A-Za-z0-9_-]{35}" | sort -u  # Google API
```

**期望**：每条都返回空。任何输出都说明历史里曾经写入过 key，需要 `git filter-repo` 清理 + 立即 rotate 那个 key。

### 2. 工作树里的 secret/local config 文件

```bash
git ls-files | grep -iE "\.env(\.|$)|secret|credential|\.local\.|config\.local"
```

**期望**：返回空。如果列出文件名 → `git rm --cached <文件>` + 检查 `.gitignore` 补规则。

### 3. .gitignore 是否真的覆盖

```bash
cat .gitignore | grep -iE "env|secret|key|local"
```

**最低要求**：`.env`、`.env.*`、`*.local`、`secrets.json`、`config.local.json`、`**/*.secret.*`。

### 4. 实际配置 / 文档里的占位符

```bash
git ls-files | xargs grep -lE "\"apiKey\":\s*\"[^\"]" 2>/dev/null
```

**期望**：要么命中 `"apiKey": ""`（空字符串占位 OK），要么不命中。**不能**命中真实 key 字符串。

---

## 为什么用户的本地 key 不会泄漏（产品侧）

Roosty 的 LLM key 存在 **Windows SharedPreferences**，路径：

```
%APPDATA%\com.example.roosty\shared_preferences.json
```

**这是系统用户目录，不在 git 工作树里**——`git status` 永远看不到它，`git add .` 也不会扫到。

但仓库里如果有人误把测试 key 硬编码进 `lib/config/llm_client.dart` 之类的源码，那是另一回事——上面 §1 的 grep 就是为了防这个。

---

## 出现泄漏怎么办

1. **立即 rotate**：去对应平台（DeepSeek / OpenAI / GitHub）撤销并重发新 key。
2. **清历史**：`pip install git-filter-repo` → `git filter-repo --replace-text passwords.txt` → 强 push（首次公开前还来得及，已经被 fork 就晚了）。
3. **复盘**：把"为什么会进 commit"写进项目 DECISIONS.md，避免下次。

---

**核心原则**：泄漏后再补救是 P0 事故，5 分钟扫描永远值。
