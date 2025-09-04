import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/floor_management_screen.dart';
import 'screens/my_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/migration_service.dart';
import 'theme/app_theme.dart';

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
        '/main': (context) => MainScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  
  // 使用IndexedStack来保持页面状态
  final List<Widget> _screens = [
    HomeScreen(),
    FloorManagementScreen(),
    MyScreen(), // 现在作为"我的"界面
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，因为使用了AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFB),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, -2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.textHint,
          selectedLabelStyle: const TextStyle(
            fontSize: AppTheme.fontSizeCaption,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: AppTheme.fontSizeCaption,
            fontWeight: FontWeight.normal,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: '识别',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apartment_outlined),
              activeIcon: Icon(Icons.apartment),
              label: '楼层',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}