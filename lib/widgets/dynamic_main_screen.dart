import 'package:flutter/material.dart';
import '../models/tab_item.dart';
import '../services/tab_manager.dart';
import '../widgets/dynamic_tab_bar.dart';

/// 动态主屏幕组件
class DynamicMainScreen extends StatefulWidget {
  final List<TabItem> initialTabs;

  const DynamicMainScreen({
    super.key,
    required this.initialTabs,
  });

  @override
  State<DynamicMainScreen> createState() => _DynamicMainScreenState();
}

class _DynamicMainScreenState extends State<DynamicMainScreen> 
    with AutomaticKeepAliveClientMixin {
  late TabManager _tabManager;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabManager = TabManager();
    _tabManager.initializeTabs(widget.initialTabs);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
        child: AnimatedBuilder(
          animation: _tabManager,
          builder: (context, child) {
            final visibleTabs = _tabManager.visibleTabs;
            final currentIndex = _tabManager.currentIndex;
            
            if (visibleTabs.isEmpty) {
              return const Center(
                child: Text('没有可用的页面'),
              );
            }

            return IndexedStack(
              index: currentIndex,
              children: visibleTabs.map((tab) => tab.screen).toList(),
            );
          },
        ),
      ),
      bottomNavigationBar: DynamicTabBar(
        tabManager: _tabManager,
      ),
    );
  }
}