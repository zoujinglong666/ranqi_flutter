import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/room.dart';
import '../models/floor.dart';
import '../models/meter_record.dart';
import '../services/storage_service.dart';
import '../services/event_manager.dart';
import '../services/recognition_service.dart';
import '../theme/app_theme.dart';
import 'room_detail_screen.dart';

class FloorManagementScreen extends StatefulWidget {
  @override
  _FloorManagementScreenState createState() => _FloorManagementScreenState();
}

class _FloorManagementScreenState extends State<FloorManagementScreen> with WidgetsBindingObserver {
  List<Room> _rooms = [];
  int _selectedFloor = 1;
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

  Future<List<int>> _getAvailableFloors() async {
    final floors = await StorageService.getAvailableFloors();
    if (floors.isEmpty) return [1];
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
    final roomNumberController = TextEditingController();
    final waterPriceController = TextEditingController(text: '3.0');
    final electricityPriceController = TextEditingController(text: '0.6');
    final initialWaterController = TextEditingController(text: '0.0');
    final initialElectricityController = TextEditingController(text: '0.0');
    final occupantNameController = TextEditingController();
    final contactPhoneController = TextEditingController();
    final checkInInfoController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 顶部拖拽条
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题栏
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    Icons.add_home,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    '添加房间',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      controller: roomNumberController,
                      label: '房间号',
                      hint: '请输入房间号',
                      icon: Icons.room,
                      autofocus: true,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: waterPriceController,
                      label: '水费单价',
                      hint: '请输入水费单价',
                      suffix: '元/吨',
                      icon: Icons.water_drop,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: electricityPriceController,
                      label: '电费单价',
                      hint: '请输入电费单价',
                      suffix: '元/度',
                      icon: Icons.electric_bolt,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: initialWaterController,
                      label: '初始水量',
                      hint: '请输入初始水量',
                      suffix: '吨',
                      icon: Icons.water,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: initialElectricityController,
                      label: '初始电量',
                      hint: '请输入初始电量',
                      suffix: '度',
                      icon: Icons.electrical_services,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: occupantNameController,
                      label: '入住人姓名',
                      hint: '请输入入住人姓名（可选）',
                      icon: Icons.person,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: contactPhoneController,
                      label: '联系电话',
                      hint: '请输入联系电话（可选）',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: checkInInfoController,
                      label: '入住信息',
                      hint: '请输入入住信息（可选）',
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // 按钮区域
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final roomNumber = roomNumberController.text.trim();
                        if (roomNumber.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('请输入房间号')),
                          );
                          return;
                        }
                        
                        final waterPrice = double.tryParse(waterPriceController.text.trim()) ?? 3.0;
                        final electricityPrice = double.tryParse(electricityPriceController.text.trim()) ?? 0.6;
                        final initialWater = double.tryParse(initialWaterController.text.trim()) ?? 0.0;
                        final initialElectricity = double.tryParse(initialElectricityController.text.trim()) ?? 0.0;
                        final occupantName = occupantNameController.text.trim().isEmpty ? null : occupantNameController.text.trim();
                        final contactPhone = contactPhoneController.text.trim().isEmpty ? null : contactPhoneController.text.trim();
                        final checkInInfo = checkInInfoController.text.trim().isEmpty ? null : checkInInfoController.text.trim();
                        
                        Navigator.of(context).pop({
                          'roomNumber': roomNumber,
                          'waterPricePerTon': waterPrice,
                          'electricityPricePerKwh': electricityPrice,
                          'initialWaterAmount': initialWater,
                          'initialElectricityAmount': initialElectricity,
                          'occupantName': occupantName,
                          'contactPhone': contactPhone,
                          'checkInInfo': checkInInfo,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '添加房间',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );

    if (result != null) {
      final roomNumber = result['roomNumber'] as String;
      
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
        waterPricePerTon: result['waterPricePerTon'] as double,
        electricityPricePerKwh: result['electricityPricePerKwh'] as double,
        initialWaterAmount: result['initialWaterAmount'] as double,
        initialElectricityAmount: result['initialElectricityAmount'] as double,
        occupantName: result['occupantName'] as String?,
        contactPhone: result['contactPhone'] as String?,
        checkInInfo: result['checkInInfo'] as String?,
      );
      
      _rooms.add(newRoom);
      await StorageService.saveRooms(_rooms);
      _loadRooms();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('房间添加成功')),
      );
    }
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

  // 导航到房间详情管理界面
  void _navigateToRoomDetail(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(room: room),
      ),
    );
  }

  Future<void> _editRoom(Room room) async {
    final roomNumberController = TextEditingController(text: room.roomNumber);
    final waterPriceController = TextEditingController(text: room.waterPricePerTon.toString());
    final electricityPriceController = TextEditingController(text: room.electricityPricePerKwh.toString());
    final initialWaterController = TextEditingController(text: room.initialWaterAmount.toString());
    final initialElectricityController = TextEditingController(text: room.initialElectricityAmount.toString());
    final occupantNameController = TextEditingController(text: room.occupantName ?? '');
    final contactPhoneController = TextEditingController(text: room.contactPhone ?? '');
    final checkInInfoController = TextEditingController(text: room.checkInInfo ?? '');

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 顶部拖拽条
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题栏
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    '编辑房间信息',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${room.floor}楼',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      controller: roomNumberController,
                      label: '房间号',
                      hint: '请输入房间号',
                      icon: Icons.room,
                      autofocus: true,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: waterPriceController,
                      label: '水费单价',
                      hint: '请输入水费单价',
                      suffix: '元/吨',
                      icon: Icons.water_drop,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: electricityPriceController,
                      label: '电费单价',
                      hint: '请输入电费单价',
                      suffix: '元/度',
                      icon: Icons.electric_bolt,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: initialWaterController,
                      label: '初始水量',
                      hint: '请输入初始水量',
                      suffix: '吨',
                      icon: Icons.water,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: initialElectricityController,
                      label: '初始电量',
                      hint: '请输入初始电量',
                      suffix: '度',
                      icon: Icons.electrical_services,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: occupantNameController,
                      label: '入住人姓名',
                      hint: '请输入入住人姓名（可选）',
                      icon: Icons.person,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: contactPhoneController,
                      label: '联系电话',
                      hint: '请输入联系电话（可选）',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: checkInInfoController,
                      label: '入住信息',
                      hint: '请输入入住信息（可选）',
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // 按钮区域
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final roomNumber = roomNumberController.text.trim();
                        final waterPrice = double.tryParse(waterPriceController.text.trim()) ?? room.waterPricePerTon;
                        final electricityPrice = double.tryParse(electricityPriceController.text.trim()) ?? room.electricityPricePerKwh;
                        final initialWater = double.tryParse(initialWaterController.text.trim()) ?? room.initialWaterAmount;
                        final initialElectricity = double.tryParse(initialElectricityController.text.trim()) ?? room.initialElectricityAmount;
                        final occupantName = occupantNameController.text.trim().isEmpty ? null : occupantNameController.text.trim();
                        final contactPhone = contactPhoneController.text.trim().isEmpty ? null : contactPhoneController.text.trim();
                        final checkInInfo = checkInInfoController.text.trim().isEmpty ? null : checkInInfoController.text.trim();
                        
                        Navigator.of(context).pop({
                          'roomNumber': roomNumber,
                          'waterPricePerTon': waterPrice,
                          'electricityPricePerKwh': electricityPrice,
                          'initialWaterAmount': initialWater,
                          'initialElectricityAmount': initialElectricity,
                          'occupantName': occupantName,
                          'contactPhone': contactPhone,
                          'checkInInfo': checkInInfo,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '保存修改',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
           ],
         ),
         ),
       ),
     );

    if (result != null) {
      final newRoomNumber = result['roomNumber'] as String;
      
      // 检查新房间号是否已存在（如果房间号有变化）
      if (newRoomNumber != room.roomNumber) {
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
      }

      // 更新房间信息
      final index = _rooms.indexWhere((r) => r.id == room.id);
      if (index != -1) {
        _rooms[index] = Room(
          id: room.id,
          floor: room.floor,
          roomNumber: newRoomNumber,
          waterPricePerTon: result['waterPricePerTon'] as double,
          electricityPricePerKwh: result['electricityPricePerKwh'] as double,
          initialWaterAmount: result['initialWaterAmount'] as double,
          initialElectricityAmount: result['initialElectricityAmount'] as double,
          occupantName: result['occupantName'] as String?,
          contactPhone: result['contactPhone'] as String?,
          checkInInfo: result['checkInInfo'] as String?,
        );
        await StorageService.saveRooms(_rooms);
        _loadRooms();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('房间信息修改成功')),
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
      final availableFloors = await StorageService.getAvailableFloors();
      if (!availableFloors.contains(floorNumber)) {
        // 使用新的楼层管理系统
        final newFloor = Floor(
          floorNumber: floorNumber,
          createdAt: DateTime.now(),
          description: '手动添加的楼层',
        );
        
        await StorageService.saveFloor(newFloor);
        
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
      // 删除该楼层的所有房间
      _rooms.removeWhere((room) => room.floor == floor);
      await StorageService.saveRooms(_rooms);
      
      // 删除楼层记录
      await StorageService.deleteFloor(floor);
      
      // 如果删除的是当前选中的楼层，切换到其他楼层
      if (_selectedFloor == floor) {
        final remainingFloors = await _getAvailableFloors();
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
    final currentFloorRooms = _getRoomsForFloor(_selectedFloor);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '楼层管理',
          style: TextStyle(
            fontSize: AppTheme.fontSizeTitle,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
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
                  child: FutureBuilder<List<int>>(
                    future: _getAvailableFloors(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue,
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            '加载失败',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }
                      
                      final floors = snapshot.data ?? [1];
                      
                      return ListView.builder(
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
                          child: Text(
                            '点击添加按钮创建新房间',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: AppTheme.fontSizeBody,
                            ),
                          ),
                        ),
                        AppStyles.primaryButton(
                          text: '添加房间',
                          icon: Icons.add_home,
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
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(60),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.home_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '${_selectedFloor}楼暂无房间',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击上方按钮添加第一个房间',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                            itemCount: currentFloorRooms.length,
                            itemBuilder: (context, index) {
                              final room = currentFloorRooms[index];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _navigateToRoomDetail(room),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          // 房间头部信息
                                          Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      AppTheme.primaryBlue,
                                                      AppTheme.primaryBlue
                                                          .withOpacity(0.8),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius
                                                      .circular(14),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppTheme
                                                          .primaryBlue
                                                          .withOpacity(0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                          0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.home_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            '房间 ${room
                                                                .roomNumber}',
                                                            style: const TextStyle(
                                                              fontSize: 20,
                                                              fontWeight: FontWeight
                                                                  .bold,
                                                              color: AppTheme
                                                                  .textPrimary,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Container(
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme
                                                                .primaryBlue
                                                                .withOpacity(
                                                                0.1),
                                                            borderRadius: BorderRadius
                                                                .circular(8),
                                                          ),
                                                          child: Text(
                                                            '${room.floor}楼',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight
                                                                  .w600,
                                                              color: AppTheme
                                                                  .primaryBlue,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    if (room.occupantName !=
                                                        null &&
                                                        room.occupantName!
                                                            .isNotEmpty)
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .person_rounded,
                                                            size: 16,
                                                            color: AppTheme
                                                                .success,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            room.occupantName!,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              color: AppTheme
                                                                  .success,
                                                              fontWeight: FontWeight
                                                                  .w500,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Container(
                                                            width: 6,
                                                            height: 6,
                                                            decoration: BoxDecoration(
                                                              color: AppTheme
                                                                  .success,
                                                              borderRadius: BorderRadius
                                                                  .circular(3),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          const Text(
                                                            '已入住',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: AppTheme
                                                                  .success,
                                                              fontWeight: FontWeight
                                                                  .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    else
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 6,
                                                            height: 6,
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey
                                                                  .shade400,
                                                              borderRadius: BorderRadius
                                                                  .circular(3),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            '空置中',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey
                                                                  .shade600,
                                                              fontWeight: FontWeight
                                                                  .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // 费用信息
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius
                                                  .circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment
                                                            .center,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets
                                                                .all(6),
                                                            decoration: BoxDecoration(
                                                              color: Colors.blue
                                                                  .withOpacity(
                                                                  0.1),
                                                              borderRadius: BorderRadius
                                                                  .circular(8),
                                                            ),
                                                            child: const Icon(
                                                              Icons.water_drop,
                                                              color: Colors
                                                                  .blue,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            '水费',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey
                                                                  .shade600,
                                                              fontWeight: FontWeight
                                                                  .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '${room
                                                            .waterPricePerTon}元/吨',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight
                                                              .bold,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  width: 1,
                                                  height: 40,
                                                  color: Colors.grey.shade300,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment
                                                            .center,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets
                                                                .all(6),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .amber
                                                                  .withOpacity(
                                                                  0.1),
                                                              borderRadius: BorderRadius
                                                                  .circular(8),
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .electrical_services,
                                                              color: Colors
                                                                  .amber
                                                                  .shade700,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            '电费',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey
                                                                  .shade600,
                                                              fontWeight: FontWeight
                                                                  .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '${room
                                                            .electricityPricePerKwh}元/度',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight
                                                              .bold,
                                                          color: AppTheme
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // 操作按钮
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _showCameraOptions(
                                                            room),
                                                    icon: const Icon(
                                                      Icons.camera_alt_rounded,
                                                      size: 12,
                                                    ),
                                                    label: const Text(
                                                      '拍照',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight
                                                            .w600,
                                                      ),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor: AppTheme
                                                          .warning,
                                                      foregroundColor: Colors
                                                          .white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                width: 40,
                                                height: 40,
                                                child: Material(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius
                                                      .circular(12),
                                                  child: InkWell(
                                                    borderRadius: BorderRadius
                                                        .circular(12),
                                                    onTap: () =>
                                                        _editRoom(room),
                                                    child: const Icon(
                                                      Icons.edit_rounded,
                                                      color: AppTheme
                                                          .primaryBlue,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              SizedBox(
                                                width: 40,
                                                height: 40,
                                                child: Material(
                                                  color: Colors.red.shade50,
                                                  borderRadius: BorderRadius
                                                      .circular(12),
                                                  child: InkWell(
                                                    borderRadius: BorderRadius
                                                        .circular(12),
                                                    onTap: () =>
                                                        _deleteRoom(room),
                                                    child: Icon(
                                                      Icons.delete_rounded,
                                                      color: Colors.red
                                                          .shade400,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  // 拍照识别相关方法
  Future<void> _showCameraOptions(Room room) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部拖拽条
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: AppTheme.warning,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        '表计识别 - ${room.floor}楼${room.roomNumber}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                // 选项列表
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    '拍照识别',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '使用相机拍摄表计读数',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _takePictureForRoom(room);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: AppTheme.success,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    '从相册选择',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '从相册中选择表计照片',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGalleryForRoom(room);
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Future<void> _takePictureForRoom(Room room) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      _processImageForRoom(file, room);
    }
  }

  Future<void> _pickFromGalleryForRoom(Room room) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      _processImageForRoom(file, room);
    }
  }

  Future<void> _processImageForRoom(File imageFile, Room room) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 16),
                  Text('正在识别表计读数...'),
                ],
              ),
            ),
      );

      // 转换图片为base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 调用识别服务
      final result = await RecognitionService.recognizeMeter(base64Image);

      // 关闭加载对话框
      Navigator.of(context).pop();

      if (result.success) {
        // 显示识别结果并让用户选择表计类型和确认保存
        _showRecognitionResult(imageFile, base64Image, result, room);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? '识别失败'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      // 关闭可能存在的加载对话框
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('识别失败: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _showRecognitionResult(File imageFile, String base64Image,
      RecognitionResult result, Room room) async {
    String selectedMeterType = '燃气';
    final resultController = TextEditingController();
    bool isEditingResult = false;

    // 提取读数到输入框
    final regex = RegExp(r'读数[：:]\s*([0-9]+\.?[0-9]*)');
    final match = regex.firstMatch(result.displayText);
    if (match != null) {
      resultController.text = match.group(1) ?? '';
    } else {
      final numberRegex = RegExp(r'([0-9]+\.?[0-9]*)');
      final numberMatch = numberRegex.firstMatch(result.displayText);
      resultController.text = numberMatch?.group(1) ?? '';
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setState) =>
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery
                      .of(context)
                      .viewInsets
                      .bottom),
                  child: Container(
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 顶部拖拽条
                        Container(
                          margin: EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // 标题栏
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.success,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                '识别结果 - ${room.floor}楼${room.roomNumber}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Spacer(),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                icon: Icon(
                                    Icons.close, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1),
                        // 内容区域
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 图片预览
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      imageFile,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // 识别结果
                                Text(
                                  '识别结果',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppTheme.success.withOpacity(
                                            0.3)),
                                  ),
                                  child: Text(
                                    result.displayText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // 表计类型选择
                                Text(
                                  '表计类型',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedMeterType,
                                      isExpanded: true,
                                      items: [
                                        DropdownMenuItem(
                                          value: '燃气',
                                          child: Row(
                                            children: [
                                              Icon(Icons.local_fire_department,
                                                  color: Colors.orange,
                                                  size: 20),
                                              SizedBox(width: 8),
                                              Text('燃气表'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '水表',
                                          child: Row(
                                            children: [
                                              Icon(Icons.water_drop,
                                                  color: Colors.blue, size: 20),
                                              SizedBox(width: 8),
                                              Text('水表'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '电表',
                                          child: Row(
                                            children: [
                                              Icon(Icons.electrical_services,
                                                  color: Colors.blue, size: 20),
                                              SizedBox(width: 8),
                                              Text('电表'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedMeterType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // 读数编辑
                                Text(
                                  '读数确认',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: resultController,
                                  decoration: InputDecoration(
                                    labelText: '表计读数',
                                    hintText: '请确认或修正读数',
                                    prefixIcon: Icon(Icons.edit),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                ),
                                SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                        // 按钮区域
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(top: BorderSide(color: Colors.grey
                                .shade200)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Text(
                                    '取消',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (resultController.text
                                        .trim()
                                        .isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('请输入读数')),
                                      );
                                      return;
                                    }
                                    Navigator.of(context).pop(true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.success,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        '保存记录',
                                        style: TextStyle(fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );

    if (confirmed == true) {
      await _saveRecordForRoom(
          imageFile, base64Image, result, room, selectedMeterType,
          resultController.text.trim());
    }
  }

  Future<void> _saveRecordForRoom(File imageFile, String base64Image,
      RecognitionResult result, Room room, String meterType,
      String finalReading) async {
    try {
      // 将图片复制到应用的永久存储目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'meter_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${Uuid().v4()}.jpg';
      final permanentImagePath = path.join(imagesDir.path, fileName);
      await imageFile.copy(permanentImagePath);

      // 构建最终的识别结果文本
      String finalResultText = '读数: $finalReading';
      if (finalReading != (result.reading ?? '')) {
        finalResultText += ' (手动修正)';
      }

      final record = MeterRecord(
        id: Uuid().v4(),
        imagePath: permanentImagePath,
        base64Image: base64Image,
        recognitionResult: finalResultText,
        floor: room.floor,
        roomNumber: room.roomNumber,
        timestamp: DateTime.now(),
        meterType: meterType,
        requestId: result.requestId,
        integerPart: result.integerPart,
        decimalPart: result.decimalPart,
        recognitionDetails: result.recognitionDetails,
        isManuallyEdited: finalReading != (result.reading ?? ''),
      );

      await StorageService.saveMeterRecord(record);

      // 发布记录新增事件
      eventManager.publish(
        EventType.recordAdded,
        data: {
          'record': record,
          'floor': room.floor,
          'roomNumber': room.roomNumber,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('表计记录保存成功 - ${room.floor}楼${room.roomNumber}'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 取消事件订阅
    _roomEventSubscription?.cancel();
    _floorController.dispose();
    super.dispose();
  }
}