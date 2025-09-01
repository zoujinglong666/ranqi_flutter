import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/floor.dart';
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 取消事件订阅
    _roomEventSubscription?.cancel();
    _floorController.dispose();
    super.dispose();
  }
}