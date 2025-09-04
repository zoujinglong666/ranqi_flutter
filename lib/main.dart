import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/migration_service.dart';
import 'theme/app_theme.dart';
import 'widgets/dynamic_main_screen.dart';
import 'config/tab_config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '燃气水表识别',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/main': (context) => DynamicMainScreen(
          initialTabs: TabConfig.getDefaultTabs(),
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 主屏幕包装器，处理数据迁移
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    _performMigrationIfNeeded();
  }
  
  /// 执行数据迁移（如果需要）
  Future<void> _performMigrationIfNeeded() async {
    try {
      final needsMigration = await MigrationService.needsMigration();
      if (needsMigration) {
        print('检测到占位符房间，开始执行数据迁移...');
        await MigrationService.migratePlaceholderRoomsToFloors();
        print('数据迁移完成');
      }
    } catch (e) {
      print('数据迁移失败: $e');
      // 迁移失败不影响应用正常运行
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicMainScreen(
      initialTabs: TabConfig.getDefaultTabs(),
    );
  }
}