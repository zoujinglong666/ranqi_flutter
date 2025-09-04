import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../models/meter_record.dart';

class MonthlyRecordsScreen extends StatefulWidget {
  @override
  _MonthlyRecordsScreenState createState() => _MonthlyRecordsScreenState();
}

class _MonthlyRecordsScreenState extends State<MonthlyRecordsScreen> {
  List<MeterRecord> _allRecords = [];
  List<MeterRecord> _monthlyRecords = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  String _searchQuery = '';
  String _selectedFilter = 'all';

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
        _filterRecordsByMonth();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRecordsByMonth() {
    _monthlyRecords = _allRecords.where((record) {
      return record.timestamp.year == _selectedMonth.year &&
             record.timestamp.month == _selectedMonth.month;
    }).toList();
    
    // 按时间倒序排列
    _monthlyRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<MeterRecord> get _filteredRecords {
    var filtered = _monthlyRecords.where((record) {
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!record.roomName.toLowerCase().contains(query) &&
            !record.meterReading.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // 类型过滤
      if (_selectedFilter != 'all') {
        if (record.meterType != _selectedFilter) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('本月记录'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: _showMonthPicker,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: Column(
        children: [
          // 月份选择和统计
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // 月份显示
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      '${_selectedMonth.year}年${_selectedMonth.month}月',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: _showMonthPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '切换月份',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // 统计卡片
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '本月记录',
                        _monthlyRecords.length.toString(),
                        Icons.assessment,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '燃气表',
                        _monthlyRecords.where((r) => r.meterType == 'gas').length.toString(),
                        Icons.local_gas_station,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '水表',
                        _monthlyRecords.where((r) => r.meterType == 'water').length.toString(),
                        Icons.water_drop,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // 搜索框
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索房间或读数...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 12),
                
                // 过滤器
                Row(
                  children: [
                    Text('类型: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', '全部'),
                            SizedBox(width: 8),
                            _buildFilterChip('gas', '燃气表'),
                            SizedBox(width: 8),
                            _buildFilterChip('water', '水表'),
                            SizedBox(width: 8),
                            _buildFilterChip('electric', '电表'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 记录列表
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            return _buildRecordCard(_filteredRecords[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(MeterRecord record) {
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMeterTypeColor(record.meterType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getMeterTypeLabel(record.meterType),
                    style: TextStyle(
                      color: _getMeterTypeColor(record.meterType),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  _formatDateTime(record.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 4),
                Text(
                  record.roomName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.speed_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 4),
                Text(
                  '读数: ${record.meterReading}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '${_selectedMonth.month}月暂无记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: _showMonthPicker,
            child: Text('选择其他月份'),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择月份'),
        content: Container(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            selectedDate: _selectedMonth,
            onChanged: (date) {
              Navigator.pop(context);
              setState(() {
                _selectedMonth = DateTime(date.year, date.month);
                _filterRecordsByMonth();
              });
            },
          ),
        ),
      ),
    );
  }

  Color _getMeterTypeColor(String type) {
    switch (type) {
      case 'gas':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'electric':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getMeterTypeLabel(String type) {
    switch (type) {
      case 'gas':
        return '燃气表';
      case 'water':
        return '水表';
      case 'electric':
        return '电表';
      default:
        return '未知';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}