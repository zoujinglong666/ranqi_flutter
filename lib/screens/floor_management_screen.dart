import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/storage_service.dart';
import '../services/event_manager.dart';
import '../theme/app_theme.dart';

class FloorManagementScreen extends StatefulWidget {
  @override
  _FloorManagementScreenState createState() => _FloorManagementScreenState();
}

class _FloorManagementScreenState extends State<FloorManagementScreen> with WidgetsBindingObserver {
  List<Room> _rooms = [];
  int _selectedFloor = 1;
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  
  // 事件订阅
  StreamSubscription<EventData>? _roomEventSubscription;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    // 监听应用生命周期变化
    WidgetsBinding.instance.addObserver(this);
    // 订阅房间相关事件
    _subscribeToEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面被访问时重新加载数据
    _loadRooms();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用从后台回到前台时重新加载数据
    if (state == AppLifecycleState.resumed) {
      _loadRooms();
    }
  }

  Future<void> _loadRooms() async {
    final rooms = await StorageService.getRooms();
    setState(() {
      _rooms = rooms;
    });
  }

  List<int> _getAvailableFloors() {
    final floors = _rooms.map((room) => room.floor).toSet().toList();
    floors.sort();
    if (floors.isEmpty) floors.add(1);
    return floors;
  }

  List<Room> _getRoomsForFloor(int floor) {
    final roomsForFloor = _rooms.where((room) => room.floor == floor && room.roomNumber != '_PLACEHOLDER_').toList();
    // 按房间号排序
    roomsForFloor.sort((a, b) {
      // 尝试按数字排序，如果不是数字则按字符串排序
      final aNum = int.tryParse(a.roomNumber);
      final bNum = int.tryParse(b.roomNumber);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      return a.roomNumber.compareTo(b.roomNumber);
    });
    return roomsForFloor;
  }

  Future<void> _addRoom() async {
    final roomNumber = _roomController.text.trim();
    if (roomNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入房间号')),
      );
      return;
    }

    // 检查房间是否已存在
    final existingRoom = _rooms.firstWhere(
      (room) => room.floor == _selectedFloor && room.roomNumber == roomNumber,
      orElse: () => Room(id: '', floor: -1, roomNumber: ''),
    );

    if (existingRoom.floor != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('该房间已存在')),
      );
      return;
    }

    final newRoom = Room(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      floor: _selectedFloor, 
      roomNumber: roomNumber,
    );
    
    _rooms.add(newRoom);
    await StorageService.saveRooms(_rooms);
    _roomController.clear();
    _loadRooms();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('房间添加成功')),
    );
  }

  Future<void> _deleteRoom(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除 ${room.floor}楼 ${room.roomNumber} 房间吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _rooms.removeWhere((r) => r.id == room.id);
      await StorageService.saveRooms(_rooms);
      _loadRooms();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('房间删除成功')),
      );
    }
  }

  Future<void> _editRoom(Room room) async {
    final controller = TextEditingController(text: room.roomNumber);
    final newRoomNumber = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑房间号'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '房间号',
            hintText: '请输入新的房间号',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text('保存'),
          ),
        ],
      ),
    );

    if (newRoomNumber != null && newRoomNumber.isNotEmpty && newRoomNumber != room.roomNumber) {
      // 检查新房间号是否已存在
      final existingRoom = _rooms.firstWhere(
        (r) => r.floor == room.floor && r.roomNumber == newRoomNumber && r.id != room.id,
        orElse: () => Room(id: '', floor: -1, roomNumber: ''),
      );

      if (existingRoom.floor != -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('该房间号已存在')),
        );
        return;
      }

      // 更新房间信息
      final index = _rooms.indexWhere((r) => r.id == room.id);
      if (index != -1) {
        _rooms[index] = Room(
          id: room.id,
          floor: room.floor,
          roomNumber: newRoomNumber,
        );
        await StorageService.saveRooms(_rooms);
        _loadRooms();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('房间号修改成功')),
        );
      }
    }
  }

  Future<void> _addFloor() async {
    final floorNumber = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加楼层'),
        content: TextField(
          controller: _floorController,
          decoration: AppStyles.inputDecoration(
            labelText: '楼层号',
            hintText: '请输入楼层号',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final floor = int.tryParse(_floorController.text.trim());
              Navigator.of(context).pop(floor);
            },
            child: Text('添加'),
          ),
        ],
      ),
    );

    if (floorNumber != null && floorNumber > 0) {
      final floors = _getAvailableFloors();
      if (!floors.contains(floorNumber)) {
        // 创建一个占位房间来确保楼层被保存和显示
        final placeholderRoom = Room(
          id: 'floor_${floorNumber}_placeholder_${DateTime.now().millisecondsSinceEpoch}',
          floor: floorNumber,
          roomNumber: '_PLACEHOLDER_', // 使用特殊标记作为占位符
        );
        
        _rooms.add(placeholderRoom);
        await StorageService.saveRooms(_rooms);
        
        setState(() {
          _selectedFloor = floorNumber;
        });
        
        _floorController.clear();
        await _loadRooms(); // 重新加载数据以更新UI
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('楼层添加成功，请添加房间')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('该楼层已存在')),
        );
      }
    }
  }

  Future<void> _deleteFloor(int floor) async {
    final roomsInFloor = _getRoomsForFloor(floor);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除楼层'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除 ${floor}楼 吗？'),
            SizedBox(height: 8),
            if (roomsInFloor.isNotEmpty) ...[
              Text(
                '该楼层包含 ${roomsInFloor.length} 个房间，删除后将无法恢复：',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              ...roomsInFloor.map((room) => Text(
                '• 房间 ${room.roomNumber}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              )),
            ] else ...[
              Text(
                '该楼层为空楼层',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 删除该楼层的所有房间（包括占位符）
      _rooms.removeWhere((room) => room.floor == floor);
      await StorageService.saveRooms(_rooms);
      
      // 如果删除的是当前选中的楼层，切换到其他楼层
      if (_selectedFloor == floor) {
        final remainingFloors = _getAvailableFloors();
        if (remainingFloors.isNotEmpty) {
          setState(() {
            _selectedFloor = remainingFloors.first;
          });
        } else {
          setState(() {
            _selectedFloor = 1; // 默认选择1楼
          });
        }
      }
      
      await _loadRooms();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${floor}楼已删除'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final floors = _getAvailableFloors();
    final currentFloorRooms = _getRoomsForFloor(_selectedFloor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('楼层管理'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home),
            onPressed: _addFloor,
            tooltip: '添加楼层',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        child: Row(
          children: [
            // 左侧楼层列表
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    '楼层',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: floors.length,
                    itemBuilder: (context, index) {
                      final floor = floors[index];
                      final isSelected = floor == _selectedFloor;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFloor = floor;
                            });
                          },
                          onLongPress: () {
                            _deleteFloor(floor);
                          },
                          child: ListTile(
                            title: Text(
                              '${floor}楼',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: AppTheme.spacingXS,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // 右侧房间管理
          Expanded(
            child: Container(
              color: AppTheme.backgroundPrimary,
              child: Column(
                children: [
                  // 房间列表标题
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.door_front_door,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          '${_selectedFloor}楼房间 (${currentFloorRooms.length}间)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 添加房间区域
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _roomController,
                            decoration: AppStyles.inputDecoration(
                              labelText: '房间号',
                              prefixIcon: Icons.add_home,
                            ),
                            onSubmitted: (_) => _addRoom(),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        AppStyles.primaryButton(
                          text: '添加',
                          icon: Icons.add,
                          onPressed: _addRoom,
                        ),
                      ],
                    ),
                  ),
                  
                  // 房间列表
                  Expanded(
                    child: currentFloorRooms.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  '${_selectedFloor}楼暂无房间',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeSubtitle,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingS),
                                Text(
                                  '请添加房间信息',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeBody,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            itemCount: currentFloorRooms.length,
                            itemBuilder: (context, index) {
                              final room = currentFloorRooms[index];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingS),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: Icon(
                                      Icons.door_front_door,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    '房间 ${room.roomNumber}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${room.floor}楼',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _editRoom(room),
                                        color: AppTheme.primaryBlue,
                                        tooltip: '编辑',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        onPressed: () => _deleteRoom(room),
                                        color: AppTheme.error,
                                        tooltip: '删除',
                                      ),
                                    ],
                                  ),
                                  onTap: () => _editRoom(room),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// 订阅事件
  void _subscribeToEvents() {
    _roomEventSubscription = eventManager.subscribeMultiple(
      [EventType.roomAdded, EventType.roomUpdated, EventType.roomDeleted, EventType.recordAdded],
      (eventData) {
        // 当有房间相关事件或新增记录时，重新加载数据
        if (mounted) {
          _loadRooms();
        }
      },
    ).first; // 使用第一个订阅即可，因为回调函数相同
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 取消事件订阅
    _roomEventSubscription?.cancel();
    _roomController.dispose();
    _floorController.dispose();
    super.dispose();
  }
}