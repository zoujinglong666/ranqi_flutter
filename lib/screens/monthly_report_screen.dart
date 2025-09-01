import 'dart:async';
import 'package:flutter/material.dart';
import '../services/fee_calculation_service.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import '../services/event_manager.dart';
import '../theme/app_theme.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({Key? key}) : super(key: key);

  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final FeeCalculationService _feeService = FeeCalculationService();
  
  List<FeeCalculationResult> _reportData = [];
  bool _isLoading = false;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _selectedFloor;
  List<String> _availableFloors = [];
  
  // 事件订阅
  StreamSubscription<EventData>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadAvailableFloors();
    _generateReport();
    _subscribeToEvents();
  }
  
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
  
  /// 订阅租金相关事件
  void _subscribeToEvents() {
    _eventSubscription = eventManager.subscribe(
      EventType.recordAdded,
      (eventData) {
        // 当有租金配置或记录变化时，重新生成报表
        if (mounted && eventData.data != null) {
          final type = eventData.data!['type'] as String?;
          if (type == 'rent_config' || type == 'rent_record') {
            _generateReport();
          }
        }
      },
    );
    
    // 同时监听更新事件
    eventManager.subscribe(
      EventType.recordUpdated,
      (eventData) {
        if (mounted && eventData.data != null) {
          final type = eventData.data!['type'] as String?;
          if (type == 'rent_config' || type == 'rent_record') {
            _generateReport();
          }
        }
      },
    );
  }

  Future<void> _loadAvailableFloors() async {
    try {
      final floors = await StorageService.getAvailableFloors();
      setState(() {
        _availableFloors = floors.map((floor) => floor.toString()).toList();
      });
    } catch (e) {
      print('加载楼层失败: $e');
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _feeService.calculateBatchFees(
        year: _selectedYear,
        month: _selectedMonth,
        floors: _selectedFloor != null ? [_selectedFloor!] : null,
      );
      
      setState(() {
        _reportData = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成报表失败: $e')),
      );
    }
  }

  void _showDatePicker() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('选择月份'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 年份选择
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: '年份',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(10, (index) {
                  final year = DateTime.now().year - 5 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() {
                      _selectedYear = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // 月份选择
              DropdownButtonFormField<int>(
                value: _selectedMonth,
                decoration: const InputDecoration(
                  labelText: '月份',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem(
                    value: month,
                    child: Text('${month}月'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() {
                      _selectedMonth = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // 楼层选择
              DropdownButtonFormField<String?>(
                value: _selectedFloor,
                decoration: const InputDecoration(
                  labelText: '楼层（可选）',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('全部楼层'),
                  ),
                  ..._availableFloors.map((floor) {
                    return DropdownMenuItem<String?>(
                      value: floor,
                      child: Text(floor),
                    );
                  }),
                ],
                onChanged: (value) {
                  setModalState(() {
                    _selectedFloor = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  // 更新选择的值
                });
                _generateReport();
              },
              child: const Text('生成报表'),
            ),
          ],
        ),
      ),
    );
  }

  double _getTotalAmount() {
    return _reportData.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  double _getTotalRent() {
    return _reportData.fold(0.0, (sum, item) => sum + item.rent);
  }

  double _getTotalWaterFee() {
    return _reportData.fold(0.0, (sum, item) => sum + item.waterFee.totalAmount);
  }

  double _getTotalElectricFee() {
    return _reportData.fold(0.0, (sum, item) => sum + item.electricFee.totalAmount);
  }

  double _getTotalGasFee() {
    return _reportData.fold(0.0, (sum, item) => sum + item.gasFee.totalAmount);
  }

  double _getTotalPublicServiceFee() {
    return _reportData.fold(0.0, (sum, item) => sum + item.publicServiceFee);
  }

  double _getTotalSanitationFee() {
    return _reportData.fold(0.0, (sum, item) => sum + item.sanitationFee);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '月度报表 - ${_selectedYear}年${_selectedMonth}月',
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
            icon: const Icon(Icons.date_range),
            onPressed: _showDatePicker,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateReport,
          ),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundPrimary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              )
            : _reportData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.assessment_outlined,
                            size: 64,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Text(
                          '暂无数据',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeHeading,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          '请选择其他月份或添加记录',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // 汇总信息卡片
                      Container(
                        margin: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(AppTheme.radiusLarge),
                                  topRight: Radius.circular(AppTheme.radiusLarge),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    color: AppTheme.textPrimary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Text(
                                    '汇总信息',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeHeading,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildSummaryCard('房间数', '${_reportData.length}', Icons.home, AppTheme.primaryBlue)),
                                      const SizedBox(width: AppTheme.spacingM),
                                      Expanded(child: _buildSummaryCard('总租金', '¥${_getTotalRent().toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingM),
                                  Row(
                                    children: [
                                      Expanded(child: _buildSummaryCard('总水费', '¥${_getTotalWaterFee().toStringAsFixed(2)}', Icons.water_drop, Colors.blue)),
                                      const SizedBox(width: AppTheme.spacingM),
                                      Expanded(child: _buildSummaryCard('总电费', '¥${_getTotalElectricFee().toStringAsFixed(2)}', Icons.electric_bolt, Colors.orange)),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingM),
                                  Row(
                                    children: [
                                      Expanded(child: _buildSummaryCard('燃气费', '¥${_getTotalGasFee().toStringAsFixed(2)}', Icons.local_fire_department, Colors.red)),
                                      const SizedBox(width: AppTheme.spacingM),
                                      Expanded(child: _buildSummaryCard('服务费', '¥${_getTotalPublicServiceFee().toStringAsFixed(2)}', Icons.cleaning_services, Colors.purple)),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingM),
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingM),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calculate,
                                              color: AppTheme.primaryBlue,
                                              size: 20,
                                            ),
                                            const SizedBox(width: AppTheme.spacingS),
                                            Text(
                                              '总计',
                                              style: TextStyle(
                                                fontSize: AppTheme.fontSizeSubtitle,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '¥${_getTotalAmount().toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeHeading,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 房间详细信息列表
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                          itemCount: _reportData.length,
                          itemBuilder: (context, index) {
                            final data = _reportData[index];
                            return _buildRoomReportCard(data, index);
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeCaption,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSubtitle,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomReportCard(FeeCalculationResult data, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 房间标题
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                topRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '${data.floor}-${data.roomNumber}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '总计: ¥${data.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 费用详情
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                // 租金
                _buildFeeRow('租金', '¥${data.rent.toStringAsFixed(2)}', Icons.home, Colors.green),
                const SizedBox(height: AppTheme.spacingS),
                
                // 水费
                _buildFeeRow(
                  '水费',
                  '¥${data.waterFee.totalAmount.toStringAsFixed(2)}',
                  Icons.water_drop,
                  Colors.blue,
                  subtitle: '${data.waterFee.previousReading.toStringAsFixed(1)} → ${data.waterFee.currentReading.toStringAsFixed(1)} (¥${data.waterFee.unitPrice.toStringAsFixed(2)}/度)',
                ),
                const SizedBox(height: AppTheme.spacingS),
                
                // 电费
                _buildFeeRow(
                  '电费',
                  '¥${data.electricFee.totalAmount.toStringAsFixed(2)}',
                  Icons.electric_bolt,
                  Colors.orange,
                  subtitle: '${data.electricFee.previousReading.toStringAsFixed(1)} → ${data.electricFee.currentReading.toStringAsFixed(1)} (¥${data.electricFee.unitPrice.toStringAsFixed(2)}/度)',
                ),
                const SizedBox(height: AppTheme.spacingS),
                
                // 燃气费
                if (data.gasFee.totalAmount > 0)
                  _buildFeeRow('燃气费', '¥${data.gasFee.totalAmount.toStringAsFixed(2)}', Icons.local_fire_department, Colors.red),
                if (data.gasFee.totalAmount > 0)
                  const SizedBox(height: AppTheme.spacingS),
                
                // 公共服务费
                if (data.publicServiceFee > 0)
                  _buildFeeRow('公共服务费', '¥${data.publicServiceFee.toStringAsFixed(2)}', Icons.cleaning_services, Colors.purple),
                if (data.publicServiceFee > 0)
                  const SizedBox(height: AppTheme.spacingS),
                
                // 卫生费
                if (data.sanitationFee > 0)
                  _buildFeeRow('卫生费', '¥${data.sanitationFee.toStringAsFixed(2)}', Icons.cleaning_services, Colors.teal),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String amount, IconData icon, Color color, {String? subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeBody,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeCaption,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: AppTheme.fontSizeBody,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusLarge),
            topRight: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacingL,
            right: AppTheme.spacingL,
            top: AppTheme.spacingL,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.file_download,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '导出报表',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeHeading,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '选择导出范围和格式',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingL),
              
              // 导出范围选择
              Text(
                '导出范围',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSubtitle,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.spacingM),
              
              // 全部房间导出
              _buildExportOption(
                icon: Icons.home_work,
                title: '全部房间',
                subtitle: '导出所有房间的费用明细',
                color: AppTheme.primaryBlue,
                onTap: () => _showFormatSelection(context, null),
              ),
              
              SizedBox(height: AppTheme.spacingM),
              
              // 单个房间导出
              const Text(
                '单个房间',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeBody,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: AppTheme.spacingS),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: ListView.builder(
                  itemCount: _reportData.length,
                  itemBuilder: (context, index) {
                    final data = _reportData[index];
                    return ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppTheme.spacingS),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Icon(
                          Icons.home,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${data.floor}-${data.roomNumber}',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '总计: ¥${data.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeCaption,
                          color: Colors.green.shade700,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textHint,
                      ),
                      onTap: () => _showFormatSelection(context, data),
                    );
                  },
                ),
              ),
              
              SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportToCSV() async {
    try {
      final filePath = await ExportService.exportMonthlyReportToCSV(
        reportData: _reportData,
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV文件已导出: $filePath'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () => _shareFile(filePath, 'CSV月度报表'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _exportToHTML() async {
    try {
      final filePath = await ExportService.exportMonthlyReportToHTML(
        reportData: _reportData,
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTML文件已导出: $filePath'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () => _shareFile(filePath, 'HTML月度报表'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _shareFile(String filePath, String title) async {
    try {
      await ExportService.shareFile(filePath, title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeCaption,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  void _showFormatSelection(BuildContext context, FeeCalculationResult? singleRoom) {
    Navigator.pop(context); // 关闭导出弹窗
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusLarge),
            topRight: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.file_copy,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '选择导出格式',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSubtitle,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          singleRoom != null 
                              ? '${singleRoom.floor}-${singleRoom.roomNumber}'
                              : '全部房间',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeCaption,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingL),
              
              // CSV格式
              _buildFormatOption(
                icon: Icons.table_chart,
                title: 'CSV格式',
                subtitle: '适合Excel打开，便于数据分析',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  if (singleRoom != null) {
                    _exportSingleRoomToCSV(singleRoom);
                  } else {
                    _exportToCSV();
                  }
                },
              ),
              
              SizedBox(height: AppTheme.spacingM),
              
              // HTML格式
              _buildFormatOption(
                icon: Icons.web,
                title: 'HTML格式',
                subtitle: '网页格式，便于打印和分享',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  if (singleRoom != null) {
                    _exportSingleRoomToHTML(singleRoom);
                  } else {
                    _exportToHTML();
                  }
                },
              ),
              
              SizedBox(height: AppTheme.spacingL),
              
              // 取消按钮
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeCaption,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSingleRoomToCSV(FeeCalculationResult roomData) async {
    try {
      final filePath = await ExportService.exportSingleRoomToCSV(
        roomData: roomData,
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV文件已导出: $filePath'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () => _shareFile(filePath, '${roomData.floor}-${roomData.roomNumber} CSV报表'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _exportSingleRoomToHTML(FeeCalculationResult roomData) async {
    try {
      final filePath = await ExportService.exportSingleRoomToHTML(
        roomData: roomData,
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTML文件已导出: $filePath'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () => _shareFile(filePath, '${roomData.floor}-${roomData.roomNumber} HTML报表'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }
}