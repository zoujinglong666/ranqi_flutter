import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meter_record.dart';

class RecognitionService {
  // 阿里云燃气表识别API配置
  static const String _apiUrl = 'https://gas.market.alicloudapi.com/api/predict/gas_meter_end2end';
  static const String _appCode = '1e7ce21614824138813611e3ed70533f';
  
  static Future<RecognitionResult> recognizeMeter(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'APPCODE $_appCode',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // 根据实际API返回格式解析结果
        if (result['success'] == true) {
          final integerPart = result['integer'] ?? '';
          final decimalPart = result['decimal'] ?? '';
          
          // 组合整数和小数部分
          String reading = '';
          if (integerPart.isNotEmpty && decimalPart.isNotEmpty) {
            reading = '$integerPart.$decimalPart';
          } else if (integerPart.isNotEmpty) {
            reading = integerPart;
          } else if (decimalPart.isNotEmpty) {
            reading = '0.$decimalPart';
          } else {
            reading = '无法识别';
          }
          
          // 获取识别详情（可选）
          final requestId = result['request_id'] ?? '';
          final retList = result['ret'] as List? ?? [];
          
          // 构建详细结果信息
          String detailInfo = '';
          List<RecognitionDetail> details = [];
          if (retList.isNotEmpty) {
            for (var item in retList) {
              final word = item['word'] ?? '';
              final prob = (item['prob'] ?? 0.0).toDouble();
              final className = item['class'] ?? '';
              final confidence = (prob * 100).toStringAsFixed(1);
              detailInfo += '$className: $word (置信度: $confidence%)\n';
              
              details.add(RecognitionDetail(
                word: word,
                probability: prob,
                className: className,
              ));
            }
          }
          
          return RecognitionResult(
            success: true,
            reading: reading,
            displayText: '读数: $reading\n$detailInfo',
            requestId: requestId,
            integerPart: integerPart,
            decimalPart: decimalPart,
            recognitionDetails: details,
          );
        } else {
          // API返回错误
          final errorMsg = result['message'] ?? result['error'] ?? '识别失败';
          return RecognitionResult(
            success: false,
            reading: '识别失败',
            displayText: 'API返回错误: $errorMsg',
            errorMessage: errorMsg,
          );
        }
      } else {
        return RecognitionResult(
          success: false,
          reading: '识别失败',
          displayText: 'HTTP请求失败: ${response.statusCode}',
          errorMessage: 'HTTP请求失败: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // 如果是网络错误或其他异常，返回错误结果
      return RecognitionResult(
        success: false,
        reading: '识别失败',
        displayText: '识别失败: $e',
        errorMessage: e.toString(),
      );
    }
  }
}

// 识别结果类
class RecognitionResult {
  final bool success;
  final String reading;
  final String displayText;
  final String? requestId;
  final String? integerPart;
  final String? decimalPart;
  final List<RecognitionDetail>? recognitionDetails;
  final String? errorMessage;

  RecognitionResult({
    required this.success,
    required this.reading,
    required this.displayText,
    this.requestId,
    this.integerPart,
    this.decimalPart,
    this.recognitionDetails,
    this.errorMessage,
  });
}