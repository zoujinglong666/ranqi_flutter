import 'dart:convert';
import 'package:http/http.dart' as http;

class RecognitionService {
  // 阿里云燃气表识别API配置
  static const String _apiUrl = 'https://gas.market.alicloudapi.com/api/predict/gas_meter_end2end';
  static const String _appCode = '1e7ce21614824138813611e3ed70533f';
  
  static Future<String> recognizeMeter(String base64Image) async {
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
          final integer = result['integer'] ?? '';
          final decimal = result['decimal'] ?? '';
          
          // 组合整数和小数部分
          String reading = '';
          if (integer.isNotEmpty && decimal.isNotEmpty) {
            reading = '$integer.$decimal';
          } else if (integer.isNotEmpty) {
            reading = integer;
          } else if (decimal.isNotEmpty) {
            reading = '0.$decimal';
          } else {
            reading = '无法识别';
          }
          
          // 获取识别详情（可选）
          final requestId = result['request_id'] ?? '';
          final retList = result['ret'] as List? ?? [];
          
          // 构建详细结果信息
          String detailInfo = '';
          if (retList.isNotEmpty) {
            for (var item in retList) {
              final word = item['word'] ?? '';
              final prob = item['prob'] ?? 0.0;
              final className = item['class'] ?? '';
              final confidence = (prob * 100).toStringAsFixed(1);
              detailInfo += '$className: $word (置信度: $confidence%)\n';
            }
          }
          
          return '读数: $reading\n$detailInfo';
        } else {
          // API返回错误
          final errorMsg = result['message'] ?? result['error'] ?? '识别失败';
          throw Exception('API返回错误: $errorMsg');
        }
      } else {
        throw Exception('HTTP请求失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // 如果是网络错误或其他异常，返回模拟数据用于测试
      throw Exception('识别失败: $e');
    }
  }
  

}