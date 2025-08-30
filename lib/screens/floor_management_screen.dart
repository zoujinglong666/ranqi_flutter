import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/room.dart';
import '../services/storage_service.dart';

class FloorManagementScreen extends StatefulWidget {
  @override
  _FloorManagementScreenState createState() => _FloorManagementScreenState();
}

class _FloorManagementScreenState extends State<FloorManagementScreen> {
  List<Room> _rooms = [];
  int _selectedFloor = 1;
  List<int> _availableFloors = [];
  String? _editingRoomId; // 当前正在编辑的房间ID
  final Map<String, TextEditingController> _editControllers = {}; // 编辑控制器

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    // 清理所有编辑控制器
    _editControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadRooms() async {
    final rooms = await StorageService.getRooms();
    setState(() {
      _rooms = rooms;
      _updateAvailableFloors();
    });
  }

  void _updateAvailableFloors() {
    final floors = _rooms.map((room) => room.floor).toSet().toList();
    floors.sort();
    if (floors.isEmpty) {
      floors.add(1); // 默认添加1楼
    }
    setState(() {
      _availableFloors = floors;
      if (!_availableFloors.contains(_selectedFloor)) {
        _selectedFloor = _availableFloors.first;
      }
    });
  }

  List<Room> _getRoomsForFloor(int floor) {
    return _rooms.where((room) => room.floor == floor).toList()
      ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber)); // 按房间号排序
  }

  Future<void> _addRoom(String roomNumber) async {
    // 检查房间号是否已存在
    final existingRoom = _rooms.firstWhere(
      (room) => room.floor == _selectedFloor && room.roomNumber == roomNumber,
      orElse: () => Room(id: '', floor: 0, roomNumber: ''),
    );
    
    if (existingRoom.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('房间号 $roomNumber 已存在')),
      );
      return;
    }
    
    final room = Room(
      id: Uuid().v4(),
      floor: _selectedFloor,
      roomNumber: roomNumber,
    );
    
    setState(() {
      _rooms.add(room);
    });
    
    await _saveRooms();
    _updateAvailableFloors();
  }

  Future<void> _deleteRoom(Room room) async {
    setState(() {
      _rooms.removeWhere((r) => r.id == room.id);
      // 如果正在编辑这个房间，取消编辑状态
      if (_editingRoomId == room.id) {
        _editingRoomId = null;
        _editControllers[room.id]?.dispose();
        _editControllers.remove(room.id);
      }
    });
    
    await _saveRooms();
    _updateAvailableFloors();
  }

  Future<void> _editRoom(Room oldRoom, String newRoomNumber) async {
    // 检查新房间号是否已存在（排除当前房间）
    final existingRoom = _rooms.firstWhere(
      (room) => room.floor == oldRoom.floor && 
                room.roomNumber == newRoomNumber && 
                room.id != oldRoom.id,
      orElse: () => Room(id: '', floor: 0, roomNumber: ''),
    );
    
    if (existingRoom.id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('房间号 $newRoomNumber 已存在')),
      );
      return;
    }
    
    final index = _rooms.indexWhere((r) => r.id == oldRoom.id);
    if (index != -1) {
      setState(() {
        _rooms[index] = Room(
          id: oldRoom.id,
          floor: oldRoom.floor,
          roomNumber: newRoomNumber,
        );
        _editingRoomId = null; // 退出编辑状态
      });
      
      // 清理编辑控制器
      _editControllers[oldRoom.id]?.dispose();
      _editControllers.remove(oldRoom.id);
      
      await _saveRooms();
    }
  }

  // 统一的保存方法，确保持久化
  Future<void> _saveRooms() async {
    try {
      await StorageService.saveRooms(_rooms);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存成功'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  // 开始编辑房间
  void _startEditRoom(Room room) {
    setState(() {
      _editingRoomId = room.id;
    });
    
    // 创建编辑控制器
    _editControllers[room.id] = TextEditingController(text: room.roomNumber);
  }

  // 取消编辑
  void _cancelEdit(String roomId) {
    setState(() {
      _editingRoomId = null;
    });
    
    // 清理编辑控制器
    _editControllers[roomId]?.dispose();
    _editControllers.remove(roomId);
  }

  // 保存编辑
  void _saveEdit(Room room) {
    final newRoomNumber = _editControllers[room.id]?.text.trim() ?? '';
    if (newRoomNumber.isNotEmpty) {
      _editRoom(room, newRoomNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('房间号不能为空')),
      );
    }
  }

  void _showAddRoomDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加房间'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '房间号',
            hintText: '例如: 101, A01',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addRoom(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final roomNumber = controller.text.trim();
              if (roomNumber.isNotEmpty) {
                _addRoom(roomNumber);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('房间号不能为空')),
                );
              }
            },
            child: Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showAddFloorDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加楼层'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '楼层号',
            hintText: '例如: 2, 3, 4',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
          onSubmitted: (value) {
            final floor = int.tryParse(value);
            if (floor != null && floor > 0 && !_availableFloors.contains(floor)) {
              setState(() {
                _availableFloors.add(floor);
                _availableFloors.sort();
                _selectedFloor = floor;
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final floor = int.tryParse(controller.text);
              if (floor != null && floor > 0) {
                if (!_availableFloors.contains(floor)) {
                  setState(() {
                    _availableFloors.add(floor);
                    _availableFloors.sort();
                    _selectedFloor = floor;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('楼层 $floor 已存在')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('请输入有效的楼层号')),
                );
              }
            },
            child: Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFloorRooms = _getRoomsForFloor(_selectedFloor);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('楼层管理'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: _showAddFloorDialog,
            icon: Icon(Icons.add_home),
            tooltip: '添加楼层',
          ),
        ],
      ),
      body: Row(
        children: [
          // 左侧楼层列表
          Container(
            width: 120,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '楼层',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableFloors.length,
                    itemBuilder: (context, index) {
                      final floor = _availableFloors[index];
                      final isSelected = floor == _selectedFloor;
                      
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Material(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() {
                                _selectedFloor = floor;
                                // 切换楼层时取消编辑状态
                                _editingRoomId = null;
                                _editControllers.values.forEach((controller) => controller.dispose());
                                _editControllers.clear();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Text(
                                '${floor}楼',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
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
          
          // 右侧房间列表
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedFloor}楼房间 (${currentFloorRooms.length}间)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddRoomDialog,
                        icon: Icon(Icons.add),
                        label: Text('添加房间'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: currentFloorRooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                '${_selectedFloor}楼暂无房间',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '点击上方"添加房间"按钮开始添加',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: currentFloorRooms.length,
                          itemBuilder: (context, index) {
                            final room = currentFloorRooms[index];
                            final isEditing = _editingRoomId == room.id;
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // 房间图标
                                    Icon(
                                      Icons.door_front_door,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                    SizedBox(width: 16),
                                    
                                    // 房间信息（左侧）
                                    Expanded(
                                      child: isEditing
                                          ? TextField(
                                              controller: _editControllers[room.id],
                                              decoration: InputDecoration(
                                                labelText: '房间号',
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                              autofocus: true,
                                              onSubmitted: (_) => _saveEdit(room),
                                            )
                                          : InkWell(
                                              onTap: () => _startEditRoom(room),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(vertical: 8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '房间号: ${room.roomNumber}',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      '点击编辑',
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                    
                                    // 操作按钮（右侧）
                                    if (isEditing) ...[
                                      // 编辑状态：保存和取消按钮
                                      IconButton(
                                        onPressed: () => _saveEdit(room),
                                        icon: Icon(Icons.check, color: Colors.green),
                                        tooltip: '保存',
                                      ),
                                      IconButton(
                                        onPressed: () => _cancelEdit(room.id),
                                        icon: Icon(Icons.close, color: Colors.orange),
                                        tooltip: '取消',
                                      ),
                                    ] else ...[
                                      // 普通状态：删除按钮
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('确认删除'),
                                              content: Text('确定要删除房间 ${room.roomNumber} 吗？'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('取消'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    _deleteRoom(room);
                                                    Navigator.pop(context);
                                                  },
                                                  child: Text('删除'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        tooltip: '删除',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}