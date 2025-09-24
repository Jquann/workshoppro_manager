## Google Sign-In 快速修复步骤

### ⚠️ 你的 SHA-1 指纹
```
E5:06:F1:83:71:7C:D5:88:FD:04:08:BF:11:71:EA:82:F7:85:B5:D5
```

### 立即执行以下步骤：

#### 1. 打开 Firebase Console
- 访问：https://console.firebase.google.com/
- 选择项目：`workshopmanager-29024`

#### 2. 启用 Google Sign-In
1. 点击左侧菜单 **Authentication**
2. 点击 **Sign-in method** 标签
3. 找到 **Google** 提供商
4. 点击 **启用**
5. 填写：
   - 项目公开名称：`WorkshopPro Manager`
   - 项目支持邮箱：你的邮箱地址
6. 点击 **保存**

#### 3. 添加 SHA-1 指纹
1. 点击左上角 ⚙️ (设置图标)
2. 选择 **项目设置**
3. 向下滚动到 **您的应用** 部分
4. 找到 Android 应用 (包名: `my.edu.tarumt.workshoppro_manager`)
5. 点击 **添加指纹**
6. 粘贴以下 SHA-1 指纹：
   ```
   E5:06:F1:83:71:7C:D5:88:FD:04:08:BF:11:71:EA:82:F7:85:B5:D5
   ```
7. 点击 **保存**

#### 4. 下载新的配置文件
1. 在同一个 Android 应用卡片中
2. 点击 **google-services.json** 下载按钮
3. 下载文件到你的计算机
4. 用新文件替换项目中的：
   ```
   android/app/google-services.json
   ```

#### 5. 验证配置文件
打开新的 `google-services.json` 文件，确保 `oauth_client` 数组不为空，应该包含类似以下内容：
```json
"oauth_client": [
  {
    "client_id": "xxxxx.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "my.edu.tarumt.workshoppro_manager",
      "certificate_hash": "e506f183717cd588fd0408bf1171ea82f785b5d5"
    }
  }
]
```

#### 6. 重新构建应用
在 VS Code 终端中运行：
```powershell
flutter clean
flutter pub get
flutter run
```

### 🎯 完成后测试
1. 运行应用
2. 点击 "Continue with Google" 按钮
3. 应该看到 Google 登录页面
4. 选择账户登录
5. 成功后应该跳转到主界面

### ❗ 如果仍有问题
检查以下项目：
- [ ] Google Sign-In 在 Firebase Console 中已启用
- [ ] SHA-1 指纹已正确添加
- [ ] google-services.json 已更新且包含 oauth_client
- [ ] 包名匹配：`my.edu.tarumt.workshoppro_manager`
- [ ] 网络连接正常

### 常见错误修复
- `sign_in_failed`：SHA-1 指纹问题，重新添加指纹
- `operation-not-allowed`：Google Sign-In 未启用
- `network_error`：检查网络或 Firebase 配置