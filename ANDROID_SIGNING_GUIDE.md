# Android APK 签名配置指南

## 当前状态
- ✅ 已生成keystore文件 (`android/key.jks`)
- ✅ 已创建签名配置文件 (`android/key.properties`)
- ⚠️ 目前使用debug签名进行构建（临时方案）
- 🔄 正在解决自定义签名的Gradle配置问题

## 概述
此项目配置了Android APK签名基础设施，但目前为了确保CI/CD流水线能够成功运行，暂时使用debug签名。

## 当前构建配置
```kotlin
buildTypes {
    release {
        // 临时使用debug签名确保构建成功
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

## 已创建的文件

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

## 下一步计划
1. 🔧 修复Gradle Kotlin DSL签名配置语法
2. 🔄 启用自定义keystore签名
3. ✅ 验证签名APK的完整性
4. 📦 更新CI/CD流水线以使用正确签名

## 当前使用方法

### 本地构建
```bash
flutter build apk --release
```
这将生成使用debug签名的release APK，可用于测试。

### CI/CD构建
GitHub Actions会自动构建APK文件并创建release。

## 安全注意事项
- ✅ `key.jks`和`key.properties`已添加到`.gitignore`
- ✅ 不会将敏感信息提交到版本控制
- ⚠️ 请妥善保管keystore文件和密码
- ⚠️ 丢失keystore将无法更新已发布的应用

## 验证构建
构建完成后，APK文件位置：
```
build/app/outputs/flutter-apk/app-release.apk
```

可以使用以下命令验证APK签名：
```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

## 备份建议
- 将keystore文件备份到安全位置
- 记录所有密码和alias信息
- 考虑使用密码管理器存储敏感信息