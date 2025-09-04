import 'package:flutter/material.dart';

import '../models/meter_record.dart';
import '../models/room.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class RoomsOverviewScreen extends StatefulWidget {
  @override
  _RoomsOverviewScreenState createState() => _RoomsOverviewScreenState();
}

class _RoomsOverviewScreenState extends State<RoomsOverviewScreen> {
  List<Room> _rooms = [];
  List<MeterRecord> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, with_records, without_records

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rooms = await StorageService.getRooms();
      final records = await StorageService.getMeterRecords();
      setState(() {
        _rooms = rooms;
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Room> get _filteredRooms {
    var filtered = _rooms.where((room) {
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!room.name.toLowerCase().contains(query) &&
            !room.floorName.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 记录状态过滤
      if (_selectedFilter != 'all') {
        final hasRecords =
            _records.any((record) => record.roomName == room.name);
        if (_selectedFilter == 'with_records' && !hasRecords) {
          return false;
        }
        if (_selectedFilter == 'without_records' && hasRecords) {
          return false;
        }
      }

      return true;
    }).toList();

    // 按楼层和房间名排序
    filtered.sort((a, b) {
      final floorCompare = a.floorName.compareTo(b.floorName);
      if (floorCompare != 0) return floorCompare;
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  Map<String, List<Room>> get _groupedRooms {
    final grouped = <String, List<Room>>{};
    for (final room in _filteredRooms) {
      if (!grouped.containsKey(room.floorName)) {
        grouped[room.floorName] = [];
      }
      grouped[room.floorName]!.add(room);
    }
    return grouped;
  }

  int _getRoomRecordCount(String roomName) {
    return _records.where((record) => record.roomName == roomName).length;
  }

  MeterRecord? _getLatestRecord(String roomName) {
    final roomRecords =
        _records.where((record) => record.roomName == roomName).toList();
    if (roomRecords.isEmpty) return null;
    roomRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return roomRecords.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('房间概览'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计和搜索区域
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // 统计卡片
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '总房间',
                        _rooms.length.toString(),
                        Icons.home,
                        AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '有记录',
                        _rooms
                            .where((room) => _getRoomRecordCount(room.name) > 0)
                            .length
                            .toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '无记录',
                        _rooms
                            .where(
                                (room) => _getRoomRecordCount(room.name) == 0)
                            .length
                            .toString(),
                        Icons.warning,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // 搜索框
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索房间或楼层...',
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
                    Text('状态: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', '全部'),
                            SizedBox(width: 8),
                            _buildFilterChip('with_records', '有记录'),
                            SizedBox(width: 8),
                            _buildFilterChip('without_records', '无记录'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 房间列表
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredRooms.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _groupedRooms.keys.length,
                          itemBuilder: (context, index) {
                            final floorName =
                                _groupedRooms.keys.elementAt(index);
                            final floorRooms = _groupedRooms[floorName]!;
                            return _buildFloorSection(floorName, floorRooms);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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

  Widget _buildFloorSection(String floorName, List<Room> rooms) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 楼层标题
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.apartment,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  floorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rooms.length}间',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 房间列表
          ...rooms.map((room) => _buildRoomItem(room)).toList(),
        ],
      ),
    );
  }

  Widget _buildRoomItem(Room room) {
    final recordCount = _getRoomRecordCount(room.roomNumber);
    final latestRecord = _getLatestRecord(room.roomNumber);
    final hasRecords = recordCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 房间图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasRecords
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasRecords ? Icons.home : Icons.home_outlined,
              color: hasRecords ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          SizedBox(width: 12),

          // 房间信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.roomNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '$recordCount 条记录',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (latestRecord != null) ...[
                      SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _formatDateTime(latestRecord.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 状态指示器
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasRecords
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hasRecords ? '有记录' : '无记录',
              style: TextStyle(
                color: hasRecords ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                ? '没有找到匹配的房间'
                : '暂无房间',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedFilter != 'all') ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'all';
                });
              },
              child: Text('清除筛选'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
