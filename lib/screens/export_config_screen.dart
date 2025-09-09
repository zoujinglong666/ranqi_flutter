import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/export_config.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ExportConfigScreen extends StatefulWidget {
  const ExportConfigScreen({super.key});

  @override
  _ExportConfigScreenState createState() => _ExportConfigScreenState();
}

class _ExportConfigScreenState extends State<ExportConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _companyNameController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _contactEmailController;
  late TextEditingController _watermarkTextController;
  late TextEditingController _reportFooterController;
  
  bool _isLoading = false;
  bool _enableWatermark = true;
  bool _showPaymentQrCodes = false;
  
  String _alipayQrCodePath = '';
  String _wechatQrCodePath = '';
  
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadConfig();
  }

  void _initControllers() {
    _companyNameController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _accountNameController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _contactEmailController = TextEditingController();
    _watermarkTextController = TextEditingController();
    _reportFooterController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _watermarkTextController.dispose();
    _reportFooterController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    
    try {
      final config = await StorageService.getExportConfig();
      
      _companyNameController.text = config.companyName;
      _bankNameController.text = config.bankName;
      _accountNumberController.text = config.accountNumber;
      _accountNameController.text = config.accountName;
      _contactPhoneController.text = config.contactPhone;
      _contactEmailController.text = config.contactEmail;
      _watermarkTextController.text = config.watermarkText;
      _reportFooterController.text = config.reportFooter;
      _enableWatermark = config.enableWatermark;
      _showPaymentQrCodes = config.showPaymentQrCodes;
      _alipayQrCodePath = config.alipayQrCodePath;
      _wechatQrCodePath = config.wechatQrCodePath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载配置失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final config = ExportConfig(
        companyName: _companyNameController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountName: _accountNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        watermarkText: _watermarkTextController.text.trim(),
        reportFooter: _reportFooterController.text.trim(),
        showWatermark: _enableWatermark,
        showPaymentQrCodes: _showPaymentQrCodes,
        alipayQrCodePath: _alipayQrCodePath,
        wechatQrCodePath: _wechatQrCodePath,
      );
      
      await StorageService.saveExportConfig(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置保存成功')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存配置失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出配置'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveConfig,
            child: const Text(
              '保存',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('公司信息'),
                  _buildTextField(
                    controller: _companyNameController,
                    label: '公司名称',
                    icon: Icons.business,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return '请输入公司名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle('银行信息'),
                  _buildTextField(
                    controller: _bankNameController,
                    label: '银行名称',
                    icon: Icons.account_balance,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return '请输入银行名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _accountNumberController,
                    label: '银行账号',
                    icon: Icons.credit_card,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return '请输入银行账号';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _accountNameController,
                    label: '账户名称',
                    icon: Icons.person,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return '请输入账户名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle('联系信息'),
                  _buildTextField(
                    controller: _contactPhoneController,
                    label: '联系电话',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _contactEmailController,
                    label: '联系邮箱',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle('报表设置'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('启用水印'),
                            subtitle: const Text('在报表中显示水印'),
                            value: _enableWatermark,
                            onChanged: (value) {
                              setState(() => _enableWatermark = value);
                            },
                          ),
                          if (_enableWatermark) ...[
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _watermarkTextController,
                              label: '水印文字',
                              icon: Icons.e_mobiledata,
                              hintText: '例如：机密文件',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _reportFooterController,
                    label: '报表页脚',
                    icon: Icons.note,
                    hintText: '例如：感谢您的配合',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle('收款码设置'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('显示收款码'),
                            subtitle: const Text('在报表中显示支付宝和微信收款码'),
                            value: _showPaymentQrCodes,
                            onChanged: (value) {
                              setState(() => _showPaymentQrCodes = value);
                            },
                          ),
                          if (_showPaymentQrCodes) ...[ 
                            const SizedBox(height: 16),
                            _buildQrCodeUploadSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  /// 构建收款码上传区域
  Widget _buildQrCodeUploadSection() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // 使用SingleChildScrollView支持横向滚动，适配小屏幕
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 8),
              _buildQrCodeUploadCard(
                title: '支付宝收款码',
                imagePath: _alipayQrCodePath,
                onTap: () => _pickQrCodeImage('alipay'),
                color: const Color(0xFF1677FF), // 支付宝蓝色
                icon: Icons.account_balance_wallet,
              ),
              const SizedBox(width: 16),
              _buildQrCodeUploadCard(
                title: '微信收款码',
                imagePath: _wechatQrCodePath,
                onTap: () => _pickQrCodeImage('wechat'),
                color: const Color(0xFF07C160), // 微信绿色
                icon: Icons.chat,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 添加提示文字
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '上传清晰的收款码图片，建议尺寸400x400像素，确保扫码正常使用',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建单个收款码上传卡片
  Widget _buildQrCodeUploadCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
  }) {
    final bool hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
    
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // 图片预览区域 - 正方形大尺寸
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasImage ? color.withOpacity(0.5) : color.withOpacity(0.3),
                    width: hasImage ? 3 : 2,
                  ),
                  boxShadow: hasImage ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: 160,
                          height: 160,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildUploadPlaceholder(color, icon);
                          },
                        ),
                      )
                    : _buildUploadPlaceholder(color, icon),
              ),
              
              const SizedBox(height: 12),
              
              // 操作按钮
              if (hasImage)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: onTap,
                      icon: Icon(Icons.refresh, size: 16, color: color),
                      label: Text(
                        '重新上传',
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: color.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _removeQrCodeImage(title.contains('支付宝') ? 'alipay' : 'wechat'),
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text(
                        '删除',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.red.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    '点击上传收款码',
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建上传占位符
  Widget _buildUploadPlaceholder(Color color, IconData icon) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '上传收款码',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '建议尺寸 400x400',
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 选择收款码图片
  Future<void> _pickQrCodeImage(String type) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        // 获取应用文档目录
        final directory = await getApplicationDocumentsDirectory();
        final qrCodeDir = Directory('${directory.path}/qr_codes');
        
        // 创建目录（如果不存在）
        if (!await qrCodeDir.exists()) {
          await qrCodeDir.create(recursive: true);
        }

        // 生成新的文件名
        final fileName = '${type}_qr_code_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final newPath = '${qrCodeDir.path}/$fileName';

        // 复制文件到应用目录
        await File(image.path).copy(newPath);

        // 删除旧文件（如果存在）
        final oldPath = type == 'alipay' ? _alipayQrCodePath : _wechatQrCodePath;
        if (oldPath.isNotEmpty && File(oldPath).existsSync()) {
          try {
            await File(oldPath).delete();
          } catch (e) {
            print('删除旧文件失败: $e');
          }
        }

        // 更新状态
        setState(() {
          if (type == 'alipay') {
            _alipayQrCodePath = newPath;
          } else {
            _wechatQrCodePath = newPath;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${type == 'alipay' ? '支付宝' : '微信'}收款码上传成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }

  /// 删除收款码图片
  Future<void> _removeQrCodeImage(String type) async {
    try {
      final path = type == 'alipay' ? _alipayQrCodePath : _wechatQrCodePath;
      
      if (path.isNotEmpty && File(path).existsSync()) {
        await File(path).delete();
      }

      setState(() {
        if (type == 'alipay') {
          _alipayQrCodePath = '';
        } else {
          _wechatQrCodePath = '';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type == 'alipay' ? '支付宝' : '微信'}收款码已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }
}