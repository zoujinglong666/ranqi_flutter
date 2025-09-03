import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room.dart';
import '../models/meter_record.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'meter_records_screen.dart';
import 'monthly_report_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;

  const RoomDetailScreen({Key? key, required this.room}) : super(key: key);

  @override
  _RoomDetailScreenState createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Room? _currentRoom;
  List<MeterRecord> _lastMonthRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentRoom = widget.room;
    _loadRoomData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomData() async {
    setState(() => _isLoading = true);
    
    try {
      // 加载房间最新信息
      final rooms = await StorageService.getRooms();
      final updatedRoom = rooms.firstWhere(
        (r) => r.id == widget.room.id,
        orElse: () => widget.room,
      );
      
      // 加载上月抄表记录
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      final records = await StorageService.getMeterRecords();
      final lastMonthRecords = records.where((record) {
        return record.floor == updatedRoom.floor &&
               record.roomNumber == updatedRoom.roomNumber &&
               record.timestamp.year == lastMonth.year &&
               record.timestamp.month == lastMonth.month;
      }).toList();
      
      setState(() {
        _currentRoom = updatedRoom;
        _lastMonthRecords = lastMonthRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoom == null) {
      return Scaffold(
        appBar: AppBar(title: Text('房间详情')),
        body: Center(child: Text('房间信息不存在')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        ),
        title: Text(
          '${_currentRoom!.floor}楼-${_currentRoom!.roomNumber}',
          style: TextStyle(
            fontSize: AppTheme.fontSizeTitle,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _shareRoomInfo,
            icon: Icon(Icons.share, color: AppTheme.primaryBlue),
          ),
          IconButton(
            onPressed: _exportRoomReport,
            icon: Icon(Icons.download, color: AppTheme.primaryBlue),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryBlue,
          tabs: [
            Tab(text: '租户信息'),
            Tab(text: '费用设置'),
            Tab(text: '抄表记录'),
            Tab(text: '月度报表'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTenantInfoTab(),
                _buildFeeSettingsTab(),
                _buildMeterRecordsTab(),
                _buildMonthlyReportTab(),
              ],
            ),
    );
  }

  Widget _buildTenantInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: '租户信息',
            icon: Icons.person,
            child: Column(
              children: [
                _buildInfoRow('入住人', _currentRoom!.occupantName ?? '未设置'),
                _buildInfoRow('联系电话', _currentRoom!.contactPhone ?? '未设置'),
                _buildInfoRow('微信号', _currentRoom!.wechatId ?? '未设置'),
                _buildInfoRow(
                  '入住日期',
                  _currentRoom!.checkInDate != null
                      ? '${_currentRoom!.checkInDate!.year}-${_currentRoom!.checkInDate!.month.toString().padLeft(2, '0')}-${_currentRoom!.checkInDate!.day.toString().padLeft(2, '0')}'
                      : '未设置',
                ),
                _buildInfoRow('备注信息', _currentRoom!.checkInInfo ?? '无'),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingL),
          _buildActionButton(
            '编辑租户信息',
            Icons.edit,
            () => _editTenantInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: '租金设置',
            icon: Icons.home,
            child: Column(
              children: [
                _buildInfoRow('月租金', _currentRoom!.monthlyRent != null ? '¥${_currentRoom!.monthlyRent!.toStringAsFixed(2)}' : '未设置'),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingM),
          _buildInfoCard(
            title: '费用设置',
            icon: Icons.receipt,
            child: Column(
              children: [
                _buildInfoRow('服务费', _currentRoom!.serviceFee != null ? '¥${_currentRoom!.serviceFee!.toStringAsFixed(2)}' : '未设置'),
                _buildInfoRow('卫生费', _currentRoom!.cleaningFee != null ? '¥${_currentRoom!.cleaningFee!.toStringAsFixed(2)}' : '未设置'),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingM),
          _buildInfoCard(
            title: '单价设置',
            icon: Icons.calculate,
            child: Column(
              children: [
                _buildInfoRow('水费单价', _currentRoom!.waterPricePerTon != null ? '¥${_currentRoom!.waterPricePerTon!.toStringAsFixed(2)}/吨' : '未设置'),
                _buildInfoRow('电费单价', _currentRoom!.electricityPricePerKwh != null ? '¥${_currentRoom!.electricityPricePerKwh!.toStringAsFixed(2)}/度' : '未设置'),
                _buildInfoRow('燃气单价', _currentRoom!.gasPricePerCubicMeter != null ? '¥${_currentRoom!.gasPricePerCubicMeter!.toStringAsFixed(2)}/立方米' : '未设置'),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingL),
          _buildActionButton(
            '编辑费用设置',
            Icons.edit,
            () => _editFeeSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterRecordsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '上月抄表记录',
            style: TextStyle(
              fontSize: AppTheme.fontSizeTitle,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: AppTheme.spacingM),
          if (_lastMonthRecords.isEmpty)
            _buildEmptyState('暂无上月抄表记录')
          else
            ..._lastMonthRecords.map((record) => _buildMeterRecordCard(record)),
          SizedBox(height: AppTheme.spacingL),
          _buildActionButton(
            '查看所有抄表记录',
            Icons.history,
            () => _viewAllMeterRecords(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '月度报表',
            style: TextStyle(
              fontSize: AppTheme.fontSizeTitle,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: AppTheme.spacingM),
          _buildInfoCard(
            title: '快速操作',
            icon: Icons.flash_on,
            child: Column(
              children: [
                _buildActionButton(
                  '生成本月报表',
                  Icons.description,
                  () => _generateMonthlyReport(),
                ),
                SizedBox(height: AppTheme.spacingM),
                _buildActionButton(
                  '导出Excel报表',
                  Icons.table_chart,
                  () => _exportExcelReport(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppTheme.spacingM),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSubtitle,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              0,
              AppTheme.spacingL,
              AppTheme.spacingL,
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: AppTheme.spacingS),
            Text(
              text,
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeterRecordCard(MeterRecord record) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
              SizedBox(width: AppTheme.spacingS),
              Text(
                '${record.timestamp.year}-${record.timestamp.month.toString().padLeft(2, '0')}-${record.timestamp.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeCaption,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              if (record.meterType == '水表')
                Expanded(
                  child: _buildMeterItem('水表', '${record.recognitionResult}吨', Icons.water_drop),
                ),
              if (record.meterType == '电表')
                Expanded(
                  child: _buildMeterItem('电表', '${record.recognitionResult}度', Icons.electric_bolt),
                ),
              if (record.meterType == '燃气')
                Expanded(
                  child: _buildMeterItem('燃气', '${record.recognitionResult}立方米', Icons.local_fire_department),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeterItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: 24,
        ),
        SizedBox(height: AppTheme.spacingXS),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeCaption,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: AppTheme.spacingM),
          Text(
            message,
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacingM),
          Text(
            '点击上方按钮开始添加抄表记录',
            style: TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 编辑租户信息
  void _editTenantInfo() async {
    final occupantNameController = TextEditingController(text: _currentRoom!.occupantName ?? '');
    final contactPhoneController = TextEditingController(text: _currentRoom!.contactPhone ?? '');
    final wechatIdController = TextEditingController(text: _currentRoom!.wechatId ?? '');
    final checkInDateController = TextEditingController(
      text: _currentRoom!.checkInDate != null 
        ? '${_currentRoom!.checkInDate!.year}-${_currentRoom!.checkInDate!.month.toString().padLeft(2, '0')}-${_currentRoom!.checkInDate!.day.toString().padLeft(2, '0')}'
        : ''
    );
    final checkInInfoController = TextEditingController(text: _currentRoom!.checkInInfo ?? '');

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
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
                      '编辑租户信息',
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
                      _buildEditField(
                        controller: occupantNameController,
                        label: '入住人姓名',
                        hint: '请输入入住人姓名',
                        icon: Icons.person,
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: contactPhoneController,
                        label: '联系电话',
                        hint: '请输入联系电话',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: wechatIdController,
                        label: '微信号',
                        hint: '请输入微信号',
                        icon: Icons.wechat,
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: widget.room.checkInDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            checkInDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          }
                        },
                        child: AbsorbPointer(
                          child: _buildEditField(
                            controller: checkInDateController,
                            label: '入住日期',
                            hint: '请选择入住日期',
                            icon: Icons.calendar_today,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: checkInInfoController,
                        label: '入住信息',
                        hint: '请输入入住信息',
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
                          final occupantName = occupantNameController.text.trim().isEmpty ? null : occupantNameController.text.trim();
                          final contactPhone = contactPhoneController.text.trim().isEmpty ? null : contactPhoneController.text.trim();
                          final wechatId = wechatIdController.text.trim().isEmpty ? null : wechatIdController.text.trim();
                          final checkInInfo = checkInInfoController.text.trim().isEmpty ? null : checkInInfoController.text.trim();
                          
                          DateTime? checkInDate;
                          if (checkInDateController.text.trim().isNotEmpty) {
                            try {
                              final parts = checkInDateController.text.split('-');
                              checkInDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                            } catch (e) {
                              checkInDate = null;
                            }
                          }
                          
                          Navigator.of(context).pop({
                            'occupantName': occupantName,
                            'contactPhone': contactPhone,
                            'wechatId': wechatId,
                            'checkInDate': checkInDate,
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
                              '保存',
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
      // 更新房间信息
      final updatedRoom = Room(
        id: widget.room.id,
        floor: widget.room.floor,
        roomNumber: widget.room.roomNumber,
        waterPricePerTon: widget.room.waterPricePerTon,
        electricityPricePerKwh: widget.room.electricityPricePerKwh,
        gasPricePerCubicMeter: widget.room.gasPricePerCubicMeter,
        initialWaterAmount: widget.room.initialWaterAmount,
        initialElectricityAmount: widget.room.initialElectricityAmount,
        initialGasAmount: widget.room.initialGasAmount,
        occupantName: result['occupantName'],
        contactPhone: result['contactPhone'],
        wechatId: result['wechatId'],
        checkInDate: result['checkInDate'],
        checkInInfo: result['checkInInfo'],
        monthlyRent: widget.room.monthlyRent,
        serviceFee: widget.room.serviceFee,
        cleaningFee: widget.room.cleaningFee,
      );

      // 保存到存储
      final rooms = await StorageService.getRooms();
      final index = rooms.indexWhere((r) => r.id == widget.room.id);
      if (index != -1) {
        rooms[index] = updatedRoom;
        await StorageService.saveRooms(rooms);
        
        // 更新当前页面状态
        setState(() {
          _currentRoom = updatedRoom;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('租户信息更新成功')),
        );
      }
    }
  }

  // 编辑费用设置
  void _editFeeSettings() async {
    final waterPriceController = TextEditingController(text: _currentRoom!.waterPricePerTon?.toString() ?? '');
    final electricityPriceController = TextEditingController(text: _currentRoom!.electricityPricePerKwh?.toString() ?? '');
    final gasPriceController = TextEditingController(text: _currentRoom!.gasPricePerCubicMeter?.toString() ?? '');
    final monthlyRentController = TextEditingController(text: _currentRoom!.monthlyRent?.toString() ?? '');
    final serviceFeeController = TextEditingController(text: _currentRoom!.serviceFee?.toString() ?? '');
    final cleaningFeeController = TextEditingController(text: _currentRoom!.cleaningFee?.toString() ?? '');
    final initialWaterController = TextEditingController(text: _currentRoom!.initialWaterAmount?.toString() ?? '');
    final initialElectricityController = TextEditingController(text: _currentRoom!.initialElectricityAmount?.toString() ?? '');
    final initialGasController = TextEditingController(text: _currentRoom!.initialGasAmount?.toString() ?? '');

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
                      Icons.settings,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      '编辑费用设置',
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
                      // 单价设置
                      Text(
                        '单价设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildEditField(
                        controller: waterPriceController,
                        label: '水费单价 (元/吨)',
                        hint: '请输入水费单价',
                        icon: Icons.water_drop,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: electricityPriceController,
                        label: '电费单价 (元/度)',
                        hint: '请输入电费单价',
                        icon: Icons.electric_bolt,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: gasPriceController,
                        label: '燃气单价 (元/立方米)',
                        hint: '请输入燃气单价',
                        icon: Icons.local_fire_department,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 32),
                      // 初始读数设置
                      Text(
                        '初始读数设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildEditField(
                        controller: initialWaterController,
                        label: '初始水表读数',
                        hint: '请输入初始水表读数',
                        icon: Icons.water_drop_outlined,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: initialElectricityController,
                        label: '初始电表读数',
                        hint: '请输入初始电表读数',
                        icon: Icons.electric_meter,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: initialGasController,
                        label: '初始燃气表读数',
                        hint: '请输入初始燃气表读数',
                        icon: Icons.gas_meter,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 32),
                      // 其他费用设置
                      Text(
                        '其他费用设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildEditField(
                        controller: monthlyRentController,
                        label: '月租金 (元)',
                        hint: '请输入月租金',
                        icon: Icons.home,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: serviceFeeController,
                        label: '服务费 (元)',
                        hint: '请输入服务费',
                        icon: Icons.room_service,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 20),
                      _buildEditField(
                        controller: cleaningFeeController,
                        label: '清洁费 (元)',
                        hint: '请输入清洁费',
                        icon: Icons.cleaning_services,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          double? parseDouble(String text) {
                            if (text.trim().isEmpty) return null;
                            return double.tryParse(text.trim());
                          }
                          
                          Navigator.of(context).pop({
                            'waterPricePerTon': parseDouble(waterPriceController.text),
                            'electricityPricePerKwh': parseDouble(electricityPriceController.text),
                            'gasPricePerCubicMeter': parseDouble(gasPriceController.text),
                            'monthlyRent': parseDouble(monthlyRentController.text),
                            'serviceFee': parseDouble(serviceFeeController.text),
                            'cleaningFee': parseDouble(cleaningFeeController.text),
                            'initialWaterAmount': parseDouble(initialWaterController.text),
                            'initialElectricityAmount': parseDouble(initialElectricityController.text),
                            'initialGasAmount': parseDouble(initialGasController.text),
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
                              '保存',
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
      // 更新房间信息
      final updatedRoom = Room(
        id: widget.room.id,
        floor: widget.room.floor,
        roomNumber: widget.room.roomNumber,
        waterPricePerTon: result['waterPricePerTon'],
        electricityPricePerKwh: result['electricityPricePerKwh'],
        gasPricePerCubicMeter: result['gasPricePerCubicMeter'],
        initialWaterAmount: result['initialWaterAmount'],
        initialElectricityAmount: result['initialElectricityAmount'],
        initialGasAmount: result['initialGasAmount'],
        occupantName: widget.room.occupantName,
        contactPhone: widget.room.contactPhone,
        wechatId: widget.room.wechatId,
        checkInDate: widget.room.checkInDate,
        checkInInfo: widget.room.checkInInfo,
        monthlyRent: result['monthlyRent'],
        serviceFee: result['serviceFee'],
        cleaningFee: result['cleaningFee'],
      );

      // 保存到存储
      final rooms = await StorageService.getRooms();
      final index = rooms.indexWhere((r) => r.id == widget.room.id);
      if (index != -1) {
        rooms[index] = updatedRoom;
        await StorageService.saveRooms(rooms);
        
        // 更新当前页面状态
        setState(() {
          _currentRoom = updatedRoom;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('费用设置更新成功')),
        );
      }
    }
  }

  // 查看所有抄表记录
  void _viewAllMeterRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeterRecordsScreen(room: _currentRoom!),
      ),
    ).then((_) {
      // 返回时刷新数据
      _loadRoomData();
    });
  }

  // 生成月度报表
  void _generateMonthlyReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonthlyReportScreen(),
      ),
    ).then((_) {
      // 返回时刷新数据
      _loadRoomData();
    });
  }

  // 导出Excel报表
  Future<void> _exportExcelReport() async {
    try {
      // 显示加载提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.primaryBlue),
              SizedBox(width: 16),
              Text('正在生成Excel报表...'),
            ],
          ),
        ),
      );

      // 获取房间的抄表记录
      final records = await StorageService.getMeterRecords();
      final roomRecords = records.where((record) => 
        record.floor == _currentRoom!.floor &&
        record.roomNumber == _currentRoom!.roomNumber
      ).toList();
      roomRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 生成Excel数据
      final excelData = _generateExcelData(roomRecords);
      
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 分享Excel数据
      await Share.share(
        excelData,
        subject: '${_currentRoom!.floor}楼-${_currentRoom!.roomNumber} - 房间报表',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('报表已生成并分享'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // 关闭加载对话框
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateExcelData(List<MeterRecord> records) {
    final buffer = StringBuffer();
    
    // 标题
    buffer.writeln('${_currentRoom!.floor}楼-${_currentRoom!.roomNumber} - 房间报表');
    buffer.writeln('生成时间: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln();
    
    // 房间基本信息
    buffer.writeln('=== 房间信息 ===');
    buffer.writeln('房间号: ${_currentRoom!.floor}楼-${_currentRoom!.roomNumber}');
    if (_currentRoom!.occupantName != null) {
      buffer.writeln('租户姓名: ${_currentRoom!.occupantName}');
    }
    if (_currentRoom!.contactPhone != null) {
      buffer.writeln('联系电话: ${_currentRoom!.contactPhone}');
    }
    if (_currentRoom!.monthlyRent != null) {
      buffer.writeln('月租金: ¥${_currentRoom!.monthlyRent!.toStringAsFixed(2)}');
    }
    buffer.writeln();
    
    // 费用设置
    buffer.writeln('=== 费用设置 ===');
    buffer.writeln('水费单价: ¥${_currentRoom!.waterPricePerTon.toStringAsFixed(2)}/吨');
    buffer.writeln('电费单价: ¥${_currentRoom!.electricityPricePerKwh.toStringAsFixed(2)}/度');
    buffer.writeln('燃气费单价: ¥${_currentRoom!.gasPricePerCubicMeter.toStringAsFixed(2)}/立方米');
    if (_currentRoom!.serviceFee != null) {
      buffer.writeln('服务费: ¥${_currentRoom!.serviceFee!.toStringAsFixed(2)}');
    }
    if (_currentRoom!.cleaningFee != null) {
      buffer.writeln('清洁费: ¥${_currentRoom!.cleaningFee!.toStringAsFixed(2)}');
    }
    buffer.writeln();
    
    // 抄表记录
    buffer.writeln('=== 抄表记录 ===');
    buffer.writeln('时间\t表计类型\t读数\t备注');
    
    for (final record in records) {
      final dateStr = '${record.timestamp.year}-${record.timestamp.month.toString().padLeft(2, '0')}-${record.timestamp.day.toString().padLeft(2, '0')} ${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';
      final meterTypeName = _getMeterTypeName(record.meterType);
      final reading = record.recognitionResult ?? '未识别';
      final note = '';
      
      buffer.writeln('$dateStr\t$meterTypeName\t$reading\t$note');
    }
    
    if (records.isEmpty) {
      buffer.writeln('暂无抄表记录');
    }
    
    return buffer.toString();
  }

  String _getMeterTypeName(String meterType) {
    switch (meterType) {
      case '水表':
        return '水表';
      case '电表':
        return '电表';
      case '燃气':
        return '燃气表';
      default:
        return '未知';
    }
  }

  // 分享房间信息
  void _shareRoomInfo() async {
    try {
      final roomInfo = '''
房间信息：${_currentRoom!.floor}楼-${_currentRoom!.roomNumber}
入住人：${_currentRoom!.occupantName ?? '未设置'}
联系电话：${_currentRoom!.contactPhone ?? '未设置'}
微信号：${_currentRoom!.wechatId ?? '未设置'}
入住日期：${_currentRoom!.checkInDate != null ? '${_currentRoom!.checkInDate!.year}-${_currentRoom!.checkInDate!.month.toString().padLeft(2, '0')}-${_currentRoom!.checkInDate!.day.toString().padLeft(2, '0')}' : '未设置'}
月租金：${_currentRoom!.monthlyRent != null ? '¥${_currentRoom!.monthlyRent!.toStringAsFixed(2)}' : '未设置'}
服务费：${_currentRoom!.serviceFee != null ? '¥${_currentRoom!.serviceFee!.toStringAsFixed(2)}' : '未设置'}
卫生费：${_currentRoom!.cleaningFee != null ? '¥${_currentRoom!.cleaningFee!.toStringAsFixed(2)}' : '未设置'}
''';
      
      await Share.share(roomInfo, subject: '房间信息分享');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  // 导出房间报表
  void _exportRoomReport() async {
    try {
      // TODO: 实现房间报表导出
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出房间报表功能开发中...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }
}