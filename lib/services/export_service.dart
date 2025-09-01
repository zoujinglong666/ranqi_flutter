import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'fee_calculation_service.dart';

class ExportService {
  /// 导出CSV格式的月度报表
  static Future<String> exportMonthlyReportToCSV({
    required List<FeeCalculationResult> reportData,
    required int year,
    required int month,
  }) async {
    try {
      // 创建CSV内容
      final StringBuffer csvBuffer = StringBuffer();
      
      // 添加标题行
      csvBuffer.writeln('月度报表 - ${year}年${month}月');
      csvBuffer.writeln('');
      
      // 添加表头
      csvBuffer.writeln('房号,租金,上月水表,本月水表,水费单价,水费合计,上月电表,本月电表,电费单价,电费合计,燃气费,公共服务费,卫生费,总计');
      
      // 添加数据行
      for (final data in reportData) {
        csvBuffer.writeln(
          '${data.floor}-${data.roomNumber},' +
          '${data.rent.toStringAsFixed(2)},' +
          '${data.waterFee.previousReading.toStringAsFixed(1)},' +
          '${data.waterFee.currentReading.toStringAsFixed(1)},' +
          '${data.waterFee.unitPrice.toStringAsFixed(2)},' +
          '${data.waterFee.totalAmount.toStringAsFixed(2)},' +
          '${data.electricFee.previousReading.toStringAsFixed(1)},' +
          '${data.electricFee.currentReading.toStringAsFixed(1)},' +
          '${data.electricFee.unitPrice.toStringAsFixed(2)},' +
          '${data.electricFee.totalAmount.toStringAsFixed(2)},' +
          '${data.gasFee.totalAmount.toStringAsFixed(2)},' +
          '${data.publicServiceFee.toStringAsFixed(2)},' +
          '${data.sanitationFee.toStringAsFixed(2)},' +
          '${data.totalAmount.toStringAsFixed(2)}'
        );
      }
      
      // 添加汇总行
      csvBuffer.writeln('');
      csvBuffer.writeln('汇总信息');
      csvBuffer.writeln('房间数,${reportData.length}');
      csvBuffer.writeln('总租金,${reportData.fold<double>(0.0, (sum, item) => sum + item.rent.toDouble()).toStringAsFixed(2)}');
       csvBuffer.writeln('总水费,${reportData.fold<double>(0.0, (sum, item) => sum + item.waterFee.totalAmount.toDouble()).toStringAsFixed(2)}');
        csvBuffer.writeln('总电费,${reportData.fold<double>(0.0, (sum, item) => sum + item.electricFee.totalAmount.toDouble()).toStringAsFixed(2)}');
        csvBuffer.writeln('总燃气费,${reportData.fold<double>(0.0, (sum, item) => sum + item.gasFee.totalAmount.toDouble()).toStringAsFixed(2)}');
       csvBuffer.writeln('总公共服务费,${reportData.fold<double>(0.0, (sum, item) => sum + item.publicServiceFee.toDouble()).toStringAsFixed(2)}');
       csvBuffer.writeln('总卫生费,${reportData.fold<double>(0.0, (sum, item) => sum + item.sanitationFee.toDouble()).toStringAsFixed(2)}');
       csvBuffer.writeln('总计,${reportData.fold<double>(0.0, (sum, item) => sum + item.totalAmount.toDouble()).toStringAsFixed(2)}');
      
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '月度报表_${year}年${month}月_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      // 写入文件
      await file.writeAsString(csvBuffer.toString(), encoding: utf8);
      
      return file.path;
    } catch (e) {
      throw Exception('导出CSV失败: $e');
    }
  }
  
  /// 导出HTML格式的月度报表
  static Future<String> exportMonthlyReportToHTML({
    required List<FeeCalculationResult> reportData,
    required int year,
    required int month,
  }) async {
    try {
      // 创建HTML内容
      final StringBuffer htmlBuffer = StringBuffer();
      
      htmlBuffer.writeln('<!DOCTYPE html>');
      htmlBuffer.writeln('<html>');
      htmlBuffer.writeln('<head>');
      htmlBuffer.writeln('<meta charset="UTF-8">');
      htmlBuffer.writeln('<title>月度报表 - ${year}年${month}月</title>');
      htmlBuffer.writeln('<style>');
      htmlBuffer.writeln('''
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; text-align: center; }
        .summary { background-color: #f0f8ff; padding: 15px; border-radius: 8px; margin-bottom: 20px; }
        .summary h2 { color: #1e90ff; margin-top: 0; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; }
        .summary-item { text-align: center; }
        .summary-label { font-size: 12px; color: #666; }
        .summary-value { font-size: 14px; font-weight: bold; color: #333; }
        .total-value { color: #dc143c; font-size: 16px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: center; }
        th { background-color: #f2f2f2; font-weight: bold; }
        .total-column { font-weight: bold; }
        .export-time { text-align: right; color: #666; font-size: 12px; margin-top: 20px; }
      ''');
      htmlBuffer.writeln('</style>');
      htmlBuffer.writeln('</head>');
      htmlBuffer.writeln('<body>');
      
      // 标题
      htmlBuffer.writeln('<h1>月度报表 - ${year}年${month}月</h1>');
      
      // 汇总信息
      htmlBuffer.writeln('<div class="summary">');
      htmlBuffer.writeln('<h2>汇总信息</h2>');
      htmlBuffer.writeln('<div class="summary-grid">');
      htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">房间数</div><div class="summary-value">${reportData.length}</div></div>');
      htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总租金</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.rent.toDouble()).toStringAsFixed(2)}</div></div>');
       htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总水费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.waterFee.totalAmount.toDouble()).toStringAsFixed(2)}</div></div>');
        htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总电费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.electricFee.totalAmount.toDouble()).toStringAsFixed(2)}</div></div>');
        htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总燃气费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.gasFee.totalAmount.toDouble()).toStringAsFixed(2)}</div></div>');
       htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">公共服务费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.publicServiceFee.toDouble()).toStringAsFixed(2)}</div></div>');
       htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">卫生费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.sanitationFee.toDouble()).toStringAsFixed(2)}</div></div>');
       htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总计</div><div class="summary-value total-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.totalAmount.toDouble()).toStringAsFixed(2)}</div></div>');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('</div>');
      
      // 详细数据表格
      htmlBuffer.writeln('<table>');
      htmlBuffer.writeln('<thead>');
      htmlBuffer.writeln('<tr>');
      htmlBuffer.writeln('<th>房号</th>');
      htmlBuffer.writeln('<th>租金</th>');
      htmlBuffer.writeln('<th>上月水表</th>');
      htmlBuffer.writeln('<th>本月水表</th>');
      htmlBuffer.writeln('<th>水费单价</th>');
      htmlBuffer.writeln('<th>水费合计</th>');
      htmlBuffer.writeln('<th>上月电表</th>');
      htmlBuffer.writeln('<th>本月电表</th>');
      htmlBuffer.writeln('<th>电费单价</th>');
      htmlBuffer.writeln('<th>电费合计</th>');
      htmlBuffer.writeln('<th>燃气费</th>');
      htmlBuffer.writeln('<th>公共服务费</th>');
      htmlBuffer.writeln('<th>卫生费</th>');
      htmlBuffer.writeln('<th>总计</th>');
      htmlBuffer.writeln('</tr>');
      htmlBuffer.writeln('</thead>');
      htmlBuffer.writeln('<tbody>');
      
      for (final data in reportData) {
        htmlBuffer.writeln('<tr>');
        htmlBuffer.writeln('<td>${data.floor}-${data.roomNumber}</td>');
        htmlBuffer.writeln('<td>${data.rent.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('<td>${data.waterFee.previousReading.toStringAsFixed(1)}</td>');
        htmlBuffer.writeln('<td>${data.waterFee.currentReading.toStringAsFixed(1)}</td>');
        htmlBuffer.writeln('<td>${data.waterFee.unitPrice.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('<td>${data.waterFee.totalAmount.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('<td>${data.electricFee.previousReading.toStringAsFixed(1)}</td>');
        htmlBuffer.writeln('<td>${data.electricFee.currentReading.toStringAsFixed(1)}</td>');
        htmlBuffer.writeln('<td>${data.electricFee.unitPrice.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('<td>${data.electricFee.totalAmount.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('<td>${data.gasFee.totalAmount.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('<td>${data.publicServiceFee.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('<td>${data.sanitationFee.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('<td class="total-column">${data.totalAmount.toStringAsFixed(2)}</td>');
        htmlBuffer.writeln('</tr>');
      }
      
      htmlBuffer.writeln('</tbody>');
      htmlBuffer.writeln('</table>');
      
      // 导出时间
      htmlBuffer.writeln('<div class="export-time">导出时间: ${DateTime.now().toString().substring(0, 19)}</div>');
      
      htmlBuffer.writeln('</body>');
      htmlBuffer.writeln('</html>');
      
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '月度报表_${year}年${month}月_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = File('${directory.path}/$fileName');
      
      // 写入文件
      await file.writeAsString(htmlBuffer.toString(), encoding: utf8);
      
      return file.path;
    } catch (e) {
      throw Exception('导出HTML失败: $e');
    }
  }
  
  /// 分享导出的文件
  static Future<void> shareFile(String filePath, String title) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: title,
      );
    } catch (e) {
      throw Exception('分享文件失败: $e');
    }
  }
  
  /// 导出单个房间的CSV报表
  static Future<String> exportSingleRoomToCSV({
    required FeeCalculationResult roomData,
    required int year,
    required int month,
  }) async {
    try {
      // 创建CSV内容
      final StringBuffer csvBuffer = StringBuffer();
      
      // 添加标题行
      csvBuffer.writeln('单房间报表 - ${year}年${month}月');
      csvBuffer.writeln('房间号: ${roomData.floor}-${roomData.roomNumber}');
      csvBuffer.writeln('');
      
      // 添加费用明细
      csvBuffer.writeln('费用项目,金额');
      csvBuffer.writeln('租金,${roomData.rent.toStringAsFixed(2)}');
      csvBuffer.writeln('水费 (${roomData.waterFee.previousReading.toStringAsFixed(1)} → ${roomData.waterFee.currentReading.toStringAsFixed(1)} × ${roomData.waterFee.unitPrice.toStringAsFixed(2)}),${roomData.waterFee.totalAmount.toStringAsFixed(2)}');
      csvBuffer.writeln('电费 (${roomData.electricFee.previousReading.toStringAsFixed(1)} → ${roomData.electricFee.currentReading.toStringAsFixed(1)} × ${roomData.electricFee.unitPrice.toStringAsFixed(2)}),${roomData.electricFee.totalAmount.toStringAsFixed(2)}');
      csvBuffer.writeln('燃气费,${roomData.gasFee.totalAmount.toStringAsFixed(2)}');
      csvBuffer.writeln('公共服务费,${roomData.publicServiceFee.toStringAsFixed(2)}');
      csvBuffer.writeln('卫生费,${roomData.sanitationFee.toStringAsFixed(2)}');
      csvBuffer.writeln('总计,${roomData.totalAmount.toStringAsFixed(2)}');
      
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${roomData.floor}-${roomData.roomNumber}_${year}年${month}月_${DateTime.now().millisecondsSinceEpoch}.csv';
       final file = File('${directory.path}/$fileName');
      
      // 写入文件
      await file.writeAsString(csvBuffer.toString(), encoding: utf8);
      
      return file.path;
    } catch (e) {
      throw Exception('导出单房间CSV失败: $e');
    }
  }

  /// 导出单个房间的HTML报表
  static Future<String> exportSingleRoomToHTML({
    required FeeCalculationResult roomData,
    required int year,
    required int month,
  }) async {
    try {
      // 创建HTML内容
      final StringBuffer htmlBuffer = StringBuffer();
      
      htmlBuffer.writeln('<!DOCTYPE html>');
      htmlBuffer.writeln('<html>');
      htmlBuffer.writeln('<head>');
      htmlBuffer.writeln('<meta charset="UTF-8">');
      htmlBuffer.writeln('<title>房间报表 - ${roomData.floor}-${roomData.roomNumber}</title>');
      htmlBuffer.writeln('<style>');
      htmlBuffer.writeln('''
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; margin-bottom: 30px; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .room-info { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 25px; text-align: center; }
        .room-number { font-size: 24px; font-weight: bold; margin-bottom: 5px; }
        .period { font-size: 14px; opacity: 0.9; }
        .fee-item { display: flex; justify-content: space-between; align-items: center; padding: 15px 0; border-bottom: 1px solid #ecf0f1; }
        .fee-item:last-child { border-bottom: none; }
        .fee-label { font-weight: 500; color: #34495e; }
        .fee-detail { font-size: 12px; color: #7f8c8d; margin-top: 2px; }
        .fee-amount { font-weight: bold; color: #27ae60; font-size: 16px; }
        .total-section { background: #ecf0f1; padding: 20px; border-radius: 8px; margin-top: 20px; }
        .total-amount { font-size: 24px; font-weight: bold; color: #e74c3c; text-align: center; }
        .export-time { text-align: center; color: #95a5a6; font-size: 12px; margin-top: 25px; }
      ''');
      htmlBuffer.writeln('</style>');
      htmlBuffer.writeln('</head>');
      htmlBuffer.writeln('<body>');
      
      htmlBuffer.writeln('<div class="container">');
      
      // 标题
      htmlBuffer.writeln('<h1>房间费用报表</h1>');
      
      // 房间信息
      htmlBuffer.writeln('<div class="room-info">');
      htmlBuffer.writeln('<div class="room-number">${roomData.floor}-${roomData.roomNumber}</div>');
       htmlBuffer.writeln('<div class="period">${year}年${month}月</div>');
      htmlBuffer.writeln('</div>');
      
      // 费用明细
      htmlBuffer.writeln('<div class="fee-details">');
      
      htmlBuffer.writeln('<div class="fee-item">');
      htmlBuffer.writeln('<div><div class="fee-label">租金</div></div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.rent.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('<div class="fee-item">');
      htmlBuffer.writeln('<div><div class="fee-label">水费</div><div class="fee-detail">${roomData.waterFee.previousReading.toStringAsFixed(1)} → ${roomData.waterFee.currentReading.toStringAsFixed(1)} × ¥${roomData.waterFee.unitPrice.toStringAsFixed(2)}</div></div>');
       htmlBuffer.writeln('<div class="fee-amount">¥${roomData.waterFee.totalAmount.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('<div class="fee-item">');
      htmlBuffer.writeln('<div><div class="fee-label">电费</div><div class="fee-detail">${roomData.electricFee.previousReading.toStringAsFixed(1)} → ${roomData.electricFee.currentReading.toStringAsFixed(1)} × ¥${roomData.electricFee.unitPrice.toStringAsFixed(2)}</div></div>');
       htmlBuffer.writeln('<div class="fee-amount">¥${roomData.electricFee.totalAmount.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('<div class="fee-item">');
      htmlBuffer.writeln('<div><div class="fee-label">燃气费</div></div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.gasFee.totalAmount.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('<div class="fee-item">');
      htmlBuffer.writeln('<div><div class="fee-label">公共服务费</div></div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.publicServiceFee.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('<div class="fee-item">');
      htmlBuffer.writeln('<div><div class="fee-label">卫生费</div></div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.sanitationFee.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('</div>');
      
      // 总计
      htmlBuffer.writeln('<div class="total-section">');
      htmlBuffer.writeln('<div class="total-amount">总计: ¥${roomData.totalAmount.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      
      // 导出时间
      htmlBuffer.writeln('<div class="export-time">导出时间: ${DateTime.now().toString().substring(0, 19)}</div>');
      
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('</body>');
      htmlBuffer.writeln('</html>');
      
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${roomData.floor}-${roomData.roomNumber}_${year}年${month}月_${DateTime.now().millisecondsSinceEpoch}.html';
       final file = File('${directory.path}/$fileName');
      
      // 写入文件
      await file.writeAsString(htmlBuffer.toString(), encoding: utf8);
      
      return file.path;
    } catch (e) {
      throw Exception('导出单房间HTML失败: $e');
    }
  }

  /// 获取导出文件的存储目录
  static Future<String> getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}