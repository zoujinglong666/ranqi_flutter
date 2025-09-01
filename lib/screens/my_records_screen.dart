import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meter_record.dart';
import '../services/storage_service.dart';
import '../services/event_manager.dart';
import '../theme/app_theme.dart';

class MyRecordsScreen extends StatefulWidget {
  @override
  _MyRecordsScreenState createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> with WidgetsBindingObserver {
  List<MeterRecord> _allRecords = [];
  List<MeterRecord> _filteredRecords = [];
  bool _isLoading = true;
  bool _isFilterExpanded = false; // 筛选区域展开状态
  
  // 筛选条件
  String? _selectedMeterType;
  int? _selectedFloor;
  String? _selectedRoom;
  String? _selectedMonth;
  
  // 快捷选择状态
  String? _selectedQuickFilter;
  
  // 筛选选项
  List<String> _availableMeterTypes = [];
  List<int> _availableFloors = [];
  List<String> _availableRooms = [];
  List<String> _availableMonths = [];
  
  // 事件订阅
  StreamSubscription<EventData>? _recordEventSubscription;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    // 监听应用生命周期变化
    WidgetsBinding.instance.addObserver(this);
    // 订阅记录相关事件
    _subscribeToEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面被访问时重新加载数据
    _loadRecords();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 取消事件订阅
    _recordEventSubscription?.cancel();
    super.dispose();
  }
  
  /// 订阅事件
  void _subscribeToEvents() {
    _recordEventSubscription = eventManager.subscribeMultiple(
      [EventType.recordAdded, EventType.recordUpdated, EventType.recordDeleted],
      (eventData) {
        // 当有记录相关事件时，重新加载数据
        if (mounted) {
          _loadRecords();
        }
      },
    ).first; // 使用第一个订阅即可，因为回调函数相同
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用从后台回到前台时重新加载数据
    if (state == AppLifecycleState.resumed) {
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    try {
      final records = await StorageService.getMeterRecords();
      // 按时间倒序排列，最新的记录在前面
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _allRecords = records;
        _filteredRecords = records;
        _isLoading = false;
      });
      _updateFilterOptions();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载记录失败: $e')),
      );
    }
  }

  void _updateFilterOptions() {
    // 更新表计类型选项 - 添加水表类型
    _availableMeterTypes = _allRecords
        .map((record) => record.meterType)
        .toSet()
        .toList();
    
    // 确保包含所有可能的表计类型
    if (!_availableMeterTypes.contains('燃气')) {
      _availableMeterTypes.add('燃气');
    }
    if (!_availableMeterTypes.contains('水表')) {
      _availableMeterTypes.add('水表');
    }
    if (!_availableMeterTypes.contains('水电')) {
      _availableMeterTypes.add('水电');
    }

    _availableMeterTypes.sort();

    // 更新楼层选项
    _availableFloors = _allRecords
        .map((record) => record.floor)
        .toSet()
        .toList()
        ..sort();
    
    // 调试信息
    print('所有记录数量: ${_allRecords.length}');
    print('可用楼层: $_availableFloors');
    print('记录详情: ${_allRecords.map((r) => '楼层${r.floor}-房间${r.roomNumber}').toList()}');

    // 更新房间选项（根据选择的楼层筛选）
    if (_selectedFloor != null) {
      // 先从记录中获取该楼层的房间
      final recordRooms = _allRecords
          .where((record) => record.floor == _selectedFloor)
          .map((record) => record.roomNumber)
          .toSet();
      
      // 再从存储的房间信息中获取该楼层的房间
      StorageService.getRoomsByFloor(_selectedFloor!).then((rooms) {
        final storageRooms = rooms.map((room) => room.roomNumber).toSet();
        
        // 合并两个来源的房间信息
        final allRooms = {...recordRooms, ...storageRooms}.toList()..sort();
        
        setState(() {
          _availableRooms = allRooms;
        });
      });
      
      // 临时设置，避免异步问题
      _availableRooms = recordRooms.toList()..sort();
    } else {
      _availableRooms = _allRecords
          .map((record) => record.roomNumber)
          .toSet()
          .toList()
          ..sort();
    }

    // 更新月份选项
    _availableMonths = _allRecords
        .map((record) => DateFormat('yyyy年MM月').format(record.timestamp))
        .toSet()
        .toList()
        ..sort((a, b) => b.compareTo(a)); // 按时间倒序
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        // 表计类型筛选
        if (_selectedMeterType != null && record.meterType != _selectedMeterType) {
          return false;
        }
        
        // 楼层筛选
        if (_selectedFloor != null && record.floor != _selectedFloor) {
          return false;
        }
        
        // 房间筛选
        if (_selectedRoom != null && record.roomNumber != _selectedRoom) {
          return false;
        }
        
        // 月份筛选
        if (_selectedMonth != null) {
          final recordMonth = DateFormat('yyyy年MM月').format(record.timestamp);
          if (recordMonth != _selectedMonth) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedMeterType = null;
      _selectedFloor = null;
      _selectedRoom = null;
      _selectedMonth = null;
      _selectedQuickFilter = null;
    });
    _updateFilterOptions();
    _applyFilters();
  }

  void _selectRecentMonths(int months) {
    final now = DateTime.now();
    final recentMonths = <String>[];
    
    for (int i = 0; i < months; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = DateFormat('yyyy年MM月').format(date);
      if (_availableMonths.contains(monthStr)) {
        recentMonths.add(monthStr);
      }
    }
    
    if (recentMonths.isNotEmpty) {
      // 这里可以扩展为多选，目前选择最近的一个月
      setState(() {
        _selectedMonth = recentMonths.first;
        _selectedQuickFilter = months == 3 ? '近三月' : '近半年';
      });
      _applyFilters();
    }
  }

  void _selectCurrentMonth() {
    final currentMonth = DateFormat('yyyy年MM月').format(DateTime.now());
    if (_availableMonths.contains(currentMonth)) {
      setState(() {
        _selectedMonth = currentMonth;
        _selectedQuickFilter = '本月';
      });
      _applyFilters();
    }
  }

  void _selectLastMonth() {
    final lastMonth = DateFormat('yyyy年MM月').format(
      DateTime(DateTime.now().year, DateTime.now().month - 1, 1)
    );
    if (_availableMonths.contains(lastMonth)) {
      setState(() {
        _selectedMonth = lastMonth;
        _selectedQuickFilter = '上月';
      });
      _applyFilters();
    }
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    final bool isSelected = _selectedQuickFilter == label;
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isSelected 
          ? AppTheme.primaryBlue 
          : AppTheme.primaryBlue.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.primaryBlue,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isSelected ? 2 : 0,
    );
  }

  // 获取表计类型颜色
  Color _getMeterTypeColor(String meterType) {
    switch (meterType) {
      case '燃气':
        return Colors.orange.shade100;
      case '水表':
        return Colors.cyan.shade100;
      case '水电':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // 获取表计类型文字颜色
  Color _getMeterTypeTextColor(String meterType) {
    switch (meterType) {
      case '燃气':
        return Colors.orange.shade700;
      case '水表':
        return Colors.cyan.shade700;
      case '水电':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // 获取表计类型图标
  IconData _getMeterTypeIcon(String meterType) {
    switch (meterType) {
      case '燃气':
        return Icons.local_fire_department;
      case '水表':
        return Icons.water_drop;
      case '水电':
        return Icons.electrical_services;
      default:
        return Icons.device_unknown;
    }
  }

  double? _calculateMonthlyUsage() {
    if (_filteredRecords.length < 2) return null;
    
    // 按时间排序
    final sortedRecords = List<MeterRecord>.from(_filteredRecords)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // 提取数值并计算差值
    final readings = sortedRecords.map((record) {
      final cleanReading = record.recognitionResult.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanReading) ?? 0.0;
    }).toList();
    
    if (readings.length < 2) return null;
    
    return readings.last - readings.first;
  }

  Future<void> _deleteRecord(MeterRecord record) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('确认删除'),
          content: Text('确定要删除这条记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performDelete(record);
              },
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete(MeterRecord record) async {
    try {
      await StorageService.deleteMeterRecord(record.id);
      await _loadRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('记录已删除')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  // 编辑记录
  Future<void> _editRecord(MeterRecord record) async {
    // 表计类型选项 - 动态获取所有可能的类型
    final Set<String> allMeterTypes = {'燃气', '水表', '水电'}; // 基础类型
    // 添加所有记录中的表计类型
    for (final r in _allRecords) {
      allMeterTypes.add(r.meterType);
    }
    final List<String> meterTypes = allMeterTypes.toList()..sort();
    String selectedMeterType = record.meterType;
    
    // 楼层和房间号选项
    List<int> availableFloors = [];
    List<String> availableRooms = [];
    int selectedFloor = record.floor;
    String selectedRoom = record.roomNumber;
    
    // 获取可用楼层
    final allRooms = await StorageService.getRooms();
    availableFloors = allRooms.map((room) => room.floor).toSet().toList()..sort();
    
    // 如果当前楼层不在可用楼层中，添加它
    if (!availableFloors.contains(selectedFloor)) {
      availableFloors.add(selectedFloor);
      availableFloors.sort();
    }
    
    // 获取当前楼层的房间
    Future<void> updateAvailableRooms(int floor) async {
      final roomsForFloor = await StorageService.getRoomsByFloor(floor);
      final storageRooms = roomsForFloor.map((room) => room.roomNumber).toList();
      
      // 从记录中获取该楼层的房间号
      final recordRooms = _allRecords
          .where((r) => r.floor == floor)
          .map((r) => r.roomNumber)
          .where((roomNumber) => roomNumber.isNotEmpty && !roomNumber.contains('_PLACEHOLDER_') && RegExp(r'^[0-9]+[A-Za-z]*$').hasMatch(roomNumber))
          .toSet();
      
      // 合并房间信息并过滤无效数据
      final allRooms = {...storageRooms, ...recordRooms}
          .where((roomNumber) => roomNumber.isNotEmpty && !roomNumber.contains('_PLACEHOLDER_') && RegExp(r'^[0-9]+[A-Za-z]*$').hasMatch(roomNumber))
          .toList();
      
      availableRooms = allRooms..sort();
      
      // 如果当前房间号不在可用房间中且是有效的，添加它
      if (!availableRooms.contains(selectedRoom) && 
          selectedRoom.isNotEmpty && 
          !selectedRoom.contains('_PLACEHOLDER_') && 
          RegExp(r'^[0-9]+[A-Za-z]*$').hasMatch(selectedRoom)) {
        availableRooms.add(selectedRoom);
        availableRooms.sort();
      }
    }
    
    await updateAvailableRooms(selectedFloor);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          '编辑记录',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // 表计类型选择
                    Text(
                      '表计类型',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMeterType,
                          isExpanded: true,
                          items: meterTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    _getMeterTypeIcon(type),
                                    color: _getMeterTypeTextColor(type),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedMeterType = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // 楼层选择
                    Text(
                      '楼层',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedFloor,
                          isExpanded: true,
                          items: availableFloors.map((int floor) {
                            return DropdownMenuItem<int>(
                              value: floor,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.layers,
                                    color: AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('${floor}楼'),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setModalState(() {
                                selectedFloor = newValue;
                              });
                              updateAvailableRooms(selectedFloor).then((_) {
                                setModalState(() {
                                  // 重置房间选择为第一个可用房间
                                  if (availableRooms.isNotEmpty) {
                                    selectedRoom = availableRooms.first;
                                  } else {
                                    selectedRoom = '';
                                  }
                                });
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // 房间号选择
                    Text(
                      '${selectedFloor}楼房间号',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: availableRooms.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.room,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '该楼层暂无房间',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: (availableRooms.contains(selectedRoom) && selectedRoom.isNotEmpty) ? selectedRoom : null,
                                isExpanded: true,
                                hint: Row(
                                  children: [
                                    Icon(
                                      Icons.room,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text('请选择房间号'),
                                  ],
                                ),
                                items: availableRooms.map((String room) {
                                  return DropdownMenuItem<String>(
                                    value: room,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.room,
                                          color: AppTheme.primaryBlue,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(room),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setModalState(() {
                                      selectedRoom = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                    ),
                    SizedBox(height: 24),
                    
                    // 按钮
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('取消'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // 验证选择
                              if (selectedRoom.isEmpty || availableRooms.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('请选择房间号')),
                                );
                                return;
                              }
                              
                              // 创建更新的记录
                              final updatedRecord = MeterRecord(
                                id: record.id,
                                imagePath: record.imagePath,
                                base64Image: record.base64Image,
                                recognitionResult: record.recognitionResult,
                                floor: selectedFloor,
                                roomNumber: selectedRoom,
                                timestamp: record.timestamp,
                                meterType: selectedMeterType,
                                requestId: record.requestId,
                                integerPart: record.integerPart,
                                decimalPart: record.decimalPart,
                                recognitionDetails: record.recognitionDetails,
                                isManuallyEdited: true, // 标记为手动编辑
                              );
                              
                              try {
                                // 更新记录
                                await StorageService.updateMeterRecord(updatedRecord);
                                
                                // 发布更新事件
                                eventManager.publish(
                                  EventType.recordUpdated,
                                  data: {'record': updatedRecord.toJson()},
                                );
                                
                                // 重新加载数据
                                await _loadRecords();
                                
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('记录更新成功')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('更新失败: $e')),
                                );
                              }
                            },
                            child: Text('保存'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 提取主要读数
  String _extractMainReading(String recognitionResult) {
    if (recognitionResult.isEmpty) return '未识别';
    
    // 尝试提取数字部分
    final RegExp numberRegex = RegExp(r'\d+\.?\d*');
    final match = numberRegex.firstMatch(recognitionResult);
    
    if (match != null) {
      return match.group(0) ?? recognitionResult;
    }
    
    return recognitionResult;
  }

  // 显示记录详情弹窗
  void _showRecordDetail(MeterRecord record) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头部
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getMeterTypeColor(record.meterType),
                      _getMeterTypeColor(record.meterType).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getMeterTypeIcon(record.meterType),
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${record.meterType} 详细信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图片展示
                      if (record.imagePath.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: record.imagePath.startsWith('http')
                                ? Image.network(
                                    record.imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey.shade400,
                                          size: 60,
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(record.imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey.shade400,
                                          size: 60,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],

                      // 识别结果
                      _buildDetailItem(
                        '识别结果',
                        record.recognitionResult,
                        Icons.speed,
                        AppTheme.primaryBlue,
                      ),

                      SizedBox(height: 16),

                      // 新增：API响应详细信息
                      if (record.requestId != null) ...[
                        _buildDetailItem(
                          '请求ID',
                          record.requestId!,
                          Icons.receipt_long,
                          Colors.indigo.shade600,
                        ),
                        SizedBox(height: 16),
                      ],

                      // 读数解析详情
                      if (record.integerPart != null || record.decimalPart != null) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.teal.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.analytics,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    '读数解析',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.teal.shade200),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '整数部分',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            record.integerPart ?? '无',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.teal.shade200),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '小数部分',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            record.decimalPart ?? '无',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // 手动修正标识
                      if (record.isManuallyEdited) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '手动修正',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '此记录的识别结果已被手动修正',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // 识别详情
                      if (record.recognitionDetails != null && record.recognitionDetails!.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.visibility,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    '识别详情',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              ...record.recognitionDetails!.map((detail) {
                                final confidence = (detail.probability * 100).toStringAsFixed(1);
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              detail.className,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              detail.word,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getConfidenceColor(detail.probability),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${confidence}%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],

                      // 表计类型
                      _buildDetailItem(
                        '表计类型',
                        record.meterType,
                        _getMeterTypeIcon(record.meterType),
                        _getMeterTypeColor(record.meterType),
                      ),

                      SizedBox(height: 8),

                      // 记录时间
                      _buildDetailItem(
                        '记录时间',
                        DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp),
                        Icons.access_time,
                        Colors.blue.shade600,
                      ),

                      SizedBox(height: 8),

                      // ID信息
                      _buildDetailItem(
                        '记录ID',
                        record.id,
                        Icons.fingerprint,
                        Colors.purple.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建详情项目 - 紧凑设计
  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
  
  // 辅助方法：根据置信度返回颜色
  Color _getConfidenceColor(double probability) {
    if (probability >= 0.9) {
      return Colors.green; // 高置信度 - 绿色
    } else if (probability >= 0.7) {
      return Colors.orange; // 中等置信度 - 橙色
    } else {
      return Colors.red; // 低置信度 - 红色
    }
  }

  Widget _buildFilterChips() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 筛选标题栏 - 可点击展开收起
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isFilterExpanded = !_isFilterExpanded;
                });
              },
              child: Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '筛选条件',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Spacer(),
                    // 显示当前筛选状态
                    if (_selectedMeterType != null || _selectedFloor != null || 
                        _selectedRoom != null || _selectedMonth != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '已筛选',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    SizedBox(width: 8),
                    Icon(
                      _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 筛选内容区域 - 根据展开状态显示
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: _isFilterExpanded ? null : 0,
            child: _isFilterExpanded ? Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 筛选选项
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 表计类型筛选
                      _buildFilterDropdown(
                        label: '表计类型',
                        value: _selectedMeterType,
                        items: _availableMeterTypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedMeterType = value;
                          });
                          _applyFilters();
                        },
                      ),
                      
                      // 楼层筛选
                      _buildFilterDropdown(
                        label: '楼层',
                        value: _selectedFloor?.toString(),
                        items: _availableFloors.map((f) => f.toString()).toSet().toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFloor = value != null ? int.parse(value) : null;
                            _selectedRoom = null; // 清除房间选择
                          });
                          _updateFilterOptions(); // 更新房间选项
                          _applyFilters();
                        },
                      ),
                      
                      // 房间筛选
                      _buildFilterDropdown(
                        label: '房间号',
                        value: _selectedRoom,
                        items: _availableRooms,
                        onChanged: (value) {
                          setState(() {
                            _selectedRoom = value;
                          });
                          _applyFilters();
                        },
                      ),
                      
                      // 月份筛选
                      _buildFilterDropdown(
                        label: '月份',
                        value: _selectedMonth,
                        items: _availableMonths,
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value;
                            _selectedQuickFilter = null; // 手动选择时清除快捷选择状态
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // 月份快捷选项
                  Text(
                    '快捷选择',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildQuickFilterChip('近三月', () => _selectRecentMonths(3)),
                      _buildQuickFilterChip('近半年', () => _selectRecentMonths(6)),
                      _buildQuickFilterChip('本月', () => _selectCurrentMonth()),
                      _buildQuickFilterChip('上月', () => _selectLastMonth()),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // 操作按钮
                  Row(
                    children: [
                      if (_selectedMeterType != null || _selectedFloor != null || 
                          _selectedRoom != null || _selectedMonth != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: Icon(Icons.clear, size: 16),
                            label: Text('清除筛选'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ) : SizedBox.shrink(),
          ),
          
          // 用量统计
          if (_selectedMonth != null && _filteredRecords.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedMonth}统计',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('记录数量: ${_filteredRecords.length}条'),
                  if (_calculateMonthlyUsage() != null)
                    Text(
                      '月用量: ${_calculateMonthlyUsage()!.toStringAsFixed(2)} ${_selectedMeterType == '燃气' ? '立方米' : '度'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: 120),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('我的记录'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
        elevation: 0,
        actions: [

          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选区域
          _buildFilterChips(),
          
          // 记录列表
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '暂无记录',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Material(
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showRecordDetail(record),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white,
                                          Colors.grey.shade50,
                                        ],
                                      ),

                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 顶部信息行
                                          Row(
                                            children: [
                                              // 表计类型标签 - 更大更醒目
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      _getMeterTypeColor(record.meterType),
                                                      _getMeterTypeColor(record.meterType).withOpacity(0.8),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(25),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _getMeterTypeColor(record.meterType).withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _getMeterTypeIcon(record.meterType),
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      record.meterType,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Spacer(),
                                              // 时间标签
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.schedule,
                                                      size: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      DateFormat('MM-dd HH:mm').format(record.timestamp),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              // 编辑按钮
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(Icons.edit_outlined),
                                                  color: Colors.blue.shade400,
                                                  iconSize: 16,
                                                  onPressed: () => _editRecord(record),
                                                  padding: EdgeInsets.all(4),
                                                  constraints: BoxConstraints(),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              // 删除按钮
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(Icons.delete_outline),
                                                  color: Colors.red.shade400,
                                                  iconSize: 16,
                                                  onPressed: () => _deleteRecord(record),
                                                  padding: EdgeInsets.all(4),
                                                  constraints: BoxConstraints(),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          SizedBox(height: 12),
                                          
                                          // 主要内容区域
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // 左侧图片 - 优化尺寸
                                              if (record.imagePath.isNotEmpty) ...[
                                                Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.08),
                                                        blurRadius: 6,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: record.imagePath.startsWith('http') 
                                                      ? Image.network(
                                                          record.imagePath,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              color: Colors.grey.shade200,
                                                              child: Icon(
                                                                Icons.broken_image,
                                                                color: Colors.grey.shade400,
                                                                size: 32,
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : Image.file(
                                                          File(record.imagePath),
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              color: Colors.grey.shade200,
                                                              child: Icon(
                                                                Icons.image_not_supported,
                                                                color: Colors.grey.shade400,
                                                                size: 32,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                              ],
                                              
                                              // 右侧信息
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // 读数显示 - 紧凑设计
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.primaryBlue,
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Icon(
                                                            Icons.speed,
                                                            size: 14,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          '读数',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            _extractMainReading(record.recognitionResult),
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppTheme.primaryBlue,
                                                              letterSpacing: 0.3,
                                                            ),
                                                            textAlign: TextAlign.right,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    
                                                    SizedBox(height: 8),
                                                    
                                                    // 位置信息 - 紧凑布局
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets.all(4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green.shade600,
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Icon(
                                                            Icons.location_on,
                                                            size: 14,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          '位置',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            '${record.floor}楼 ${record.roomNumber}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.green.shade800,
                                                            ),
                                                            textAlign: TextAlign.right,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        // 查看详情提示
                                                        Container(
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue.shade100,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(
                                                                '详情',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors.blue.shade700,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                                ),
                                                                SizedBox(width: 2),
                                                                Icon(
                                                                  Icons.arrow_forward_ios,
                                                                  size: 10,
                                                                  color: Colors.blue.shade700,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}