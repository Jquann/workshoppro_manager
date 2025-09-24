# Google Sign-In 修复指南

## 问题诊断
Google Sign-In 无法正常工作的主要原因：
1. `google-services.json` 文件中缺少 OAuth 客户端配置
2. Firebase Console 中可能未正确配置 Google Sign-In
3. SHA-1 指纹可能未添加或不正确

## 解决方案

### 步骤 1：更新 Firebase Console 配置

1. **访问 Firebase Console**
   - 打开 https://console.firebase.google.com/
   - 选择项目 `workshopmanager-29024`

2. **启用 Google Sign-In**
   - 前往 **Authentication** > **Sign-in method**
   - 找到 **Google** 提供商
   - 点击 **启用**
   - 设置项目公开名称（例如：WorkshopPro Manager）
   - 设置项目支持邮箱

### 步骤 2：获取并添加 SHA-1 指纹

1. **生成 SHA-1 指纹**
   ```powershell
   # 在项目根目录运行
   cd android
   ./gradlew signingReport
   ```

2. **复制 SHA-1 指纹**
   - 从输出中找到 `SHA1:` 后的指纹
   - 复制完整的 SHA-1 指纹

3. **添加到 Firebase**
   - 在 Firebase Console 中，前往 **Project settings**
   - 找到你的 Android 应用
   - 点击 **Add fingerprint**
   - 粘贴 SHA-1 指纹并保存

### 步骤 3：下载更新的配置文件

1. **下载新的 google-services.json**
   - 在 Firebase Console 的项目设置中
   - 点击 Android 应用旁边的下载按钮
   - 下载最新的 `google-services.json` 文件

2. **替换现有文件**
   - 将新的 `google-services.json` 文件替换
   - 位置：`android/app/google-services.json`

### 步骤 4：验证配置文件

新的 `google-services.json` 应该包含：
```json
{
  "client": [
    {
      "oauth_client": [
        {
          "client_id": "你的客户端ID.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "my.edu.tarumt.workshoppro_manager",
            "certificate_hash": "你的SHA1指纹"
          }
        },
        {
          "client_id": "你的Web客户端ID.apps.googleusercontent.com",
          "client_type": 3
        }
      ]
    }
  ]
}
```

### 步骤 5：更新代码（如果需要）

检查 `lib/services/auth_service.dart` 中的 Google Sign-In 配置：

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  // 如果需要指定作用域，可以添加：
  // scopes: ['email', 'profile'],
);
```

### 步骤 6：重新构建应用

```powershell
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 构建并运行
flutter run
```

## 测试步骤

1. 运行应用
2. 点击 "Continue with Google" 按钮
3. 应该弹出 Google 登录界面
4. 选择账户并登录
5. 检查是否成功跳转到主界面

## 常见错误和解决方案

### 错误 1: `PlatformException(sign_in_failed)`
**解决方案：**
- 确保 SHA-1 指纹正确添加到 Firebase
- 重新下载 google-services.json 文件

### 错误 2: `operation-not-allowed`
**解决方案：**
- 在 Firebase Console 中启用 Google Sign-In
- 检查 Authentication 设置

### 错误 3: `network_error`
**解决方案：**
- 检查网络连接
- 确保 Firebase 项目配置正确

## 调试提示

在 `lib/services/auth_service.dart` 中已添加详细的调试日志：
- 查看 Flutter 控制台输出
- 寻找 "Google Sign-In" 相关的日志信息
- 检查任何错误消息

## 联系支持

如果问题仍然存在：
1. 检查 Firebase Console 中的使用情况和配额
2. 确认项目配置与应用包名匹配
3. 验证 Google Sign-In API 是否已启用