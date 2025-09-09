import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/fee_calculation_service.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';
import '../services/event_manager.dart';
import '../theme/app_theme.dart';
import 'html_preview_screen.dart';
import 'image_preview_screen.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({Key? key}) : super(key: key);

  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

enum TimePeriodType {
  monthly('月度'),
  yearly('年度'),
  halfYear('近半年'),
  threeMonths('近三月');
  
  const TimePeriodType(this.displayName);
  final String displayName;
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final FeeCalculationService _feeService = FeeCalculationService();
  
  List<FeeCalculationResult> _reportData = [];
  bool _isLoading = false;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _selectedFloor;
  List<String> _availableFloors = [];
  TimePeriodType _selectedPeriodType = TimePeriodType.monthly;
  
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
  
  /// 订阅所有相关数据变更事件
  void _subscribeToEvents() {
    // 监听记录新增事件
    _eventSubscription = eventManager.subscribe(
      EventType.recordAdded,
      (eventData) {
        if (mounted) {
          _handleDataChange(eventData);
        }
      },
    );
    
    // 监听记录更新事件
    eventManager.subscribe(
      EventType.recordUpdated,
      (eventData) {
        if (mounted) {
          _handleDataChange(eventData);
        }
      },
    );
    
    // 监听记录删除事件
    eventManager.subscribe(
      EventType.recordDeleted,
      (eventData) {
        if (mounted) {
          _handleDataChange(eventData);
        }
      },
    );
    
    // 监听房间相关事件
    eventManager.subscribe(
      EventType.roomUpdated,
      (eventData) {
        if (mounted) {
          _loadAvailableFloors();
          _generateReport();
        }
      },
    );
    
    eventManager.subscribe(
      EventType.roomAdded,
      (eventData) {
        if (mounted) {
          _loadAvailableFloors();
          _generateReport();
        }
      },
    );
    
    eventManager.subscribe(
      EventType.roomDeleted,
      (eventData) {
        if (mounted) {
          _loadAvailableFloors();
          _generateReport();
        }
      },
    );
  }
  
  /// 处理数据变更事件
  void _handleDataChange(EventData eventData) {
    if (eventData.data != null) {
      final type = eventData.data!['type'] as String?;
      
      // 检查是否是影响报表的数据类型
      if (type == 'rent_config' || 
          type == 'rent_record' || 
          type == 'meter_record' ||
          type == 'service_fee') {
        _generateReport();
      }
    } else {
      // 如果没有具体类型信息，直接重新生成报表
      _generateReport();
    }
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
      List<FeeCalculationResult> results = [];
      
      switch (_selectedPeriodType) {
        case TimePeriodType.monthly:
          results = await _feeService.calculateBatchFees(
            year: _selectedYear,
            month: _selectedMonth,
            floors: _selectedFloor != null ? [int.parse(_selectedFloor!)] : null,
          );
          break;
          
        case TimePeriodType.yearly:
          // 计算整年数据
          for (int month = 1; month <= 12; month++) {
            final monthlyResults = await _feeService.calculateBatchFees(
              year: _selectedYear,
              month: month,
              floors: _selectedFloor != null ? [int.parse(_selectedFloor!)] : null,
            );
            results.addAll(monthlyResults);
          }
          // 合并同一房间的数据
          results = _mergeResultsByRoom(results);
          break;
          
        case TimePeriodType.halfYear:
          // 计算近6个月数据
          final now = DateTime.now();
          for (int i = 0; i < 6; i++) {
            final targetDate = DateTime(now.year, now.month - i, 1);
            final monthlyResults = await _feeService.calculateBatchFees(
              year: targetDate.year,
              month: targetDate.month,
              floors: _selectedFloor != null ? [int.parse(_selectedFloor!)] : null,
            );
            results.addAll(monthlyResults);
          }
          results = _mergeResultsByRoom(results);
          break;
          
        case TimePeriodType.threeMonths:
          // 计算近3个月数据
          final now = DateTime.now();
          for (int i = 0; i < 3; i++) {
            final targetDate = DateTime(now.year, now.month - i, 1);
            final monthlyResults = await _feeService.calculateBatchFees(
              year: targetDate.year,
              month: targetDate.month,
              floors: _selectedFloor != null ? [int.parse(_selectedFloor!)] : null,
            );
            results.addAll(monthlyResults);
          }
          results = _mergeResultsByRoom(results);
          break;
      }
      
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
  
  List<FeeCalculationResult> _mergeResultsByRoom(List<FeeCalculationResult> results) {
    final Map<String, FeeCalculationResult> mergedMap = {};
    
    for (final result in results) {
      final key = '${result.floor}-${result.roomNumber}';
      if (mergedMap.containsKey(key)) {
        final existing = mergedMap[key]!;
        mergedMap[key] = FeeCalculationResult(
          floor: result.floor,
          roomNumber: result.roomNumber,
          year: result.year,
          month: result.month,
          rent: existing.rent + result.rent,
          waterFee: MeterFeeDetail(
            meterType: '水表',
            previousReading: 0,
            currentReading: 0,
            usage: existing.waterFee.usage + result.waterFee.usage,
            unitPrice: existing.waterFee.unitPrice,
            totalAmount: existing.waterFee.totalAmount + result.waterFee.totalAmount,
          ),
          electricFee: MeterFeeDetail(
            meterType: '电表',
            previousReading: 0,
            currentReading: 0,
            usage: existing.electricFee.usage + result.electricFee.usage,
            unitPrice: existing.electricFee.unitPrice,
            totalAmount: existing.electricFee.totalAmount + result.electricFee.totalAmount,
          ),
          gasFee: MeterFeeDetail(
            meterType: '燃气表',
            previousReading: 0,
            currentReading: 0,
            usage: existing.gasFee.usage + result.gasFee.usage,
            unitPrice: existing.gasFee.unitPrice,
            totalAmount: existing.gasFee.totalAmount + result.gasFee.totalAmount,
          ),
          publicServiceFee: existing.publicServiceFee + result.publicServiceFee,
          sanitationFee: existing.sanitationFee + result.sanitationFee,
          totalAmount: existing.totalAmount + result.totalAmount,
        );
      } else {
        mergedMap[key] = result;
      }
    }
    
    return mergedMap.values.toList();
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
              // 时间段类型选择
              DropdownButtonFormField<TimePeriodType>(
                value: _selectedPeriodType,
                decoration: const InputDecoration(
                  labelText: '时间段类型',
                  border: OutlineInputBorder(),
                ),
                items: TimePeriodType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() {
                      _selectedPeriodType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // 根据时间段类型显示相应的选择器
              if (_selectedPeriodType == TimePeriodType.monthly || _selectedPeriodType == TimePeriodType.yearly) ...[
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
                
                // 月份选择（仅月度报表显示）
                if (_selectedPeriodType == TimePeriodType.monthly) ...[
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
                ],
              ],
              
              // 时间段说明
              if (_selectedPeriodType != TimePeriodType.monthly && _selectedPeriodType != TimePeriodType.yearly) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedPeriodType == TimePeriodType.halfYear 
                              ? '将统计从当前月份往前推6个月的数据'
                              : '将统计从当前月份往前推3个月的数据',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
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
  
  String _getReportTitle() {
    switch (_selectedPeriodType) {
      case TimePeriodType.monthly:
        return '${_selectedYear}年${_selectedMonth}月';
      case TimePeriodType.yearly:
        return '${_selectedYear}年';
      case TimePeriodType.halfYear:
        return '近半年报表';
      case TimePeriodType.threeMonths:
        return '近三月报表';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getReportTitle(),
          style: const TextStyle(
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
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              child: Column(
                                children: [
                                  // 紧凑的3x2网格布局
                                  Row(
                                    children: [
                                      Expanded(child: _buildCompactSummaryCard('房间数', '${_reportData.length}', Icons.home, AppTheme.primaryBlue)),
                                      const SizedBox(width: AppTheme.spacingS),
                                      Expanded(child: _buildCompactSummaryCard('总租金', '¥${_getTotalRent().toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
                                      const SizedBox(width: AppTheme.spacingS),
                                      Expanded(child: _buildCompactSummaryCard('总水费', '¥${_getTotalWaterFee().toStringAsFixed(2)}', Icons.water_drop, Colors.blue)),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Row(
                                    children: [
                                      Expanded(child: _buildCompactSummaryCard('总电费', '¥${_getTotalElectricFee().toStringAsFixed(2)}', Icons.electric_bolt, Colors.orange)),
                                      const SizedBox(width: AppTheme.spacingS),
                                      Expanded(child: _buildCompactSummaryCard('燃气费', '¥${_getTotalGasFee().toStringAsFixed(2)}', Icons.local_fire_department, Colors.red)),
                                      const SizedBox(width: AppTheme.spacingS),
                                      Expanded(child: _buildCompactSummaryCard('服务费', '¥${_getTotalPublicServiceFee().toStringAsFixed(2)}', Icons.cleaning_services, Colors.purple)),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  // 总计行
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                                              size: 16,
                                            ),
                                            const SizedBox(width: AppTheme.spacingS),
                                            Text(
                                              '总计',
                                              style: TextStyle(
                                                fontSize: AppTheme.fontSizeBody,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '¥${_getTotalAmount().toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeSubtitle,
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

  Widget _buildCompactSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                const SizedBox(width: AppTheme.spacingS),
                // 房间操作菜单按钮
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  onSelected: (value) => _handleRoomMenuAction(value, data),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'export_csv',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart, color: Colors.green, size: 18),
                          const SizedBox(width: AppTheme.spacingS),
                          Text('导出CSV'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export_html',
                      child: Row(
                        children: [
                          Icon(Icons.web, color: Colors.orange, size: 18),
                          const SizedBox(width: AppTheme.spacingS),
                          Text('导出HTML'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'preview_html',
                      child: Row(
                        children: [
                          Icon(Icons.preview, color: Colors.purple, size: 18),
                          const SizedBox(width: AppTheme.spacingS),
                          Text('HTML预览'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'preview_image',
                      child: Row(
                        children: [
                          Icon(Icons.image_search, color: Colors.indigo, size: 18),
                          const SizedBox(width: AppTheme.spacingS),
                          Text('图片预览'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export_image',
                      child: Row(
                        children: [
                          Icon(Icons.image, color: Colors.teal, size: 18),
                          const SizedBox(width: AppTheme.spacingS),
                          Text('导出图片'),
                        ],
                      ),
                    ),
                  ],
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
              Text(
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

  /// 系统分享
  Future<void> _shareWithSystem(String filePath, String subject) async {
    try {
      await ExportService.shareFile(filePath, subject);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
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
              color: AppTheme.textHint,
            ),
          ],
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
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: '打开文件夹',
              onPressed: () {
                final directory = File(filePath).parent.path;
                Process.run('explorer', [directory]);
              },
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

  /// 显示分享选项对话框
  Future<void> _showShareOptions(String filePath, String subject, {bool isImage = false}) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择分享方式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 系统分享
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('系统分享'),
              subtitle: const Text('使用系统默认分享方式'),
              onTap: () {
                Navigator.pop(context);
                _shareWithSystem(filePath, subject);
              },
            ),
            
            const SizedBox(height: 10),
            
            // 取消按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToHTML() async {
    try {
      final filePath = await ExportService.exportMonthlyReportToHTML(
        reportData: _reportData,
        year: _selectedYear,
        month: _selectedMonth,
        periodType: _selectedPeriodType.displayName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTML文件已导出: $filePath'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: '打开文件夹',
              onPressed: () {
                final directory = File(filePath).parent.path;
                Process.run('explorer', [directory]);
              },
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
          child: SingleChildScrollView(
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
              
              SizedBox(height: AppTheme.spacingM),
              
              // HTML预览
              _buildFormatOption(
                icon: Icons.preview,
                title: 'HTML预览',
                subtitle: '预览后再决定是否导出',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  if (singleRoom != null) {
                    _previewSingleRoomHTML(singleRoom);
                  } else {
                    _previewHTML();
                  }
                },
              ),
              
              SizedBox(height: AppTheme.spacingM),
              
              // 图片预览
              _buildFormatOption(
                icon: Icons.image_search,
                title: '图片预览',
                subtitle: '预览后再决定是否导出',
                color: Colors.indigo,
                onTap: () {
                  Navigator.pop(context);
                  if (singleRoom != null) {
                    _previewSingleRoomImage(singleRoom);
                  } else {
                    _previewImage();
                  }
                },
              ),
              
              SizedBox(height: AppTheme.spacingM),
              
              // 图片格式
              _buildFormatOption(
                icon: Icons.image,
                title: '图片格式',
                subtitle: 'PNG格式，高清图片便于分享',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  if (singleRoom != null) {
                    _exportSingleRoomToImage(singleRoom);
                  } else {
                    _exportToImage();
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
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: '打开文件夹',
              onPressed: () {
                final directory = File(filePath).parent.path;
                Process.run('explorer', [directory]);
              },
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

  /// 处理房间菜单操作
  void _handleRoomMenuAction(String action, FeeCalculationResult roomData) {
    switch (action) {
      case 'export_csv':
        _exportSingleRoomToCSV(roomData);
        break;
      case 'export_html':
        _exportSingleRoomToHTML(roomData);
        break;
      case 'preview_html':
        _previewSingleRoomHTML(roomData);
        break;
      case 'preview_image':
        _previewSingleRoomImage(roomData);
        break;
      case 'export_image':
        _exportSingleRoomToImage(roomData);
        break;
    }
  }

  Future<void> _exportSingleRoomToHTML(FeeCalculationResult roomData) async {
    try {
      // 获取导出配置
      final exportConfig = await StorageService.getExportConfig();
      
      final filePath = await ExportService.exportSingleRoomToHTML(
        roomData: roomData,
        year: _selectedYear,
        month: _selectedMonth,
        periodType: _selectedPeriodType.displayName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTML文件已导出: $filePath'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: '打开文件夹',
              onPressed: () {
                final directory = File(filePath).parent.path;
                Process.run('explorer', [directory]);
              },
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
  
  /// 预览HTML报表
  Future<void> _previewHTML() async {
    try {
      final htmlContent = ExportService.generateMonthlyReportHtmlContent(
        reportData: _reportData,
        year: _selectedYear,
        month: _selectedMonth,
        periodType: _selectedPeriodType.displayName,
      );
      
      if (mounted) {
        final shouldExport = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => HtmlPreviewScreen(
              htmlContent: htmlContent,
              title: '报表预览',
            ),
          ),
        );
        
        if (shouldExport == true) {
          _exportToHTML();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('预览失败: $e')),
        );
      }
    }
  }
  
  /// 预览单个房间HTML报表
  Future<void> _previewSingleRoomHTML(FeeCalculationResult roomData) async {
    try {
      final htmlContent = ExportService.generateSingleRoomHtmlContent(
        roomData: roomData,
        year: _selectedYear,
        month: _selectedMonth,
        periodType: _selectedPeriodType.displayName,
      );
      
      if (mounted) {
        final shouldExport = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => HtmlPreviewScreen(
              htmlContent: htmlContent,
              title: '${roomData.floor}-${roomData.roomNumber} 预览',
            ),
          ),
        );
        
        if (shouldExport == true) {
          _exportSingleRoomToHTML(roomData);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('预览失败: $e')),
        );
      }
    }
  }

  /// 导出单个房间的图片报表
  Future<void> _exportSingleRoomToImage(FeeCalculationResult roomData) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在保存到相册...'),
            ],
          ),
        ),
      );
      
      // 获取导出配置
      final exportConfig = await StorageService.getExportConfig();
      
      final success = await ExportService.saveRoomImageToGallery(
        roomData: roomData,
        year: _selectedYear,
        month: _selectedMonth,
        periodType: _selectedPeriodType.displayName,
        config: exportConfig,
        context: context,
      );
      
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('图片已保存到相册'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '查看相册',
                textColor: Colors.white,
                onPressed: () {
                  // 在Android上可以打开相册应用
                  // 这里可以根据需要添加打开相册的逻辑
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存到相册失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存图片失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 导出全部房间的图片报表
  Future<void> _exportToImage() async {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('没有数据可导出')),
      );
      return;
    }

    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在保存到相册...'),
            ],
          ),
        ),
      );

      // 获取导出配置
      final exportConfig = await StorageService.getExportConfig();
      
      // 保存每个房间的图片到相册
      int successCount = 0;
      int totalCount = _reportData.length;
      
      for (int i = 0; i < _reportData.length; i++) {
        final roomData = _reportData[i];
        try {
          final success = await ExportService.saveRoomImageToGallery(
            roomData: roomData,
            year: _selectedYear,
            month: _selectedMonth,
            periodType: _selectedPeriodType.displayName,
            config: exportConfig,
            context: context,
          );
          if (success) {
            successCount++;
          }
        } catch (e) {
          // 单个房间保存失败，继续处理其他房间
          print('保存房间 ${roomData.floor}-${roomData.roomNumber} 图片失败: $e');
        }
      }

      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        if (successCount == totalCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已成功保存 $successCount 个房间的图片到相册'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '查看相册',
                textColor: Colors.white,
                onPressed: () {
                  // 在Android上可以打开相册应用
                  // 这里可以根据需要添加打开相册的逻辑
                },
              ),
            ),
          );
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已保存 $successCount/$totalCount 个房间的图片到相册'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('保存图片到相册失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存图片失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示批量图片预览
  void _showBatchImagePreview(List<String> filePaths) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('导出完成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已成功导出 ${filePaths.length} 个房间的图片报表'),
            SizedBox(height: 16),
            Text('文件保存位置：'),
            Text(
              filePaths.first.substring(0, filePaths.first.lastIndexOf('/')),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showShareOptions(filePaths.first, '批量房间报表图片', isImage: true);
            },
            child: Text('分享'),
          ),
        ],
      ),
    );
  }

  /// 预览单个房间图片报表
  Future<void> _previewSingleRoomImage(FeeCalculationResult roomData) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在生成预览...'),
            ],
          ),
        ),
      );

      // 获取导出配置
      final exportConfig = await StorageService.getExportConfig();
      
      // 生成图片
      final filePath = await ExportService.exportSingleRoomToImage(
        roomData: roomData,
        year: _selectedYear,
        month: _selectedMonth,
        periodType: _selectedPeriodType.displayName,
        config: exportConfig,
        context: context,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        // 显示图片预览
        final shouldExport = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imagePath: filePath,
              title: '${roomData.floor}-${roomData.roomNumber} 预览',
              onExport: () => _exportSingleRoomToImage(roomData),
            ),
          ),
        );
        
        // 如果用户没有选择导出，删除临时文件
        if (shouldExport != true) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            // 忽略删除错误
          }
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('预览失败: $e')),
        );
      }
    }
  }

  /// 预览全部房间图片报表
  Future<void> _previewImage() async {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('没有数据可预览')),
      );
      return;
    }

    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在生成预览...'),
            ],
          ),
        ),
      );

      // 获取导出配置
      final exportConfig = await StorageService.getExportConfig();
      
      // 生成第一个房间的图片作为预览
      final firstRoom = _reportData.first;
      final filePath = await ExportService.exportSingleRoomToImage(
        roomData: firstRoom,
        year: _selectedYear,
        month: _selectedMonth,
        periodType: _selectedPeriodType.displayName,
        config: exportConfig,
        context: context,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        // 显示图片预览
        final shouldExport = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imagePath: filePath,
              title: '批量导出预览 (${_reportData.length}个房间)',
              onExport: () => _exportToImage(),
            ),
          ),
        );
        
        // 如果用户没有选择导出，删除临时文件
        if (shouldExport != true) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            // 忽略删除错误
          }
        }
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('预览失败: $e')),
        );
      }
    }
  }
}