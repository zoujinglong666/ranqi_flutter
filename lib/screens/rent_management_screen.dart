import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rent_record.dart';
import '../models/rent_config.dart';
import '../models/room.dart';
import '../services/storage_service.dart';
import '../services/event_manager.dart';
import '../theme/app_theme.dart';

class RentManagementScreen extends StatefulWidget {
  @override
  _RentManagementScreenState createState() => _RentManagementScreenState();
}

class _RentManagementScreenState extends State<RentManagementScreen> {
  List<RentRecord> _rentRecords = [];
  List<RentConfig> _rentConfigs = [];
  List<Room> _availableRooms = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  int _selectedTabIndex = 0; // 0: 租金配置, 1: 月度记录
  
  // 事件订阅
  StreamSubscription<EventData>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToEvents();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToEvents() {
    _eventSubscription = eventManager.subscribeMultiple(
      [EventType.recordAdded, EventType.recordUpdated, EventType.recordDeleted],
      (eventData) {
        if (mounted) {
          _loadData();
        }
      },
    ).first;
  }

  Future<void> _loadData() async {
    try {
      final rentRecords = await StorageService.getRentRecords();
      final rentConfigs = await StorageService.getRentConfigs();
      final rooms = await StorageService.getRooms();
      
      setState(() {
        _rentRecords = rentRecords;
        _rentConfigs = rentConfigs;
        _availableRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败: $e')),
      );
    }
  }

  List<RentRecord> _getRecordsForMonth(DateTime month) {
    return _rentRecords.where((record) => 
      record.month.year == month.year && 
      record.month.month == month.month
    ).toList();
  }

  List<RentConfig> _getConfigsForRoom(Room room) {
    return _rentConfigs.where((config) => 
      config.floor == room.floor && 
      config.roomNumber == room.roomNumber &&
      config.isActive
    ).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  Future<void> _addOrUpdateRentConfig(Room room, [RentConfig? existingConfig]) async {
    final TextEditingController rentController = TextEditingController(
      text: existingConfig?.rentAmount.toString() ?? ''
    );
    final TextEditingController notesController = TextEditingController(
      text: existingConfig?.notes ?? ''
    );
    
    DateTime selectedStartDate = existingConfig?.startDate ?? DateTime.now();
    DateTime? selectedEndDate = existingConfig?.endDate;
    bool hasEndDate = selectedEndDate != null;

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // 标题
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          '${existingConfig != null ? '编辑' : '添加'}租金配置',
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
                    
                    // 房间信息
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: AppTheme.primaryBlue),
                          SizedBox(width: 8),
                          Text(
                            '${room.floor}楼 ${room.roomNumber}房间',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // 租金金额输入
                    Text(
                      '租金金额',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: rentController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '请输入租金金额',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: '元',
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // 生效日期
                    Text(
                      '生效开始日期',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedStartDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text(
                              DateFormat('yyyy年MM月dd日').format(selectedStartDate),
                              style: TextStyle(fontSize: 16),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // 结束日期选项
                    Row(
                      children: [
                        Checkbox(
                          value: hasEndDate,
                          onChanged: (value) {
                            setModalState(() {
                              hasEndDate = value ?? false;
                              if (!hasEndDate) {
                                selectedEndDate = null;
                              } else {
                                selectedEndDate = selectedStartDate.add(Duration(days: 365));
                              }
                            });
                          },
                        ),
                        Text(
                          '设置结束日期',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    
                    if (hasEndDate) ...[
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedEndDate ?? selectedStartDate.add(Duration(days: 365)),
                            firstDate: selectedStartDate,
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedEndDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                              SizedBox(width: 8),
                              Text(
                                DateFormat('yyyy年MM月dd日').format(selectedEndDate!),
                                style: TextStyle(fontSize: 16),
                              ),
                              Spacer(),
                              Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    
                    // 备注输入
                    Text(
                      '备注',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '请输入备注信息（可选）',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // 操作按钮
                    Row(
                      children: [
                        if (existingConfig != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await StorageService.deleteRentConfig(existingConfig.id);
                                Navigator.of(context).pop();
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('租金配置已删除')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('删除'),
                            ),
                          ),
                        if (existingConfig != null) SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final rentAmountText = rentController.text.trim();
                              if (rentAmountText.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('请输入租金金额')),
                                );
                                return;
                              }
                              
                              final rentAmount = double.tryParse(rentAmountText);
                              if (rentAmount == null || rentAmount < 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('请输入有效的租金金额')),
                                );
                                return;
                              }
                              
                              final now = DateTime.now();
                              final config = RentConfig(
                                id: existingConfig?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                floor: room.floor,
                                roomNumber: room.roomNumber,
                                rentAmount: rentAmount,
                                startDate: selectedStartDate,
                                endDate: selectedEndDate,
                                createdAt: existingConfig?.createdAt ?? now,
                                updatedAt: now,
                                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                              );
                              
                              if (existingConfig != null) {
                                await StorageService.updateRentConfig(config);
                                eventManager.publish(EventType.recordUpdated, data: {
                                  'type': 'rent_config',
                                  'floor': config.floor,
                                  'roomNumber': config.roomNumber,
                                });
                              } else {
                                await StorageService.saveRentConfig(config);
                                eventManager.publish(EventType.recordAdded, data: {
                                  'type': 'rent_config',
                                  'floor': config.floor,
                                  'roomNumber': config.roomNumber,
                                });
                              }
                              
                              Navigator.of(context).pop();
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('租金配置已${existingConfig != null ? '更新' : '保存'}')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(existingConfig != null ? '更新' : '保存'),
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
        );
      },
    );
  }

  Future<void> _addOrUpdateRentRecord(Room room) async {
    final existingRecord = await StorageService.getRentRecord(
      room.floor, 
      room.roomNumber, 
      _selectedMonth
    );
    
    final TextEditingController rentController = TextEditingController(
      text: existingRecord?.rentAmount.toString() ?? ''
    );
    final TextEditingController notesController = TextEditingController(
      text: existingRecord?.notes ?? ''
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 标题
                Row(
                  children: [
                    Icon(
                      Icons.home,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${existingRecord != null ? '编辑' : '添加'}租金记录',
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
                
                // 房间信息
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        '${room.floor}楼 ${room.roomNumber}房间',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        DateFormat('yyyy年MM月').format(_selectedMonth),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // 租金金额输入
                Text(
                  '租金金额',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: rentController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '请输入租金金额',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixText: '元',
                  ),
                ),
                SizedBox(height: 16),
                
                // 备注输入
                Text(
                  '备注',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '请输入备注信息（可选）',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // 操作按钮
                Row(
                  children: [
                    if (existingRecord != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await StorageService.deleteRentRecord(existingRecord.id);
                            Navigator.of(context).pop();
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('租金记录已删除')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('删除'),
                        ),
                      ),
                    if (existingRecord != null) SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final rentAmountText = rentController.text.trim();
                          if (rentAmountText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('请输入租金金额')),
                            );
                            return;
                          }
                          
                          final rentAmount = double.tryParse(rentAmountText);
                          if (rentAmount == null || rentAmount < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('请输入有效的租金金额')),
                            );
                            return;
                          }
                          
                          final now = DateTime.now();
                          final record = RentRecord(
                            id: existingRecord?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            floor: room.floor,
                            roomNumber: room.roomNumber,
                            rentAmount: rentAmount,
                            month: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
                            createdAt: existingRecord?.createdAt ?? now,
                            updatedAt: now,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );
                          
                          if (existingRecord != null) {
                            await StorageService.updateRentRecord(record);
                            eventManager.publish(EventType.recordUpdated, data: {
                              'type': 'rent_record',
                              'floor': record.floor,
                              'roomNumber': record.roomNumber,
                              'month': record.month,
                            });
                          } else {
                            await StorageService.saveRentRecord(record);
                            eventManager.publish(EventType.recordAdded, data: {
                              'type': 'rent_record',
                              'floor': record.floor,
                              'roomNumber': record.roomNumber,
                              'month': record.month,
                            });
                          }
                          
                          Navigator.of(context).pop();
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('租金记录已${existingRecord != null ? '更新' : '保存'}')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(existingRecord != null ? '更新' : '保存'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '租金管理',
            style: TextStyle(
              fontSize: AppTheme.fontSizeTitle,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryBlue,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final monthRecords = _getRecordsForMonth(_selectedMonth);
    final recordsMap = {for (var record in monthRecords) '${record.floor}-${record.roomNumber}': record};

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '租金管理',
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
              icon: Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.receipt_long),
                text: '租金记录',
              ),
              Tab(
                icon: Icon(Icons.schedule),
                text: '租金配置',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 租金记录Tab
            Column(
              children: [
                // 月份选择器
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: AppTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        '选择月份：',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedMonth,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              initialDatePickerMode: DatePickerMode.year,
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedMonth = DateTime(picked.year, picked.month, 1);
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat('yyyy年MM月').format(_selectedMonth),
                                  style: TextStyle(fontSize: 16),
                                ),
                                Spacer(),
                                Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 房间列表
                 Expanded(
                   child: _availableRooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '暂无房间信息',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '请先在楼层管理中添加房间',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _availableRooms.length,
                           itemBuilder: (context, index) {
                             final room = _availableRooms[index];
                            final recordKey = '${room.floor}-${room.roomNumber}';
                            final rentRecord = recordsMap[recordKey];
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: rentRecord != null 
                                        ? AppTheme.primaryBlue.withOpacity(0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.home,
                                    color: rentRecord != null 
                                        ? AppTheme.primaryBlue
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                title: Text(
                                  '${room.floor}楼 ${room.roomNumber}房间',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    if (rentRecord != null) ...[
                                      Text(
                                        '租金：¥${rentRecord.rentAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (rentRecord.notes != null && rentRecord.notes!.isNotEmpty)
                                        Text(
                                          '备注：${rentRecord.notes}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ] else
                                      Text(
                                        '未设置租金',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Icon(
                                  rentRecord != null ? Icons.edit : Icons.add,
                                  color: AppTheme.primaryBlue,
                                ),
                                onTap: () => _addOrUpdateRentRecord(room),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            
            // 租金配置Tab
             _availableRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '暂无房间信息',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '请先在楼层管理中添加房间',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _availableRooms.length,
                     itemBuilder: (context, index) {
                       final room = _availableRooms[index];
                      final configs = _getConfigsForRoom(room);
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 房间标题
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.05),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.home,
                                    color: AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${room.floor}楼 ${room.roomNumber}房间',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    onPressed: () => _addOrUpdateRentConfig(room),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 配置列表
                            if (configs.isEmpty)
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        size: 32,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '暂无租金配置',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () => _addOrUpdateRentConfig(room),
                                        child: Text('添加配置'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...configs.map((config) {
                                final isCurrentlyActive = config.isValidForDate(DateTime.now());
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCurrentlyActive 
                                        ? AppTheme.primaryBlue.withOpacity(0.05)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrentlyActive 
                                          ? AppTheme.primaryBlue.withOpacity(0.3)
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _addOrUpdateRentConfig(room, config),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.attach_money,
                                              size: 16,
                                              color: isCurrentlyActive 
                                                  ? AppTheme.primaryBlue
                                                  : Colors.grey.shade600,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '¥${config.rentAmount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isCurrentlyActive 
                                                    ? AppTheme.primaryBlue
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                            if (isCurrentlyActive) ...[
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryBlue,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '当前',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            Spacer(),
                                            Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.grey.shade500,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey.shade500,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              DateFormat('yyyy/MM/dd').format(config.startDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              ' - ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              config.endDate != null 
                                                  ? DateFormat('yyyy/MM/dd').format(config.endDate!)
                                                  : '无限期',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (config.notes != null && config.notes!.isNotEmpty) ...[
                                          SizedBox(height: 4),
                                          Text(
                                            config.notes!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}