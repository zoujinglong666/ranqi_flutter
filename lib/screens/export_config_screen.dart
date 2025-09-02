import 'package:flutter/material.dart';
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
        enableWatermark: _enableWatermark,
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
}