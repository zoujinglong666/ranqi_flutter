import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' show base64Encode;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

import '../models/export_config.dart';
import 'fee_calculation_service.dart';
import 'storage_service.dart';

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
    String? periodType,
  }) async {
    try {
      // 创建HTML内容
      final StringBuffer htmlBuffer = StringBuffer();
      
      htmlBuffer.writeln('<!DOCTYPE html>');
      htmlBuffer.writeln('<html>');
      htmlBuffer.writeln('<head>');
      htmlBuffer.writeln('<meta charset="UTF-8">');
      final title = _getReportTitle(periodType, year, month);
      htmlBuffer.writeln('<title>$title</title>');
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
      htmlBuffer.writeln('<h1>$title</h1>');
      
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
      final fileName = '${_getFileNamePrefix(periodType, year, month)}_${DateTime.now().millisecondsSinceEpoch}.html';
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

  /// 导出单个房间的图片报表
  static Future<String> exportSingleRoomToImage({
    required FeeCalculationResult roomData,
    required int year,
    required int month,
    String? periodType,
    ExportConfig? config,
    required BuildContext context,
  }) async {
    try {
      // 获取导出配置
      final exportConfig = config ?? await StorageService.getExportConfig();
      
      // 创建截图控制器
      final screenshotController = ScreenshotController();
      
      // 创建报表Widget
      final reportWidget = _buildReportWidget(
        context: context,
        roomData: roomData,
        year: year,
        month: month,
        periodType: periodType ?? '月度',
        exportConfig: exportConfig,
      );
      
      // 截图
      final Uint8List imageBytes = await screenshotController.captureFromWidget(
        reportWidget,
        pixelRatio: 2.0,
      );
      
      // 保存到文件
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${roomData.floor}-${roomData.roomNumber}_${year}年${month}月_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(imageBytes);
      
      return file.path;
    } catch (e) {
      throw Exception('导出图片失败: $e');
    }
  }

  /// 保存单个房间图片报表到相册
  static Future<bool> saveRoomImageToGallery({
    required FeeCalculationResult roomData,
    required int year,
    required int month,
    String? periodType,
    ExportConfig? config,
    required BuildContext context,
  }) async {
    try {
      // 获取导出配置
      final exportConfig = config ?? await StorageService.getExportConfig();
      
      // 创建截图控制器
      final screenshotController = ScreenshotController();
      
      // 创建报表Widget
      final reportWidget = _buildReportWidget(
        context: context,
        roomData: roomData,
        year: year,
        month: month,
        periodType: periodType ?? '月度',
        exportConfig: exportConfig,
      );
      
      // 截图
      final Uint8List imageBytes = await screenshotController.captureFromWidget(
        reportWidget,
        pixelRatio: 2.0,
      );
      
      // 保存到相册
      await Gal.putImageBytes(imageBytes);
      
      return true;
    } catch (e) {
      throw Exception('保存图片到相册失败: $e');
    }
  }

  /// 构建报表Widget
  // static Widget _buildReportWidget({
  //   required FeeCalculationResult roomData,
  //   required int year,
  //   required int month,
  //   required String periodType,
  //   required ExportConfig exportConfig,
  // }) {
  //   // 动态计算尺寸，支持不同屏幕比例
  //   const double baseWidth = 1080;
  //   const double baseHeight = 1920;
  //   const double aspectRatio = baseWidth / baseHeight;
  //
  //   return MediaQuery(
  //     data: const MediaQueryData(
  //       size: Size(baseWidth, baseHeight),
  //       devicePixelRatio: 2.0,
  //       textScaleFactor: 1.0,
  //     ),
  //     child: Directionality(
  //       textDirection: TextDirection.ltr,
  //       child: Container(
  //         width: baseWidth,
  //         height: baseHeight,
  //         decoration: const BoxDecoration(
  //           gradient: LinearGradient(
  //             begin: Alignment.topCenter,
  //             end: Alignment.bottomCenter,
  //             colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  //           ),
  //         ),
  //         child: Container(
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(16),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.15),
  //                 blurRadius: 30,
  //                 offset: const Offset(0, 15),
  //               ),
  //             ],
  //           ),
  //           child: Stack(
  //             children: [
  //               // 主要内容
  //               Positioned.fill(
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(16),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.stretch,
  //                     children: [
  //                       // 头部 - 固定高度
  //                       _buildReportHeader(roomData, exportConfig),
  //                       const SizedBox(height: 8),
  //
  //                       // 时间段 - 固定高度
  //                       _buildPeriodInfo(periodType, year, month),
  //                       const SizedBox(height: 8),
  //
  //                       // 费用网格 - 占用剩余空间
  //                       Container(
  //                         padding: const EdgeInsets.symmetric(vertical: 8),
  //                         child: _buildFeesGrid(roomData),
  //                       ),
  //                       const SizedBox(height: 12),
  //
  //                       // 总计 - 固定高度
  //                       _buildTotalSection(roomData),
  //                       const SizedBox(height: 8),
  //
  //                       // 付款信息 - 固定高度
  //                       _buildPaymentInfo(exportConfig),
  //                       const SizedBox(height: 6),
  //
  //                       // 页脚 - 固定高度
  //                       _buildFooter(exportConfig),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               // 水印 - 平铺效果（置于最上层）
  //               if (exportConfig.enableWatermark)
  //                 Positioned.fill(
  //                   child: CustomPaint(
  //                     painter: WatermarkPainter(
  //                       text: exportConfig.watermarkText,
  //                       textStyle: TextStyle(
  //                         fontSize: 24,
  //                         color: Colors.grey.withOpacity(0.06),
  //                         fontWeight: FontWeight.w400,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }


  static Widget _buildReportWidget({
    required BuildContext context,
    required FeeCalculationResult roomData,
    required int year,
    required int month,
    required String periodType,
    required ExportConfig exportConfig,
  }) {
    final Size screenSize = MediaQuery.of(context).size;
    final double width = screenSize.width;
    final double height = screenSize.height;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        devicePixelRatio: 2.0,
        textScaleFactor: 1.0,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          width: width,
          height: height,
          // decoration: const BoxDecoration(
          //   gradient: LinearGradient(
          //     begin: Alignment.topCenter,
          //     end: Alignment.bottomCenter,
          //     colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          //   ),
          // ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              // borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildReportHeader(roomData, exportConfig),
                        const SizedBox(height: 8),
                        _buildPeriodInfo(periodType, year, month),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: _buildFeesGrid(roomData),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTotalSection(roomData),
                        const SizedBox(height: 8),
                        _buildPaymentInfo(exportConfig),
                        const SizedBox(height: 6),
                        _buildFooter(exportConfig),
                      ],
                    ),
                  ),
                ),
                if (exportConfig.enableWatermark)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: WatermarkPainter(
                        text: exportConfig.watermarkText,
                        textStyle: TextStyle(
                          fontSize: 24,
                          color: Colors.grey.withOpacity(0.06),
                          fontWeight: FontWeight.w400,
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


  static Widget _buildReportHeader(FeeCalculationResult roomData, ExportConfig exportConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  exportConfig.companyName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '房间费用报表',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${roomData.floor}-${roomData.roomNumber}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPeriodInfo(String periodType, int year, int month) {
    final periodText = _getPeriodText(periodType, year, month);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF4F46E5),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '报表周期：$periodText',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFeesGrid(FeeCalculationResult roomData) {
    final fees = [
      {'label': '租金', 'amount': roomData.rent, 'icon': '🏠', 'color': const Color(0xFFD97706)},
      {'label': '水费', 'amount': roomData.waterFee.totalAmount, 'icon': '💧', 'color': const Color(0xFF2563EB)},
      {'label': '电费', 'amount': roomData.electricFee.totalAmount, 'icon': '⚡', 'color': const Color(0xFFCA8A04)},
      {'label': '燃气费', 'amount': roomData.gasFee.totalAmount, 'icon': '🔥', 'color': const Color(0xFFE53E3E)},
      {'label': '公共服务费', 'amount': roomData.publicServiceFee, 'icon': '🏢', 'color': const Color(0xFF319795)},
      {'label': '卫生费', 'amount': roomData.sanitationFee, 'icon': '🧹', 'color': const Color(0xFF38A169)},
    ];

    return Column(
      children: [
        for (int i = 0; i < fees.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildFeeCard(fees[i]),
                ),
                const SizedBox(width: 10),
                if (i + 1 < fees.length)
                  Expanded(
                    child: _buildFeeCard(fees[i + 1]),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  static Widget _buildFeeCard(Map<String, dynamic> fee) {
    return Container(
      height: 80, // ✅ 固定高度避免溢出
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (fee['color'] as Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                fee['icon'] as String,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '¥${(fee['amount'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTotalSection(FeeCalculationResult roomData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '应缴费用总计',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            '¥${roomData.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPaymentInfo(ExportConfig exportConfig) {
    return Container(
      padding: const EdgeInsets.all(12), // ✅ 减少内边距
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8), // ✅ 减少圆角
        border: Border.all(color: const Color(0xFF0EA5E9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ 使用最小尺寸
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: Color(0xFF0EA5E9), size: 16), // ✅ 减少图标大小
              SizedBox(width: 6), // ✅ 减少间距
              Text(
                '付款信息',
                style: TextStyle(
                  fontSize: 14, // ✅ 减少字体大小
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // ✅ 减少间距
          _buildPaymentItem('银行名称', exportConfig.bankName),
          _buildPaymentItem('账号', exportConfig.accountNumber),
          _buildPaymentItem('户名', exportConfig.accountName),
          if (exportConfig.contactPhone.isNotEmpty)
            _buildPaymentItem('联系电话', exportConfig.contactPhone),
          
          // 添加收款码显示
          if (exportConfig.showPaymentQrCodes &&
              (exportConfig.alipayQrCodePath.isNotEmpty || exportConfig.wechatQrCodePath.isNotEmpty))
            _buildQrCodesSection(exportConfig),
        ],
      ),
    );
  }

  static Widget _buildPaymentItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4), // ✅ 减少底部间距
      child: Row(
        children: [
          SizedBox(
            width: 60, // ✅ 减少标签宽度
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12, // ✅ 减少字体大小
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12, // ✅ 减少字体大小
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1, // ✅ 限制为单行
              overflow: TextOverflow.ellipsis, // ✅ 超出部分显示省略号
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildQrCodesSection(ExportConfig exportConfig) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Divider(color: Color(0xFF0EA5E9), thickness: 1),
        const SizedBox(height: 8),
        const Row(
          children: [
            Icon(Icons.qr_code, color: Color(0xFF0EA5E9), size: 16),
            SizedBox(width: 6),
            Text(
              '扫码支付',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (exportConfig.alipayQrCodePath.isNotEmpty && File(exportConfig.alipayQrCodePath).existsSync())
              _buildQrCodeItem(
                imagePath: exportConfig.alipayQrCodePath,
                label: '支付宝',
                color: Colors.blue,
              ),
            if (exportConfig.wechatQrCodePath.isNotEmpty && File(exportConfig.wechatQrCodePath).existsSync())
              _buildQrCodeItem(
                imagePath: exportConfig.wechatQrCodePath,
                label: '微信支付',
                color: Colors.green,
              ),
          ],
        ),
      ],
    );
  }

  static Widget _buildQrCodeItem({
    required String imagePath,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.error,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  static Widget _buildFooter(ExportConfig exportConfig) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (exportConfig.reportFooter.isNotEmpty) ...[
          Text(
            exportConfig.reportFooter,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
        ],
        Text(
          '导出时间：${DateTime.now().toString().substring(0, 19)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
          textAlign: TextAlign.center,
        ),

        if (exportConfig.contactEmail.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '联系邮箱：${exportConfig.contactEmail}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
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
    String? periodType,
    ExportConfig? config,
  }) async {
    try {
      // 获取导出配置
      final exportConfig = config ?? await StorageService.getExportConfig();
      
      // 创建HTML内容
      final StringBuffer htmlBuffer = StringBuffer();
      
      htmlBuffer.writeln('<!DOCTYPE html>');
      htmlBuffer.writeln('<html>');
      htmlBuffer.writeln('<head>');
      htmlBuffer.writeln('<meta charset="UTF-8">');
      htmlBuffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
      htmlBuffer.writeln('<title>房间费用报表 - ${roomData.floor}-${roomData.roomNumber}</title>');
      htmlBuffer.writeln('<style>');
      htmlBuffer.writeln('''
        @import url('https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;500;600;700;800&display=swap');
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        :root {
          --primary-color: #2563eb;
          --primary-light: #dbeafe;
          --primary-dark: #1e40af;
          --secondary-color: #0ea5e9;
          --accent-color: #f59e0b;
          --danger-color: #dc2626;
          --success-color: #10b981;
          --text-primary: #1e293b;
          --text-secondary: #64748b;
          --bg-light: #f8fafc;
          --border-light: #e2e8f0;
          --card-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        }
        
        body { 
          font-family: 'Nunito', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
          min-height: 100vh;
          padding: 40px 20px;
          position: relative;
          color: var(--text-primary);
          line-height: 1.6;
        }
        
        ${exportConfig.enableWatermark ? '''
        body::before {
          content: "${exportConfig.watermarkText}";
          position: fixed;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%) rotate(-30deg);
          font-size: 120px;
          color: rgba(37, 99, 235, 0.03);
          font-weight: 800;
          z-index: 0;
          pointer-events: none;
          white-space: nowrap;
          letter-spacing: 2px;
        }
        ''' : ''}
        
        .container {
          max-width: 850px;
          margin: 0 auto;
          background: #ffffff;
          border-radius: 16px;
          box-shadow: var(--card-shadow);
          overflow: hidden;
          position: relative;
          z-index: 1;
        }
        
        .header {
          background: linear-gradient(135deg, var(--primary-color) 0%, var(--primary-dark) 100%);
          color: white;
          padding: 40px 30px;
          text-align: center;
          position: relative;
        }
        
        .header::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M11 18c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm48 25c3.866 0 7-3.134 7-7s-3.134-7-7-7-7 3.134-7 7 3.134 7 7 7zm-43-7c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm63 31c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM34 90c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zm56-76c1.657 0 3-1.343 3-3s-1.343-3-3-3-3 1.343-3 3 1.343 3 3 3zM12 86c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm28-65c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm23-11c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-6 60c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm29 22c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zM32 63c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm57-13c2.76 0 5-2.24 5-5s-2.24-5-5-5-5 2.24-5 5 2.24 5 5 5zm-9-21c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM60 91c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM35 41c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2zM12 60c1.105 0 2-.895 2-2s-.895-2-2-2-2 .895-2 2 .895 2 2 2z' fill='%23ffffff' fill-opacity='0.1' fill-rule='evenodd'/%3E%3C/svg%3E");
          opacity: 0.5;
        }
        
        .company-info {
          position: relative;
          z-index: 2;
        }
        
        .company-name {
          font-size: 32px;
          font-weight: 800;
          margin-bottom: 8px;
          letter-spacing: -0.5px;
          text-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .report-title {
          font-size: 18px;
          font-weight: 500;
          opacity: 0.9;
          margin-bottom: 24px;
          letter-spacing: 1px;
          text-transform: uppercase;
        }
        
        .room-badge {
          display: inline-block;
          background: rgba(255, 255, 255, 0.2);
          padding: 12px 30px;
          border-radius: 50px;
          font-size: 24px;
          font-weight: 700;
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255, 255, 255, 0.3);
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          letter-spacing: 1px;
        }
        
        .content {
          padding: 40px 30px;
          background-color: #ffffff;
        }
        
        .period-info {
          text-align: center;
          margin-bottom: 40px;
          padding: 20px;
          background: linear-gradient(135deg, var(--primary-light) 0%, #e0f2fe 100%);
          border-radius: 12px;
          border: 1px solid var(--primary-light);
          box-shadow: 0 2px 4px rgba(37, 99, 235, 0.1);
        }
        
        .period-text {
          font-size: 18px;
          color: var(--primary-dark);
          font-weight: 600;
        }
        
        .fees-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 24px;
          margin-bottom: 40px;
        }
        
        .fee-card {
          background: #ffffff;
          border-radius: 12px;
          padding: 24px;
          transition: all 0.3s ease;
          position: relative;
          overflow: hidden;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
          border: 1px solid var(--border-light);
        }
        
        .fee-card::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          width: 6px;
          height: 100%;
          background: var(--primary-color);
          border-radius: 3px 0 0 3px;
        }
        
        .fee-card:hover {
          transform: translateY(-4px);
          box-shadow: 0 12px 20px rgba(0, 0, 0, 0.1);
        }
        
        .fee-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 16px;
          padding-bottom: 12px;
          border-bottom: 1px dashed var(--border-light);
        }
        
        .fee-label {
          font-size: 18px;
          font-weight: 700;
          color: var(--text-primary);
          display: flex;
          align-items: center;
          gap: 10px;
        }
        
        .fee-icon {
          width: 36px;
          height: 36px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 18px;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .fee-amount {
          font-size: 24px;
          font-weight: 800;
          color: var(--success-color);
          background: rgba(16, 185, 129, 0.1);
          padding: 6px 12px;
          border-radius: 8px;
        }
        
        .fee-detail {
          font-size: 15px;
          color: var(--text-secondary);
          margin-top: 12px;
          padding: 14px;
          background: var(--bg-light);
          border-radius: 8px;
          border-left: 4px solid var(--secondary-color);
          line-height: 1.8;
        }
        
        .total-section {
          background: linear-gradient(135deg, var(--danger-color) 0%, #991b1b 100%);
          color: white;
          padding: 36px;
          border-radius: 16px;
          text-align: center;
          margin-bottom: 40px;
          position: relative;
          overflow: hidden;
          box-shadow: 0 10px 25px rgba(220, 38, 38, 0.2);
        }
        
        .total-section::before {
          content: '';
          position: absolute;
          top: -50%;
          left: -50%;
          width: 200%;
          height: 200%;
          background: radial-gradient(circle, rgba(255,255,255,0.15) 0%, transparent 70%);
          animation: shimmer 4s ease-in-out infinite;
        }
        
        @keyframes shimmer {
          0%, 100% { transform: translateX(-30%) translateY(-30%) rotate(0deg); }
          50% { transform: translateX(0%) translateY(0%) rotate(10deg); }
        }
        
        .total-label {
          font-size: 20px;
          font-weight: 600;
          margin-bottom: 16px;
          opacity: 0.9;
          position: relative;
          z-index: 2;
          letter-spacing: 1px;
          text-transform: uppercase;
        }
        
        .total-value {
          font-size: 42px;
          font-weight: 800;
          position: relative;
          z-index: 2;
          text-shadow: 0 2px 4px rgba(0,0,0,0.2);
          letter-spacing: -0.5px;
        }
        
        .payment-info {
          background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
          border-radius: 16px;
          padding: 30px;
          margin-bottom: 30px;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
          border: 1px solid #bfdbfe;
        }
        
        .payment-title {
          font-size: 20px;
          font-weight: 700;
          color: var(--primary-dark);
          margin-bottom: 20px;
          display: flex;
          align-items: center;
          gap: 10px;
          padding-bottom: 12px;
          border-bottom: 2px solid #bfdbfe;
        }
        
        .payment-details {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 24px;
        }
        
        .payment-item {
          display: flex;
          flex-direction: column;
          gap: 8px;
          background: rgba(255, 255, 255, 0.7);
          padding: 16px;
          border-radius: 10px;
          border: 1px solid #bfdbfe;
        }
        
        .payment-label {
          font-size: 13px;
          color: var(--text-secondary);
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        
        .payment-value {
          font-size: 18px;
          font-weight: 700;
          color: var(--primary-dark);
        }
        
        .footer {
          text-align: center;
          padding: 30px;
          background: var(--bg-light);
          border-top: 1px solid var(--border-light);
          color: var(--text-secondary);
        }
        
        .footer-text {
          font-size: 15px;
          margin-bottom: 10px;
          font-weight: 600;
        }
        
        .export-time {
          font-size: 13px;
          opacity: 0.8;
          margin-bottom: 8px;
        }
        
        .contact-info {
          margin-top: 16px;
          font-size: 14px;
          background: rgba(14, 165, 233, 0.1);
          display: inline-block;
          padding: 8px 16px;
          border-radius: 50px;
          color: var(--secondary-color);
        }
        
        .qr-codes-section {
          margin-top: 20px;
          padding: 20px;
          background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
          border-radius: 12px;
          border: 1px solid #bfdbfe;
        }
        
        .qr-codes-title {
          font-size: 18px;
          font-weight: 700;
          color: var(--primary-dark);
          margin-bottom: 16px;
          text-align: center;
        }
        
        .qr-codes-container {
          display: flex;
          justify-content: center;
          gap: 30px;
          flex-wrap: wrap;
        }
        
        .qr-code-item {
          text-align: center;
          background: white;
          padding: 16px;
          border-radius: 12px;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          border: 2px solid #e2e8f0;
        }
        
        .qr-code-image {
          width: 120px;
          height: 120px;
          border-radius: 8px;
          object-fit: cover;
          border: 2px solid #f1f5f9;
        }
        
        .qr-code-label {
          font-size: 14px;
          font-weight: 600;
          color: var(--text-primary);
          margin-top: 8px;
        }
        
        .qr-code {
          margin-top: 20px;
          text-align: center;
        }
        
        .qr-code img {
          width: 120px;
          height: 120px;
          border-radius: 8px;
          border: 4px solid white;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .qr-code-text {
          font-size: 12px;
          color: var(--text-secondary);
          margin-top: 8px;
        }
        
        @media (max-width: 768px) {
          body { padding: 20px 10px; }
          .container { margin: 0; border-radius: 12px; }
          .header { padding: 30px 20px; }
          .content { padding: 30px 20px; }
          .company-name { font-size: 26px; }
          .room-badge { font-size: 20px; }
          .fees-grid { grid-template-columns: 1fr; }
          .total-value { font-size: 32px; }
          .payment-details { grid-template-columns: 1fr; }
        }
        
        @media print {
          body { background: white; padding: 0; }
          .container { box-shadow: none; max-width: none; }
          .fee-card:hover { transform: none; box-shadow: none; }
        }
      ''');
      htmlBuffer.writeln('</style>');
      htmlBuffer.writeln('</head>');
      htmlBuffer.writeln('<body>');
      
      htmlBuffer.writeln('<div class="container">');
      
      // 头部信息
      htmlBuffer.writeln('<div class="header">');
      htmlBuffer.writeln('<div class="company-info">');
      htmlBuffer.writeln('<div class="company-name">${exportConfig.companyName}</div>');
      htmlBuffer.writeln('<div class="report-title">房间费用结算单</div>');
      htmlBuffer.writeln('<div class="room-badge">${roomData.floor}-${roomData.roomNumber}</div>');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('<div class="content">');
      
      // 时间段信息
      final periodText = _getPeriodText(periodType, year, month);
      htmlBuffer.writeln('<div class="period-info">');
      htmlBuffer.writeln('<div class="period-text">📅 结算周期：$periodText</div>');
      htmlBuffer.writeln('</div>');
      
      // 费用明细网格
      htmlBuffer.writeln('<div class="fees-grid">');
      
      // 租金卡片
      htmlBuffer.writeln('<div class="fee-card">');
      htmlBuffer.writeln('<div class="fee-header">');
      htmlBuffer.writeln('<div class="fee-label">');
      htmlBuffer.writeln('<div class="fee-icon" style="background: #fef3c7; color: #d97706;">🏠</div>');
      htmlBuffer.writeln('房屋租金');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.rent.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-detail">');
      htmlBuffer.writeln('月度基础租金');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('</div>');
      
      // 水费卡片
      htmlBuffer.writeln('<div class="fee-card">');
      htmlBuffer.writeln('<div class="fee-header">');
      htmlBuffer.writeln('<div class="fee-label">');
      htmlBuffer.writeln('<div class="fee-icon" style="background: #dbeafe; color: #2563eb;">💧</div>');
      htmlBuffer.writeln('水费');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.waterFee.totalAmount.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      if (roomData.waterFee.usage > 0) {
        htmlBuffer.writeln('<div class="fee-detail">');
        htmlBuffer.writeln('<strong>用量:</strong> ${roomData.waterFee.usage.toStringAsFixed(1)} 吨<br>');
        htmlBuffer.writeln('<strong>单价:</strong> ¥${roomData.waterFee.unitPrice.toStringAsFixed(2)}/吨<br>');
        htmlBuffer.writeln('<strong>读数变化:</strong> ${roomData.waterFee.previousReading.toStringAsFixed(1)} → ${roomData.waterFee.currentReading.toStringAsFixed(1)}');
        htmlBuffer.writeln('</div>');
      } else {
        htmlBuffer.writeln('<div class="fee-detail">');
        htmlBuffer.writeln('本期无用水记录');
        htmlBuffer.writeln('</div>');
      }
      htmlBuffer.writeln('</div>');
      
      // 电费卡片
      htmlBuffer.writeln('<div class="fee-card">');
      htmlBuffer.writeln('<div class="fee-header">');
      htmlBuffer.writeln('<div class="fee-label">');
      htmlBuffer.writeln('<div class="fee-icon" style="background: #fef9c3; color: #ca8a04;">⚡</div>');
      htmlBuffer.writeln('电费');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.electricFee.totalAmount.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      if (roomData.electricFee.usage > 0) {
        htmlBuffer.writeln('<div class="fee-detail">');
        htmlBuffer.writeln('<strong>用量:</strong> ${roomData.electricFee.usage.toStringAsFixed(1)} 度<br>');
        htmlBuffer.writeln('<strong>单价:</strong> ¥${roomData.electricFee.unitPrice.toStringAsFixed(2)}/度<br>');
        htmlBuffer.writeln('<strong>读数变化:</strong> ${roomData.electricFee.previousReading.toStringAsFixed(1)} → ${roomData.electricFee.currentReading.toStringAsFixed(1)}');
        htmlBuffer.writeln('</div>');
      } else {
        htmlBuffer.writeln('<div class="fee-detail">');
        htmlBuffer.writeln('本期无用电记录');
        htmlBuffer.writeln('</div>');
      }
      htmlBuffer.writeln('</div>');
      
      // 燃气费卡片
      htmlBuffer.writeln('<div class="fee-card">');
      htmlBuffer.writeln('<div class="fee-header">');
      htmlBuffer.writeln('<div class="fee-label">');
      htmlBuffer.writeln('<div class="fee-icon" style="background: #fed7d7; color: #e53e3e;">🔥</div>');
      htmlBuffer.writeln('燃气费');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.gasFee.totalAmount.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      if (roomData.gasFee.usage > 0) {
        htmlBuffer.writeln('<div class="fee-detail">');
        htmlBuffer.writeln('<strong>用量:</strong> ${roomData.gasFee.usage.toStringAsFixed(1)} 立方米<br>');
        htmlBuffer.writeln('<strong>单价:</strong> ¥${roomData.gasFee.unitPrice.toStringAsFixed(2)}/立方米<br>');
        if (roomData.gasFee.previousReading > 0 || roomData.gasFee.currentReading > 0) {
          htmlBuffer.writeln('<strong>读数变化:</strong> ${roomData.gasFee.previousReading.toStringAsFixed(1)} → ${roomData.gasFee.currentReading.toStringAsFixed(1)}');
        }
        htmlBuffer.writeln('</div>');
      } else {
        htmlBuffer.writeln('<div class="fee-detail">');
        htmlBuffer.writeln('本期无燃气使用记录');
        htmlBuffer.writeln('</div>');
      }
      htmlBuffer.writeln('</div>');
      
      // 公共服务费卡片
      htmlBuffer.writeln('<div class="fee-card">');
      htmlBuffer.writeln('<div class="fee-header">');
      htmlBuffer.writeln('<div class="fee-label">');
      htmlBuffer.writeln('<div class="fee-icon" style="background: #e6fffa; color: #319795;">🏢</div>');
      htmlBuffer.writeln('公共服务费');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.publicServiceFee.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-detail">');
      htmlBuffer.writeln('包含公共区域维护、安保服务等费用');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('</div>');
      
      // 卫生费卡片
      htmlBuffer.writeln('<div class="fee-card">');
      htmlBuffer.writeln('<div class="fee-header">');
      htmlBuffer.writeln('<div class="fee-label">');
      htmlBuffer.writeln('<div class="fee-icon" style="background: #f0fff4; color: #38a169;">🧹</div>');
      htmlBuffer.writeln('卫生费');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-amount">¥${roomData.sanitationFee.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="fee-detail">');
      htmlBuffer.writeln('包含公共区域清洁、垃圾处理等费用');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('</div>'); // 结束 fees-grid
      
      // 总计部分
      htmlBuffer.writeln('<div class="total-section">');
      htmlBuffer.writeln('<div class="total-label">应缴费用总计</div>');
      htmlBuffer.writeln('<div class="total-value">¥${roomData.totalAmount.toStringAsFixed(2)}</div>');
      htmlBuffer.writeln('</div>');
      
      // 付款信息
      htmlBuffer.writeln('<div class="payment-info">');
      htmlBuffer.writeln('<div class="payment-title">');
      htmlBuffer.writeln('💳 付款方式');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="payment-details">');
      htmlBuffer.writeln('<div class="payment-item">');
      htmlBuffer.writeln('<div class="payment-label">银行名称</div>');
      htmlBuffer.writeln('<div class="payment-value">${exportConfig.bankName}</div>');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="payment-item">');
      htmlBuffer.writeln('<div class="payment-label">账号</div>');
      htmlBuffer.writeln('<div class="payment-value">${exportConfig.accountNumber}</div>');
      htmlBuffer.writeln('</div>');
      htmlBuffer.writeln('<div class="payment-item">');
      htmlBuffer.writeln('<div class="payment-label">户名</div>');
      htmlBuffer.writeln('<div class="payment-value">${exportConfig.accountName}</div>');
      htmlBuffer.writeln('</div>');
      if (exportConfig.contactPhone.isNotEmpty) {
        htmlBuffer.writeln('<div class="payment-item">');
        htmlBuffer.writeln('<div class="payment-label">联系电话</div>');
        htmlBuffer.writeln('<div class="payment-value">${exportConfig.contactPhone}</div>');
        htmlBuffer.writeln('</div>');
      }
      htmlBuffer.writeln('</div>');
      
      // 添加收款码显示
      if (exportConfig.showPaymentQrCodes && 
          (exportConfig.alipayQrCodePath.isNotEmpty || exportConfig.wechatQrCodePath.isNotEmpty)) {
        htmlBuffer.writeln('<div class="qr-codes-section">');
        htmlBuffer.writeln('<div class="qr-codes-title">📱 扫码支付</div>');
        htmlBuffer.writeln('<div class="qr-codes-container">');
        
        if (exportConfig.alipayQrCodePath.isNotEmpty && File(exportConfig.alipayQrCodePath).existsSync()) {
          final alipayBase64 = await _imageToBase64(exportConfig.alipayQrCodePath);
          htmlBuffer.writeln('<div class="qr-code-item">');
          htmlBuffer.writeln('<img src="data:image/jpeg;base64,$alipayBase64" alt="支付宝收款码" class="qr-code-image"/>');
          htmlBuffer.writeln('<div class="qr-code-label">支付宝</div>');
          htmlBuffer.writeln('</div>');
        }
        
        if (exportConfig.wechatQrCodePath.isNotEmpty && File(exportConfig.wechatQrCodePath).existsSync()) {
          final wechatBase64 = await _imageToBase64(exportConfig.wechatQrCodePath);
          htmlBuffer.writeln('<div class="qr-code-item">');
          htmlBuffer.writeln('<img src="data:image/jpeg;base64,$wechatBase64" alt="微信收款码" class="qr-code-image"/>');
          htmlBuffer.writeln('<div class="qr-code-label">微信支付</div>');
          htmlBuffer.writeln('</div>');
        }
        
        htmlBuffer.writeln('</div>');
        htmlBuffer.writeln('</div>');
      }
      
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('</div>'); // 结束 content
      
      // 页脚
      htmlBuffer.writeln('<div class="footer">');
      if (exportConfig.reportFooter.isNotEmpty) {
        htmlBuffer.writeln('<div class="footer-text">${exportConfig.reportFooter}</div>');
      }
      htmlBuffer.writeln('<div class="export-time">生成时间：${DateTime.now().toString().substring(0, 19)}</div>');
      if (exportConfig.contactEmail.isNotEmpty) {
        htmlBuffer.writeln('<div class="contact-info">📧 ${exportConfig.contactEmail}</div>');
      }
      
      // 添加二维码占位符（实际应用中可以替换为真实的二维码）
      htmlBuffer.writeln('<div class="qr-code">');
      htmlBuffer.writeln('<img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAgMTAwIj48cGF0aCBmaWxsPSIjMjU2M2ViIiBkPSJNMCAwaDEwMHYxMDBIMHoiLz48cGF0aCBmaWxsPSIjZmZmIiBkPSJNMzAgMzBoNDB2NDBIMzB6Ii8+PHBhdGggZmlsbD0iIzI1NjNlYiIgZD0iTTQwIDQwaDIwdjIwSDQweiIvPjwvc3ZnPg==" alt="付款二维码"/>');
      htmlBuffer.writeln('<div class="qr-code-text">扫码支付费用</div>');
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('</div>');
      
      htmlBuffer.writeln('</div>'); // 结束 container
      htmlBuffer.writeln('</body>');
      htmlBuffer.writeln('</html>');
      
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final filePrefix = _getSingleRoomFilePrefix(periodType, roomData.floor, roomData.roomNumber, year, month);
      final fileName = '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.html';
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
  
  /// 根据时间段类型获取报表标题
  static String _getReportTitle(String? periodType, int year, int month) {
    switch (periodType) {
      case '年度':
        return '年度报表 - ${year}年';
      case '近半年':
        return '近半年报表';
      case '近三月':
        return '近三月报表';
      default:
        return '月度报表 - ${year}年${month}月';
    }
  }
  
  /// 根据时间段类型获取文件名前缀
  static String _getFileNamePrefix(String? periodType, int year, int month) {
    switch (periodType) {
      case '年度':
        return '年度报表_${year}年';
      case '近半年':
        return '近半年报表';
      case '近三月':
        return '近三月报表';
      default:
        return '月度报表_${year}年${month}月';
    }
  }
  
  /// 获取时间段显示文本
  static String _getPeriodText(String? periodType, int year, int month) {
    switch (periodType) {
      case '年度':
        return '${year}年';
      case '近半年':
        return '近半年';
      case '近三月':
        return '近三月';
      default:
        return '${year}年${month}月';
    }
  }
  
  /// 获取单个房间文件名前缀
  static String _getSingleRoomFilePrefix(String? periodType, String floor, String roomNumber, int year, int month) {
    final periodText = _getPeriodText(periodType, year, month);
    return '${floor}-${roomNumber}_$periodText';
  }
  
  /// 生成HTML内容用于预览（不保存文件）
  static String generateMonthlyReportHtmlContent({
    required List<FeeCalculationResult> reportData,
    required int year,
    required int month,
    String? periodType,
  }) {
    // 创建HTML内容
    final StringBuffer htmlBuffer = StringBuffer();
    
    htmlBuffer.writeln('<!DOCTYPE html>');
    htmlBuffer.writeln('<html>');
    htmlBuffer.writeln('<head>');
    htmlBuffer.writeln('<meta charset="UTF-8">');
    final title = _getReportTitle(periodType, year, month);
    htmlBuffer.writeln('<title>$title</title>');
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
    htmlBuffer.writeln('<h1>$title</h1>');
    
    // 汇总信息
    htmlBuffer.writeln('<div class="summary">');
    htmlBuffer.writeln('<h2>汇总信息</h2>');
    htmlBuffer.writeln('<div class="summary-grid">');
    htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">房间数</div><div class="summary-value">${reportData.length}</div></div>');
    htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总租金</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.rent.toDouble()).toStringAsFixed(2)}</div></div>');
    htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总水费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.waterFee.totalAmount.toDouble()).toStringAsFixed(2)}</div></div>');
    htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总电费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.electricFee.totalAmount.toDouble()).toStringAsFixed(2)}</div></div>');
    htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总燃气费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.gasFee.totalAmount.toDouble()).toStringAsFixed(2)}</div></div>');
    htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总公共服务费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.publicServiceFee.toDouble()).toStringAsFixed(2)}</div></div>');
    htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总卫生费</div><div class="summary-value">¥${reportData.fold<double>(0.0, (sum, item) => sum + item.sanitationFee.toDouble()).toStringAsFixed(2)}</div></div>');
    final totalAmount = reportData.fold<double>(0.0, (sum, item) => sum + item.totalAmount.toDouble());
    htmlBuffer.writeln('<div class="summary-item"><div class="summary-label">总计</div><div class="summary-value total-value">¥${totalAmount.toStringAsFixed(2)}</div></div>');
    htmlBuffer.writeln('</div>');
    htmlBuffer.writeln('</div>');
    
    // 详细表格
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
    
    // 预览时间
    htmlBuffer.writeln('<div class="export-time">预览时间: ${DateTime.now().toString().substring(0, 19)}</div>');
    
    htmlBuffer.writeln('</body>');
    htmlBuffer.writeln('</html>');
    
    return htmlBuffer.toString();
  }
  
  /// 生成单个房间HTML内容用于预览（不保存文件）
  static String generateSingleRoomHtmlContent({
    required FeeCalculationResult roomData,
    required int year,
    required int month,
    String? periodType,
  }) {
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
      .fee-label { font-weight: 600; color: #2c3e50; font-size: 16px; }
      .fee-detail { font-size: 12px; color: #7f8c8d; margin-top: 2px; }
      .fee-amount { font-weight: bold; color: #27ae60; font-size: 18px; }
      .total-amount { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); color: white; padding: 20px; border-radius: 8px; text-align: center; margin-top: 20px; }
      .total-label { font-size: 16px; margin-bottom: 5px; }
      .total-value { font-size: 28px; font-weight: bold; }
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
    final periodText = _getPeriodText(periodType, year, month);
    htmlBuffer.writeln('<div class="period">$periodText</div>');
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
    htmlBuffer.writeln('<div class="total-amount">');
    htmlBuffer.writeln('<div class="total-label">总计</div>');
    htmlBuffer.writeln('<div class="total-value">¥${roomData.totalAmount.toStringAsFixed(2)}</div>');
    htmlBuffer.writeln('</div>');
    
    htmlBuffer.writeln('</div>');
    
    htmlBuffer.writeln('</body>');
    htmlBuffer.writeln('</html>');
    
    return htmlBuffer.toString();
  }
}

/// 自定义水印绘制器，实现平铺效果
class WatermarkPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;

  WatermarkPainter({
    required this.text,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 计算平铺间距
    const double spacingX = 200.0;
    const double spacingY = 150.0;
    const double rotationAngle = -0.3; // 旋转角度

    // 计算需要绘制的行列数
    final int cols = (size.width / spacingX).ceil() + 2;
    final int rows = (size.height / spacingY).ceil() + 2;

    canvas.save();
    
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        canvas.save();
        
        // 计算位置（交错排列）
        final double x = col * spacingX + (row % 2 == 1 ? spacingX / 2 : 0);
        final double y = row * spacingY;
        
        // 移动到绘制位置
        canvas.translate(x, y);
        
        // 旋转
        canvas.rotate(rotationAngle);
        
        // 绘制文字
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        
        canvas.restore();
      }
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is! WatermarkPainter ||
        oldDelegate.text != text ||
        oldDelegate.textStyle != textStyle;
  }
}

/// 将图片文件转换为Base64字符串
Future<String> _imageToBase64(String imagePath) async {
  try {
    final file = File(imagePath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
    return '';
  } catch (e) {
    print('图片转Base64失败: $e');
    return '';
  }
}