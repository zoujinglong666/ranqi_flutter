import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/meter_record.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MeterRecordsScreen extends StatefulWidget {
  final Room room;

  const MeterRecordsScreen({Key? key, required this.room}) : super(key: key);

  @override
  _MeterRecordsScreenState createState() => _MeterRecordsScreenState();
}

class _MeterRecordsScreenState extends State<MeterRecordsScreen> {
  List<MeterRecord> _records = [];
  bool _isLoading = true;
  String _selectedMeterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadMeterRecords();
  }

  Future<void> _loadMeterRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await StorageService.getMeterRecords();
      final roomRecords = records.where((record) => 
        record.floor == widget.room.floor && 
        record.roomNumber == widget.room.roomNumber
      ).toList();
      roomRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      setState(() {
        _records = roomRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载抄表记录失败: $e')),
      );
    }
  }

  List<MeterRecord> get _filteredRecords {
    if (_selectedMeterType == 'all') {
      return _records;
    }
    return _records.where((record) => record.meterType == _selectedMeterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.room.roomNumber} - 抄表记录',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadMeterRecords,
            icon: Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选器
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '表计类型筛选',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', '全部', Icons.all_inclusive),
                      SizedBox(width: 8),
                      _buildFilterChip('water', '水表', Icons.water_drop),
                      SizedBox(width: 8),
                      _buildFilterChip('electricity', '电表', Icons.electric_bolt),
                      SizedBox(width: 8),
                      _buildFilterChip('gas', '燃气表', Icons.local_fire_department),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 记录列表
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryBlue),
                        SizedBox(height: 16),
                        Text(
                          '加载中...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMeterRecords,
                        color: AppTheme.primaryBlue,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return _buildRecordCard(record, index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedMeterType == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedMeterType = value;
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.primaryBlue,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryBlue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            _selectedMeterType == 'all' ? '暂无抄表记录' : '暂无${_getMeterTypeName(_selectedMeterType)}记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请先进行抄表操作',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(MeterRecord record, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部信息
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMeterTypeColor(record.meterType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMeterTypeIcon(record.meterType),
                        size: 16,
                        color: _getMeterTypeColor(record.meterType),
                      ),
                      SizedBox(width: 4),
                      Text(
                        _getMeterTypeName(record.meterType),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getMeterTypeColor(record.meterType),
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Text(
                  '#${(_records.length - index).toString().padLeft(3, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // 读数信息
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '识别结果',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        record.recognitionResult ?? '未识别',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade200,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '抄表时间',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${record.timestamp.year}-${record.timestamp.month.toString().padLeft(2, '0')}-${record.timestamp.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (record.integerPart != null || record.decimalPart != null) ...[
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              // 详细读数
              Row(
                children: [
                  if (record.integerPart != null) ...[
                    Expanded(
                      child: _buildDetailItem('整数部分', record.integerPart.toString()),
                    ),
                  ],
                  if (record.integerPart != null && record.decimalPart != null)
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade200,
                      margin: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  if (record.decimalPart != null) ...[
                    Expanded(
                      child: _buildDetailItem('小数部分', record.decimalPart.toString()),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getMeterTypeName(String meterType) {
    switch (meterType) {
      case 'water':
        return '水表';
      case 'electricity':
        return '电表';
      case 'gas':
        return '燃气表';
      default:
        return '未知';
    }
  }

  IconData _getMeterTypeIcon(String meterType) {
    switch (meterType) {
      case 'water':
        return Icons.water_drop;
      case 'electricity':
        return Icons.electric_bolt;
      case 'gas':
        return Icons.local_fire_department;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getMeterTypeColor(String meterType) {
    switch (meterType) {
      case 'water':
        return Colors.blue;
      case 'electricity':
        return Colors.orange;
      case 'gas':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}