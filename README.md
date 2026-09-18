# LumiTrail · 光影随行

用 Flutter 构建的拍照指导与穿搭推荐客户端，让旅途中的光影与穿搭更合拍。

**仓库名：`lumitrail-app` · 维护者：`qiaoshengix` · 当前版本：`1.0.2+3`**

## 功能

- **账号与登录**：注册、登录、本地登录态保存与退出。
- **拍照指导**：拍照或选择图片，上传至业务 API，展示画面特征、姿势、滤镜和拍摄角度建议。
- **穿搭推荐**：获取景点信息，提交衣橱选项，展示搭配建议。
- **个人中心**：昵称展示与账号退出。
- **统一界面**：Material 3 风格，拍照 / 穿搭 / 我的三栏导航。

本仓库仅包含 Flutter App 与 Android 工程。分析和推荐页面保留，但所需业务服务需自行提供；仓库不包含 Java/Python 后端、模型、提示词、AI 编排代码、部署资料或 AI 开发工具记录。未配置可用后端时，登录、分析、推荐等网络功能不可用。

## 技术与平台

- Flutter / Dart，Dart SDK 要求 `^3.12.1`。
- `http`：业务 API；`shared_preferences`：登录态；`image_picker`：拍照与选图。
- 当前包含 **Android** 工程；未提供 iOS、Web 和桌面工程。
- Android 构建需要 Flutter SDK、Android SDK，以及兼容项目 Gradle/AGP 的 JDK；源码目标为 Java 17。

## 目录

```text
lib/
  main.dart             应用入口与路由
  pages/                登录、拍照、穿搭、个人中心
  services/             API 调用与响应模型
  theme/                主题
  widgets/              通用组件
android/                Android 工程
assets/                 应用图标源文件
config/                 不含真实服务地址的配置示例
test/                   已有测试源码
docs/                   发布前脱敏检查记录
init-qiaoshengix.bat     本地 Git 身份与初始化脚本
```

## 配置与编译

安装 Flutter 与 Android 开发工具后，在仓库根目录执行：

```powershell
flutter pub get
```

将 `config/dev.example.json`、`test.example.json` 或 `prod.example.json` 复制为对应的 `dev.json`、`test.json`、`prod.json`，仅在这些本地文件中填写自己的业务 API 地址。真实配置被 `.gitignore` 排除。

`API_BASE_URL` 应包含协议和可选端口，**不带末尾 `/`，也不重复添加 `/api`**。开发示例的 localhost 是本机回环地址；Android 设备访问开发机器时需要自行配置网络或端口映射。测试、生产示例使用保留的 `.invalid` 域名，不能作为真实服务使用。

```powershell
# 开发构建
flutter build apk --debug --dart-define-from-file=config/dev.json

# 测试环境构建
flutter build apk --debug --dart-define-from-file=config/test.json

# 生产环境构建（先配置自己的发布签名）
flutter build apk --release --dart-define-from-file=config/prod.json
```

也可直接使用 `--dart-define=API_BASE_URL=https://api.example.invalid` 注入地址。未传入配置时默认使用无效示例域名，不会连接原项目服务。

> 构建参数不是秘密存储：注入的地址可以从安装包中提取。不要在客户端放置服务端密钥，也不要将包含私人地址的构建产物上传到公开仓库。

### Android 签名

正式发布前自行创建签名密钥和 `android/key.properties`，配置 `storeFile`、`storePassword`、`keyAlias`、`keyPassword`。这些文件不随仓库分发。现有构建逻辑在未配置发布签名时回退到 debug 签名，此时生成的 release 包仅适合验证构建，不应用作正式发布包。

## 业务 API 约定

客户端消费统一响应：`{ "code": 200, "message": "...", "data": ... }`。

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| POST | `/api/auth/register` | 用户注册 |
| POST | `/api/auth/login` | 用户登录 |
| POST | `/api/analyze` | 图片分析，multipart 字段 `image` |
| GET | `/api/outfit/spots` | 景点列表 |
| POST | `/api/outfit/recommend` | 穿搭推荐 |

认证通过 `Authorization: Bearer <token>` 传递。具体请求与响应字段见 `lib/services/api_service.dart`。

## Git 初始化与提交身份

独立仓库从已脱敏的当前 App 快照创建，不继承原项目提交历史。

```powershell
.\init-qiaoshengix.bat
```

脚本仅操作自身所在仓库，将本地身份设为：

```text
Author / Committer: qiaoshengix <qiaoshengix@outlook.com>
```

没有历史时创建首次提交；已有历史时核查全部引用中的作者与提交者，发现不一致则报错，不改写历史。脚本不会创建 GitHub 仓库或推送。以后在这个仓库正常提交会使用本地身份配置；显式覆盖身份、导入其他历史或合并外部提交后，应重新检查。

GitHub 通过提交邮箱关联账号，请确保 `qiaoshengix@outlook.com` 已在你的 GitHub 账号中添加并验证。提交邮箱会出现在公开历史中，此处按维护者确认使用当前本地邮箱。

## 上传 GitHub

在 GitHub 创建空仓库 `lumitrail-app`，不要自动添加 README 或其他初始化文件。然后在**此独立仓库目录**执行：

```powershell
git status --short
git log --all --format="%h %an <%ae> | %cn <%ce>"
git remote add origin https://github.com/qiaoshengix/lumitrail-app.git
git push -u origin main
```

上传范围及已执行检查见 [脱敏检查记录](docs/PUBLICATION_AUDIT.md)。

## 参考

- [Dart 编译环境配置](https://dart.dev/libraries/core/environment-declarations)
- [GitHub 提交邮箱与账号关联](https://docs.github.com/en/account-and-profile/how-tos/email-preferences/setting-your-commit-email-address)
