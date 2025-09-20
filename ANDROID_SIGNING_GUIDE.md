# Android APK 签名配置指南

## 概述
此项目已配置统一的Android APK签名，确保发布版本的一致性和安全性。

## 配置文件

### 1. Keystore文件
- **位置**: `android/key.jks`
- **类型**: Java Keystore (JKS)
- **算法**: RSA 2048位
- **有效期**: 10000天（约27年）

### 2. 签名配置
- **Alias**: workshoppro
- **Store Password**: workshoppro123
- **Key Password**: workshoppro123

### 3. 证书信息
- **CN**: WorkshopPro Manager
- **OU**: Development
- **O**: TARUMT
- **L**: Kuala Lumpur
- **ST**: Selangor
- **C**: MY

## 文件结构
```
android/
├── key.jks                 # Keystore文件 (不要提交到Git)
├── key.properties          # 签名配置 (不要提交到Git)
└── app/
    └── build.gradle.kts    # 已配置签名
```

## 使用方法

### 本地构建
1. 确保`android/key.jks`和`android/key.properties`文件存在
2. 运行构建命令：
   ```bash
   flutter build apk --release
   ```

### CI/CD构建
GitHub Actions会自动使用配置的签名构建发布版APK。

## 安全注意事项
- ✅ `key.jks`和`key.properties`已添加到`.gitignore`
- ✅ 不会将敏感信息提交到版本控制
- ⚠️ 请妥善保管keystore文件和密码
- ⚠️ 丢失keystore将无法更新已发布的应用

## 验证签名
构建完成后，可以使用以下命令验证APK签名：
```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

## 备份建议
- 将keystore文件备份到安全位置
- 记录所有密码和alias信息
- 考虑使用密码管理器存储敏感信息