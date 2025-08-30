import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meter_record.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MyRecordsScreen extends StatefulWidget {
  @override
  _MyRecordsScreenState createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  List<MeterRecord> _allRecords = [];
  List<MeterRecord> _filteredRecords = [];
  bool _isLoading = true;
  bool _isFilterExpanded = false; // 筛选区域展开状态
  
  // 筛选条件
  String? _selectedMeterType;
  int? _selectedFloor;
  String? _selectedRoom;
  String? _selectedMonth;
  
  // 筛选选项
  List<String> _availableMeterTypes = [];
  List<int> _availableFloors = [];
  List<String> _availableRooms = [];
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records = await StorageService.getMeterRecords();
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
      });
      _applyFilters();
    }
  }

  void _selectCurrentMonth() {
    final currentMonth = DateFormat('yyyy年MM月').format(DateTime.now());
    if (_availableMonths.contains(currentMonth)) {
      setState(() {
        _selectedMonth = currentMonth;
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
      });
      _applyFilters();
    }
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
      labelStyle: TextStyle(
        color: AppTheme.primaryBlue,
        fontSize: 12,
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Future<void> _addTestData() async {
    try {
      final testRecords = [
        MeterRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '1',
          imagePath: '',
          recognitionResult: '12345.67',
          floor: 1,
          roomNumber: '101',
          meterType: '燃气',
          timestamp: DateTime.now().subtract(Duration(days: 5)), base64Image: '',
        ),
        MeterRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '2',
          imagePath: '',
          recognitionResult: '23456.78',
          floor: 2,
          roomNumber: '201',
          meterType: '水表',
          timestamp: DateTime.now().subtract(Duration(days: 3)), base64Image: '',
        ),
        MeterRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '3',
          imagePath: '',
          recognitionResult: '34567.89',
          floor: 1,
          roomNumber: '102',
          meterType: '燃气',
          timestamp: DateTime.now().subtract(Duration(days: 1)), base64Image: '',
        ),
        MeterRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '4',
          imagePath: '',
          recognitionResult: '45678.90',
          floor: 3,
          roomNumber: '301',
          meterType: '水电',
          timestamp: DateTime.now(), base64Image: '',
        ),
      ];

      for (final record in testRecords) {
        await StorageService.saveMeterRecord(record);
      }

      await _loadRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('测试数据已添加')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('添加测试数据失败: $e')),
      );
    }
  }

  Future<void> _deleteRecord(MeterRecord record) async {
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
            icon: Icon(Icons.add_box_outlined),
            onPressed: _addTestData,
            tooltip: '添加测试数据',
          ),
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
                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shadowColor: Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
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
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 顶部信息行
                                      Row(
                                        children: [
                                          // 表计类型标签
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getMeterTypeColor(record.meterType),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getMeterTypeIcon(record.meterType),
                                                  size: 16,
                                                  color: _getMeterTypeTextColor(record.meterType),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  record.meterType,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getMeterTypeTextColor(record.meterType),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Spacer(),
                                          // 删除按钮
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.delete_outline),
                                              color: Colors.red.shade400,
                                              iconSize: 20,
                                              onPressed: () => _deleteRecord(record),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      SizedBox(height: 16),
                                      
                                      // 主要内容区域
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 左侧图片
                                          if (record.imagePath.isNotEmpty) ...[
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 1,
                                                ),
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
                                            SizedBox(width: 16),
                                          ],
                                          
                                          // 右侧信息
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // 读数
                                                Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.speed,
                                                        size: 18,
                                                        color: AppTheme.primaryBlue,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          ' ${record.recognitionResult}',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppTheme.primaryBlue,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                SizedBox(height: 12),
                                                
                                                // 位置信息
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade50,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Icon(
                                                        Icons.location_on,
                                                        size: 16,
                                                        color: Colors.green.shade600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        '${record.floor}楼 ${record.roomNumber}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                
                                                SizedBox(height: 8),
                                                
                                                // 时间信息
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Icon(
                                                        Icons.access_time,
                                                        size: 16,
                                                        color: Colors.blue.shade600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        DateFormat('MM-dd HH:mm').format(record.timestamp),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
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