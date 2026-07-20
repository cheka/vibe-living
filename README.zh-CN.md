# Vibe Living

**让 AI 写代码，也让自己动一动。**

Vibe Living 是一个面向 AI 编程等待时间的本地微运动伙伴。当 Codex 或 Claude Code 正在思考、执行工具且不需要输入时，它会显示一个像素风小人，示范简单的桌边动作；需要审批或回答时自动收起，任务结束后消失。

![Vibe Living 预览](plugins/vibe-living/assets/preview.png)

![Vibe Living 喝水提醒](plugins/vibe-living/assets/hydration-preview.png)

英文系统会自动显示英文界面：

![Vibe Living English preview](plugins/vibe-living/assets/preview-en.png)

[English](README.md)

> 当前为 macOS 早期版本。Apple 芯片直接使用随插件提供的原生程序；其他 Mac 架构会在首次使用时通过 Xcode Command Line Tools 构建。

## 为什么叫 Vibe Living？

Vibe Coding 改变了开发者使用时间的方式：连续输入减少，等待 Agent 思考和执行的碎片时间增加。Vibe Living 希望把这些已经存在的间隙变成站立、伸展和改变姿势的轻量提示，同时不对健康效果作诊断、治疗或预防承诺。

## 功能

- Agent 连续工作 6 秒后出现。
- 轮换小幅肩部画圈、骨盆稳定且双臂自然屈曲的坐姿转体、手腕与手指放松、安静起身和喝水提醒。
- 所有动作限定在个人工位范围内，安静、低幅度、无需器械。
- 根据 macOS 首选语言自动显示简体中文或英文；非中文环境回退英文。
- Agent 需要权限或用户输入时自动收起。
- 支持多个并行任务，不重复启动悬浮窗。
- 双击暂停 10 分钟。
- 遵循 macOS“减少动态效果”设置。
- 完全本地运行：无遥测、无网络请求、不读取代码。
- 同一套 Hooks 同时兼容 Codex 与 Claude Code。

## 环境要求

- macOS 13 或更高版本
- Apple 芯片可直接运行；Intel Mac 需要 Xcode Command Line Tools
- 支持插件生命周期 Hooks 和 `codex plugin` 命令的 Codex/ChatGPT 桌面端，或支持插件 Hooks 的 Claude Code
- 首次下载和更新时需要连接互联网

## 安装

### Codex / ChatGPT 桌面端

在终端中运行：

```bash
codex plugin marketplace add cheka/vibe-living
codex plugin add vibe-living@vibe-living
```

然后：

1. 重启桌面应用。
2. 在插件列表中确认 **Vibe Living** 已启用；如果出现提示，请检查并信任其生命周期 Hooks。
3. 新建任务，让 Agent 连续工作至少 6 秒。Agent 工作时小人应当出现；需要你审批或回答时自动隐藏；本轮任务结束后消失。

Vibe Living 会通过生命周期 Hooks 自动启动，无需在任务中输入额外命令。

### 更新

先刷新 Marketplace，再重新安装插件，以确保使用最新发布版本：

```bash
codex plugin marketplace upgrade vibe-living
codex plugin remove vibe-living@vibe-living
codex plugin add vibe-living@vibe-living
```

更新后请重启桌面应用。

### 卸载

```bash
codex plugin remove vibe-living@vibe-living
codex plugin marketplace remove vibe-living
```

第二条命令会同时移除 Vibe Living 的 Marketplace 来源。

## 使用 Claude Code 试用

当前仓库还不是可持久安装的 Claude Code Marketplace。可以用下面的命令在单次 Claude Code 会话中加载 Vibe Living：

```bash
git clone https://github.com/cheka/vibe-living.git
cd vibe-living
claude --plugin-dir "$PWD/plugins/vibe-living"
```

进入会话后，可以打开 `/hooks` 检查已注册的生命周期 Hooks。关闭该会话后插件即被卸载，克隆到本地的仓库仍会保留。

## 常见问题

- **找不到 `codex plugin`：**请升级到支持插件生命周期 Hooks 的 Codex/ChatGPT 桌面端版本。
- **小人没有出现：**请新建任务，并让 Agent 连续工作至少 6 秒。等待你输入以及本轮任务结束后，悬浮窗会按设计自动隐藏。
- **Intel Mac 无法启动：**请运行 `xcode-select --install` 安装 Xcode Command Line Tools，再新建任务。首次使用时会在本地构建原生助手。
- **Hooks 被禁用：**请在插件列表中启用 Vibe Living，并允许其生命周期 Hooks。Hook 失败不会阻断 Agent，因此禁用或失败时可能没有报错提示。

## 本地开发安装

克隆仓库，将当前目录注册为本地 Marketplace，然后安装插件：

```bash
git clone https://github.com/cheka/vibe-living.git
cd vibe-living
codex plugin marketplace add "$PWD"
codex plugin add vibe-living@vibe-living
```

## 开发

```bash
make check       # 检查清单、Python、Shell、测试和 Swift 类型
make harness     # 在隔离环境中模拟完整 Hooks 生命周期
make build       # 构建当前 Mac 架构的原生助手
make preview     # 渲染悬浮窗预览
make package     # 在 dist/ 生成发布压缩包
```

每个新需求必须先更新 `docs/specs/` 下的相关规格和验收标准，再修改实现。更多信息见[规格索引](docs/specs/README.md)、[开发指南](docs/development.md)、[架构说明](docs/architecture.md)和[贡献指南](CONTRIBUTING.md)。

## 隐私与安全提示

Vibe Living 只读取区分本地会话所需的生命周期元数据，不读取仓库文件、提示词或模型回答，也不发起网络请求。

默认动作不会包含跳跃、原地踏步、深蹲、快速甩臂或需要占用过道的活动。喝水提醒只建议在手边有水时小口慢饮，不要求离开工位。

动作仅为一般活动提示，不构成医疗建议。请在舒适范围内活动；如出现疼痛、眩晕、麻木、气短或异常不适，应立即停止。如有健康问题或活动限制，请咨询专业人士。

## 许可证

[MIT](LICENSE)
