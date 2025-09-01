import 'package:flutter/material.dart';
import '../services/fee_calculation_service.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAvailableFloors();
    _generateReport();
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
        title: Text('月度报表 - ${_selectedYear}年${_selectedMonth}月'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData.isEmpty
              ? const Center(
                  child: Text(
                    '暂无数据\n请选择其他月份或添加记录',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    // 汇总信息卡片
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '汇总信息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem('房间数', '${_reportData.length}'),
                              _buildSummaryItem('总租金', '¥${_getTotalRent().toStringAsFixed(2)}'),
                              _buildSummaryItem('总水费', '¥${_getTotalWaterFee().toStringAsFixed(2)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem('总电费', '¥${_getTotalElectricFee().toStringAsFixed(2)}'),
                                _buildSummaryItem('总燃气费', '¥${_getTotalGasFee().toStringAsFixed(2)}'),
                                _buildSummaryItem('公共服务费', '¥${_getTotalPublicServiceFee().toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem('卫生费', '¥${_getTotalSanitationFee().toStringAsFixed(2)}'),
                                _buildSummaryItem('', ''),
                                _buildSummaryItem('总计', '¥${_getTotalAmount().toStringAsFixed(2)}', isTotal: true),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    // 详细数据表格
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                            columns: const [
                              DataColumn(label: Text('房号', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('租金', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('上月水表', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('本月水表', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('水费单价', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('水费合计', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('上月电表', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('本月电表', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('电费单价', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('电费合计', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('燃气费', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('公共服务费', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('卫生费', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('总计', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _reportData.map((data) {
                              return DataRow(
                                cells: [
                                  DataCell(Text('${data.floor}-${data.roomNumber}')),
                                  DataCell(Text(data.rent.toStringAsFixed(2))),
                                  DataCell(Text(data.waterFee.previousReading.toStringAsFixed(1))),
                                  DataCell(Text(data.waterFee.currentReading.toStringAsFixed(1))),
                                  DataCell(Text(data.waterFee.unitPrice.toStringAsFixed(2))),
                                  DataCell(Text(data.waterFee.totalAmount.toStringAsFixed(2))),
                                  DataCell(Text(data.electricFee.previousReading.toStringAsFixed(1))),
                                  DataCell(Text(data.electricFee.currentReading.toStringAsFixed(1))),
                                  DataCell(Text(data.electricFee.unitPrice.toStringAsFixed(2))),
                                  DataCell(Text(data.electricFee.totalAmount.toStringAsFixed(2))),
                                  DataCell(Text(data.gasFee.totalAmount.toStringAsFixed(2))),
                                  DataCell(Text(data.publicServiceFee.toStringAsFixed(2))),
                                  DataCell(Text(data.sanitationFee.toStringAsFixed(2))),
                                  DataCell(
                                    Text(
                                      data.totalAmount.toStringAsFixed(2),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.red.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出报表'),
        content: const Text('请选择导出格式'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToCSV();
            },
            child: const Text('CSV格式'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToHTML();
            },
            child: const Text('HTML格式'),
          ),
        ],
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
}