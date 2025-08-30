import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/meter_record.dart';
import '../models/room.dart';
import '../services/storage_service.dart';
import '../services/recognition_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  String? _base64Image;
  String? _recognitionResult;
  bool _isRecognizing = false;
  bool _isEditingResult = false;
  
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  
  List<Room> _availableRooms = [];
  int? _selectedFloor;
  String? _selectedRoom;

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
        _recognitionResult = result;
        _isEditingResult = false;
        _extractReadingToController(result);
      });
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

    final record = MeterRecord(
      id: Uuid().v4(),
      imagePath: _image!.path,
      base64Image: _base64Image!,
      recognitionResult: _recognitionResult!,
      floor: floor,
      roomNumber: roomNumber,
      timestamp: DateTime.now(),
    );

    try {
      await StorageService.saveMeterRecord(record);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('记录保存成功')),
      );
      
      setState(() {
        _image = null;
        _base64Image = null;
        _recognitionResult = null;
        _isEditingResult = false;
        _selectedFloor = null;
        _selectedRoom = null;
        _floorController.clear();
        _roomController.clear();
        _resultController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.05),
            AppTheme.primaryTeal.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
            child: const Text(
              '🔥 燃气表识别',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTheme.fontSizeTitle,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 拍照区域
              Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      gradient: _image == null 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryBlue.withOpacity(0.08),
                              AppTheme.primaryTeal.withOpacity(0.08),
                            ],
                          )
                        : null,
                    ),
                    child: _image != null
                        ? Stack(
                            children: [
                              Image.file(
                                _image!, 
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Positioned(
                                top: AppTheme.spacingM,
                                right: AppTheme.spacingM,
                                child: Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingS),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
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
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryBlue.withOpacity(0.4),
                                        offset: const Offset(0, 8),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingL),
                                Text(
                                  '📸 拍摄燃气表读数',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingL,
                                    vertical: AppTheme.spacingS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  ),
                                  child: Text(
                                    '💡 请确保表盘清晰可见，光线充足',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              
              // 拍照按钮
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _takePicture,
                        icon: const Icon(Icons.camera_alt_rounded, size: 24),
                        label: const Text(
                          '拍照识别',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.successGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_rounded, size: 24),
                        label: const Text(
                          '选择图片',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // 识别结果
              if (_isRecognizing)
                Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        offset: const Offset(0, 4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            ),
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      Text(
                        '🤖 AI智能识别中...',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                          vertical: AppTheme.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        ),
                        child: Text(
                          '⚡ 正在分析表盘数据，请稍候...',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_recognitionResult != null)
                Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.1),
                        offset: const Offset(0, 4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacingM),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.successGradient,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.success.withOpacity(0.3),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Text(
                                '✨ 识别结果',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (!_isEditingResult)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.warning.withOpacity(0.1),
                                    AppTheme.warning.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                border: Border.all(
                                  color: AppTheme.warning.withOpacity(0.3),
                                ),
                              ),
                              child: TextButton.icon(
                                onPressed: _startEditResult,
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text(
                                  '修改',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.warning,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingL,
                                    vertical: AppTheme.spacingM,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      if (_isEditingResult) ...[
                        // 编辑模式
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.warning.withOpacity(0.08),
                                AppTheme.warning.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            border: Border.all(
                              color: AppTheme.warning.withOpacity(0.3),
                            ),
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingS),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warning,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Text(
                                    '🔧 手动修正读数',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              TextField(
                                controller: _resultController,
                                decoration: AppStyles.inputDecoration(
                                  labelText: '表计读数',
                                  hintText: '请输入正确的读数',
                                  prefixIcon: Icons.straighten_rounded,
                                ).copyWith(
                                  suffixText: '(仅数字)',
                                  suffixStyle: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: AppTheme.fontSizeCaption,
                                  ),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                autofocus: true,
                                onSubmitted: (_) => _saveEditedResult(),
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.successGradient,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.success.withOpacity(0.3),
                                            offset: const Offset(0, 2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _saveEditedResult,
                                        icon: const Icon(Icons.check_rounded, size: 20),
                                        label: const Text(
                                          '保存',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.textHint.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                        border: Border.all(
                                          color: AppTheme.textHint.withOpacity(0.3),
                                        ),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _cancelEditResult,
                                        icon: const Icon(Icons.close_rounded, size: 20),
                                        label: const Text(
                                          '取消',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: AppTheme.textHint,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                          ),
                                        ),
                                      ),
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
                          padding: const EdgeInsets.all(AppTheme.spacingXL),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.success.withOpacity(0.1),
                                AppTheme.primaryTeal.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            border: Border.all(
                              color: AppTheme.success.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingS),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    child: const Icon(
                                      Icons.analytics_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Expanded(
                                    child: Text(
                                      _recognitionResult!,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_recognitionResult!.contains('(手动修正)')) ...[
                                const SizedBox(height: AppTheme.spacingM),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingM,
                                    vertical: AppTheme.spacingS,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                    border: Border.all(
                                      color: AppTheme.warning.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                        color: AppTheme.warning,
                                      ),
                                      const SizedBox(width: AppTheme.spacingS),
                                      Text(
                                        '已手动修正',
                                        style: TextStyle(
                                          color: AppTheme.warning,
                                          fontSize: AppTheme.fontSizeCaption,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
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
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingS),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Text(
                            '📍 选择楼层和房间',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // 从已有房间选择
                      if (_availableRooms.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🏠 从已有房间选择',
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
                                          child: Text('${floor}楼'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedFloor = value;
                                          _selectedRoom = null;
                                        });
                                      },
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
                                          ? _getRoomsForFloor(_selectedFloor!).map((room) {
                                              return DropdownMenuItem(
                                                value: room,
                                                child: Text(room),
                                              );
                                            }).toList()
                                          : [],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedRoom = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppTheme.spacingL),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppTheme.textHint.withOpacity(0.3),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                              child: Text(
                                '或',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppTheme.textHint.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppTheme.spacingL),
                      ],
                      
                      // 手动输入
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: AppTheme.success.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✏️ 手动输入房间信息',
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
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // 保存按钮
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.warning,
                              AppTheme.warning.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.warning.withOpacity(0.4),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _saveRecord,
                          icon: const Icon(Icons.save_rounded, size: 24),
                          label: const Text(
                            '💾 保存记录',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeBody,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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