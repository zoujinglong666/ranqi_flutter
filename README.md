# 燃气水表识别应用

## 功能特性

### 1. 首页 - 拍照识别
- 拍照或从相册选择图片
- 自动转换为base64格式
- 调用阿里云OCR接口进行燃气表读数识别
- 支持楼层和房间号选择/输入
- 保存识别记录

### 2. 楼层管理
- 左右分栏布局（楼层列表 + 房间展示）
- 添加/删除/修改房间信息
- 支持多楼层管理
- 类似点单UI的交互体验

### 3. 我的记录
- 查看所有保存的识别记录
- 记录详情查看（包含图片、读数、位置、时间）
- 删除记录功能
- 支持刷新

## 阿里云API配置

### 1. 获取AppCode
1. 登录阿里云市场：https://market.aliyun.com/
2. 搜索"燃气表识别"或访问相关API页面
3. 购买服务并获取AppCode

### 2. 配置AppCode
在 `lib/services/recognition_service.dart` 文件中：

```dart
static const String _appCode = '你的实际AppCode'; // 替换这里
```

### 3. API接口说明
- **接口地址**: https://gas.market.alicloudapi.com/api/predict/gas_meter_end2end
- **请求方式**: POST
- **请求头**:
  - Content-Type: application/json; charset=UTF-8
  - Authorization: APPCODE {你的AppCode}
- **请求体**:
  ```json
  {
    "image": "图片的base64编码"
  }
  ```

## 运行应用

1. 确保已安装Flutter SDK
2. 安装依赖：
   ```bash
   flutter pub get
   ```
3. 运行应用：
   ```bash
   flutter run
   ```

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/                      # 数据模型
│   ├── meter_record.dart       # 表记录模型
│   └── room.dart               # 房间模型
├── services/                    # 服务层
│   ├── recognition_service.dart # 识别服务
│   └── storage_service.dart    # 存储服务
└── screens/                     # 页面
    ├── home_screen.dart        # 首页
    ├── floor_management_screen.dart # 楼层管理
    └── my_records_screen.dart  # 我的记录
```

## 注意事项

1. **权限配置**: 应用需要相机和存储权限
2. **网络权限**: 需要网络权限调用API
3. **AppCode配置**: 必须配置正确的AppCode才能正常识别
4. **图片格式**: 支持常见图片格式（JPG、PNG等）
5. **识别准确性**: 建议拍摄清晰、光线充足的燃气表图片

## 开发说明

- 使用SharedPreferences进行本地数据存储
- 支持离线查看历史记录
- 模块化代码结构，便于维护和扩展
- Material Design风格UI