import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/meter_record.dart';
import '../models/room.dart';
import '../services/storage_service.dart';
import '../services/recognition_service.dart';
import '../services/event_manager.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String? _base64Image;
  String? _recognitionResult;
  String? _originalRecognitionResult; // 新增：保存原始识别结果
  RecognitionResult? _detailedResult; // 新增：保存详细的识别结果
  bool _isRecognizing = false;
  bool _isEditingResult = false;
  
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  
  List<Room> _availableRooms = [];
  int? _selectedFloor;
  String? _selectedRoom;
  String _selectedMeterType = '燃气'; // 新增：表计类型选择

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await StorageService.getRooms();
    setState(() {
      _availableRooms = rooms;
    });
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      
      setState(() {
        _image = file;
        _base64Image = base64;
        _recognitionResult = null;
      });
      
      _recognizeMeter();
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      
      setState(() {
        _image = file;
        _base64Image = base64;
        _recognitionResult = null;
      });
      
      _recognizeMeter();
    }
  }

  Future<void> _recognizeMeter() async {
    if (_base64Image == null) return;
    
    setState(() {
      _isRecognizing = true;
    });
    
    try {
      final result = await RecognitionService.recognizeMeter(_base64Image!);
      setState(() {
        _detailedResult = result;
        _recognitionResult = result.displayText;
        _originalRecognitionResult = result.displayText; // 保存原始识别结果
        _isEditingResult = false;
        _extractReadingToController(result.displayText);
      });
      
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? '识别失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('识别失败: $e')),
      );
    } finally {
      setState(() {
        _isRecognizing = false;
      });
    }
  }

  void _extractReadingToController(String result) {
    final regex = RegExp(r'读数[：:]\\s*([0-9]+\\.?[0-9]*)');
    final match = regex.firstMatch(result);
    if (match != null) {
      _resultController.text = match.group(1) ?? '';
    } else {
      final numberRegex = RegExp(r'([0-9]+\\.?[0-9]*)');
      final numberMatch = numberRegex.firstMatch(result);
      _resultController.text = numberMatch?.group(1) ?? '';
    }
  }

  void _startEditResult() {
    // 从当前识别结果中提取读数并显示在输入框中
    if (_recognitionResult != null) {
      _extractReadingToController(_recognitionResult!);
    }
    setState(() {
      _isEditingResult = true;
    });
  }

  void _saveEditedResult() {
    final editedReading = _resultController.text.trim();
    if (editedReading.isNotEmpty) {
      setState(() {
        _recognitionResult = '读数: $editedReading (手动修正)';
        _isEditingResult = false;
        // 更新详细结果，标记为手动修正
        if (_detailedResult != null) {
          _detailedResult = RecognitionResult(
            success: true,
            reading: editedReading,
            displayText: '读数: $editedReading (手动修正)',
            requestId: _detailedResult!.requestId,
            integerPart: _detailedResult!.integerPart,
            decimalPart: _detailedResult!.decimalPart,
            recognitionDetails: _detailedResult!.recognitionDetails,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('读数不能为空')),
      );
    }
  }

  void _cancelEditResult() {
    setState(() {
      _isEditingResult = false;
    });
    if (_recognitionResult != null) {
      _extractReadingToController(_recognitionResult!);
    }
  }

  void _resetToOriginalResult() {
    if (_originalRecognitionResult != null) {
      setState(() {
        _recognitionResult = _originalRecognitionResult;
        _isEditingResult = false;
        // 重置详细结果，移除手动修正标记
        if (_detailedResult != null) {
          _detailedResult = RecognitionResult(
            success: true,
            reading: _detailedResult!.reading,
            displayText: _originalRecognitionResult!,
            requestId: _detailedResult!.requestId,
            integerPart: _detailedResult!.integerPart,
            decimalPart: _detailedResult!.decimalPart,
            recognitionDetails: _detailedResult!.recognitionDetails,
          );
        }
      });
      _extractReadingToController(_originalRecognitionResult!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已重置为原始识别结果')),
      );
    }
  }

  void _showImagePreview() {
    if (_image == null) return;
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // 全屏图片查看器
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(0),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      _image!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                // 顶部状态栏和关闭按钮
                SafeArea(
                  child: Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '图片预览',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 底部操作提示
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '双指缩放 • 拖拽查看',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 点击空白区域关闭
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  List<int> _getAvailableFloors() {
    final floors = _availableRooms.map((room) => room.floor).toSet().toList();
    floors.sort();
    return floors;
  }

  List<String> _getRoomsForFloor(int floor) {
    return _availableRooms
        .where((room) => room.floor == floor)
        .map((room) => room.roomNumber)
        .toList();
  }

  Future<void> _saveRecord() async {
    if (_image == null || _recognitionResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先拍照并完成识别')),
      );
      return;
    }

    // 检查识别结果是否有效
    if (_recognitionResult!.contains('无法识别')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('识别失败，请重新拍照或手动修正读数'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    int? floor;
    String? roomNumber;

    if (_selectedFloor != null && _selectedRoom != null) {
      floor = _selectedFloor;
      roomNumber = _selectedRoom;
    } else if (_floorController.text.isNotEmpty && _roomController.text.isNotEmpty) {
      floor = int.tryParse(_floorController.text);
      roomNumber = _roomController.text;
    }

    if (floor == null || roomNumber == null || roomNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请选择或输入楼层和房间号')),
      );
      return;
    }

    try {
      // 将图片复制到应用的永久存储目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'meter_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final fileName = '${Uuid().v4()}.jpg';
      final permanentImagePath = path.join(imagesDir.path, fileName);
      await _image!.copy(permanentImagePath);

      final record = MeterRecord(
        id: Uuid().v4(),
        imagePath: permanentImagePath, // 使用永久路径
        base64Image: _base64Image!,
        recognitionResult: _recognitionResult!,
        floor: floor,
        roomNumber: roomNumber,
        timestamp: DateTime.now(),
        meterType: _selectedMeterType,
        // 新增：保存详细的API响应信息
        requestId: _detailedResult?.requestId,
        integerPart: _detailedResult?.integerPart,
        decimalPart: _detailedResult?.decimalPart,
        recognitionDetails: _detailedResult?.recognitionDetails,
        isManuallyEdited: _recognitionResult?.contains('(手动修正)') ?? false,
      );

      await StorageService.saveMeterRecord(record);
      
      // 发布记录新增事件
      eventManager.publish(
        EventType.recordAdded,
        data: {
          'record': record,
          'floor': floor,
          'roomNumber': roomNumber,
        },
      );
      
      // 如果是手动输入的楼层和房间号，自动添加到楼层管理
      if (_floorController.text.isNotEmpty && _roomController.text.isNotEmpty) {
        final existingRoom = _availableRooms.firstWhere(
          (room) => room.floor == floor && room.roomNumber == roomNumber,
          orElse: () => Room(id: '', floor: 0, roomNumber: ''),
        );
        
        if (existingRoom.id.isEmpty) {
          // 房间不存在，添加新房间
          final newRoom = Room(
            id: Uuid().v4(),
            floor: floor!,
            roomNumber: roomNumber!,
          );
          await StorageService.saveRoom(newRoom);
          await _loadRooms(); // 重新加载房间列表
          
          // 发布房间新增事件
          eventManager.publish(
            EventType.roomAdded,
            data: {
              'room': newRoom,
              'floor': floor,
              'roomNumber': roomNumber,
            },
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('记录保存成功，已自动添加房间 ${floor}楼${roomNumber}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('记录保存成功')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('记录保存成功')),
        );
      }
      
      setState(() {
        _image = null;
        _base64Image = null;
        _recognitionResult = null;
        _originalRecognitionResult = null; // 清空原始识别结果
        _detailedResult = null; // 清空详细结果
        _isEditingResult = false;
        _selectedFloor = null;
        _selectedRoom = null;
        _floorController.clear();
        _roomController.clear();
        _resultController.clear();
      });
    } catch (e) {
      print('保存失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('燃气表识别'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 拍照区域
            AppStyles.card(
              child: InkWell(
                onTap: () {
                  if (_image != null) {
                    // 有图片时放大查看
                    _showImagePreview();
                  } else {
                    // 没有图片时直接拍照
                    _takePicture();
                  }
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: _image != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              child: Image.file(
                                _image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            // 放大图标提示
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Text(
                                '拍摄燃气表读数',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeSubtitle,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingS),
                              Text(
                                '请确保表盘清晰可见，光线充足',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeBody,
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTheme.spacingS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '点击此处拍照',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // 拍照按钮
            Row(
              children: [
                Expanded(
                  child: AppStyles.primaryButton(
                    text: '拍照识别',
                    icon: Icons.camera_alt,
                    onPressed: _takePicture,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: AppStyles.secondaryButton(
                    text: '选择图片',
                    icon: Icons.photo_library,
                    onPressed: _pickFromGallery,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // 识别结果
            if (_isRecognizing)
              AppStyles.card(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      'AI智能识别中...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      '请稍候，正在分析表盘数据',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            
            if (_recognitionResult != null)
              AppStyles.card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '识别结果',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (!_isEditingResult)
                          TextButton.icon(
                            onPressed: _startEditResult,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('修改'),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    if (_isEditingResult) ...[
                      // 编辑模式
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '手动修正读数',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            TextField(
                              controller: _resultController,
                              decoration: AppStyles.inputDecoration(
                                labelText: '表计读数',
                                hintText: '请输入正确的读数',
                                prefixIcon: Icons.straighten,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              autofocus: true,
                              onSubmitted: (_) => _saveEditedResult(),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppStyles.primaryButton(
                                        text: '保存',
                                        icon: Icons.check,
                                        onPressed: _saveEditedResult,
                                        color: AppTheme.success,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingM),
                                    Expanded(
                                      child: AppStyles.secondaryButton(
                                        text: '取消',
                                        icon: Icons.close,
                                        onPressed: _cancelEditResult,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                if (_originalRecognitionResult != null && _originalRecognitionResult != _recognitionResult)
                                  SizedBox(
                                    width: double.infinity,
                                    child: AppStyles.secondaryButton(
                                      text: '重置为原始结果',
                                      icon: Icons.restore,
                                      onPressed: _resetToOriginalResult,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // 显示模式
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _recognitionResult!,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (_recognitionResult!.contains('(手动修正)')) ...[
                              const SizedBox(height: AppTheme.spacingS),
                              AppStyles.statusIndicator(
                                text: '已手动修正',
                                color: AppTheme.warning,
                                icon: Icons.edit,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            // 楼层和房间选择
            if (_recognitionResult != null) ...[
              AppStyles.card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '表计信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    
                    // 表计类型选择
                    Text(
                      '表计类型',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMeterType,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
                          items: [
                            DropdownMenuItem(
                              value: '燃气',
                              child: Row(
                                children: [
                                  Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Text('燃气表'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: '水电',
                              child: Row(
                                children: [
                                  Icon(Icons.water_drop, color: Colors.blue, size: 20),
                                  const SizedBox(width: AppTheme.spacingS),
                                  Text('水电表'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedMeterType = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingL),
                    
                    Text(
                      '选择楼层和房间',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // 从已有房间选择
                    if (_availableRooms.isNotEmpty) ...[
                      Text(
                        '从已有房间选择',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedFloor,
                              decoration: AppStyles.inputDecoration(
                                labelText: '楼层',
                                prefixIcon: Icons.layers,
                              ),
                              items: _getAvailableFloors().map((floor) {
                                return DropdownMenuItem(
                                  value: floor,
                                  child: Text(
                                    '${floor}楼',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedFloor = value;
                                  _selectedRoom = null;
                                });
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedRoom,
                              decoration: AppStyles.inputDecoration(
                                labelText: '房间号',
                                prefixIcon: Icons.door_front_door,
                              ),
                              items: _selectedFloor != null
                                  ? _getRoomsForFloor(_selectedFloor!).where((room) => room != '_PLACEHOLDER_').map((room) {
                                      return DropdownMenuItem(
                                        value: room,
                                        child: Text(
                                          room,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList()
                                  : [],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRoom = value;
                                });
                              },
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      const Divider(),
                      
                      const SizedBox(height: AppTheme.spacingL),
                    ],
                    
                    // 手动输入
                    Text(
                      '手动输入房间信息',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _floorController,
                            decoration: AppStyles.inputDecoration(
                              labelText: '楼层',
                              hintText: '如: 1',
                              prefixIcon: Icons.layers,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: TextField(
                            controller: _roomController,
                            decoration: AppStyles.inputDecoration(
                              labelText: '房间号',
                              hintText: '如: 101',
                              prefixIcon: Icons.door_front_door,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spacingXL),
                    
                    // 保存按钮或提示信息
                    SizedBox(
                      width: double.infinity,
                      child: _recognitionResult != null && _recognitionResult!.contains('无法识别')
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red.shade600,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '识别失败',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '请重新拍照或手动修正读数后再保存',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : AppStyles.primaryButton(
                              text: '保存记录',
                              icon: Icons.save,
                              onPressed: _saveRecord,
                              color: AppTheme.warning,
                              height: 56,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _floorController.dispose();
    _roomController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}