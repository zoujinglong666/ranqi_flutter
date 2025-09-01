import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/unit_price.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class UnitPriceManagementScreen extends StatefulWidget {
  const UnitPriceManagementScreen({Key? key}) : super(key: key);

  @override
  _UnitPriceManagementScreenState createState() => _UnitPriceManagementScreenState();
}

class _UnitPriceManagementScreenState extends State<UnitPriceManagementScreen> {
  List<UnitPrice> _unitPrices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnitPrices();
  }

  Future<void> _loadUnitPrices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final unitPrices = await StorageService.getUnitPrices();
      setState(() {
        _unitPrices = unitPrices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载单价数据失败: $e')),
      );
    }
  }

  void _showAddEditBottomSheet({UnitPrice? unitPrice}) {
    final isEdit = unitPrice != null;
    String selectedMeterType = unitPrice?.meterType ?? '水表';
    final priceController = TextEditingController(
      text: unitPrice?.unitPrice.toString() ?? '',
    );
    final remarksController = TextEditingController(
      text: unitPrice?.remarks ?? '',
    );
    DateTime selectedDate = unitPrice?.effectiveDate ?? DateTime.now();
    bool isEnabled = unitPrice?.isEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusXLarge),
                  topRight: Radius.circular(AppTheme.radiusXLarge),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题栏
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.attach_money,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${isEdit ? '编辑' : '添加'}单价配置',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeHeading,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // 表计类型选择
                  Text(
                    '表计类型',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedMeterType,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                          vertical: AppTheme.spacingM,
                        ),
                        prefixIcon: Icon(
                          selectedMeterType == '水表'
                              ? Icons.water_drop
                              : selectedMeterType == '电表'
                                  ? Icons.electrical_services
                                  : Icons.local_gas_station,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      items: ['水表', '电表', '燃气表'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() {
                            selectedMeterType = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // 单价输入
                  Text(
                    '单价金额',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '请输入单价金额',
                      prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryBlue),
                      suffixText: '元',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // 生效日期选择
                  Text(
                    '生效日期',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setModalState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                        vertical: AppTheme.spacingM,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('yyyy年MM月dd日').format(selectedDate),
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeBody,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // 启用状态
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.toggle_on, color: AppTheme.primaryBlue),
                        const SizedBox(width: 12),
                        const Text(
                          '启用状态',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: isEnabled,
                          onChanged: (value) {
                            setModalState(() {
                              isEnabled = value;
                            });
                          },
                          activeColor: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  
                  // 备注输入
                  Text(
                    '备注信息',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSubtitle,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  TextField(
                    controller: remarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '请输入备注信息（可选）',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  
                  // 操作按钮
                  Row(
                    children: [
                      if (isEdit)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await StorageService.deleteUnitPrice(unitPrice!.id);
                              Navigator.of(context).pop();
                              _loadUnitPrices();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('单价配置已删除')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                            ),
                            child: const Text('删除'),
                          ),
                        ),
                      if (isEdit) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (priceController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请输入单价金额')),
                              );
                              return;
                            }
                            
                            final price = double.tryParse(priceController.text);
                            if (price == null || price <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('请输入有效的单价金额')),
                              );
                              return;
                            }
                            
                            try {
                              final newUnitPrice = UnitPrice(
                                id: unitPrice?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                meterType: selectedMeterType,
                                price: price,
                                effectiveDate: selectedDate,
                                isActive: isEnabled,
                                notes: remarksController.text.trim().isEmpty ? null : remarksController.text.trim(),
                                createdAt: unitPrice?.createdAt ?? DateTime.now(),
                                updatedAt: DateTime.now(),
                              );
                              
                              if (isEdit) {
                                await StorageService.updateUnitPrice(newUnitPrice);
                              } else {
                                await StorageService.saveUnitPrice(newUnitPrice);
                              }
                              
                              Navigator.of(context).pop();
                              _loadUnitPrices();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('单价配置已${isEdit ? '更新' : '保存'}')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('操作失败: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: Text(isEdit ? '更新' : '保存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteUnitPrice(UnitPrice unitPrice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除${unitPrice.meterType}的单价配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await StorageService.deleteUnitPrice(unitPrice.id);
                Navigator.of(context).pop();
                _loadUnitPrices();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('删除成功')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          '单价管理',
          style: TextStyle(
            fontSize: AppTheme.fontSizeHeading,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            )
          : _unitPrices.isEmpty
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
                          Icons.attach_money,
                          size: 48,
                          color: AppTheme.primaryBlue.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      const Text(
                        '暂无单价配置',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeHeading,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Text(
                        '点击右下角按钮添加单价配置',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeBody,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  itemCount: _unitPrices.length,
                  itemBuilder: (context, index) {
                    final unitPrice = _unitPrices[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          onTap: () => _showAddEditBottomSheet(unitPrice: unitPrice),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: Row(
                              children: [
                                // 图标和状态
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: unitPrice.isActive
                                         ? AppTheme.primaryBlue.withOpacity(0.1)
                                         : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                  child: Icon(
                                    unitPrice.meterType == '水表'
                                        ? Icons.water_drop
                                        : unitPrice.meterType == '电表'
                                            ? Icons.electrical_services
                                            : Icons.local_gas_station,
                                    color: unitPrice.isActive
                                         ? AppTheme.primaryBlue
                                         : Colors.grey,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingL),
                                
                                // 主要信息
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            unitPrice.meterType,
                                            style: const TextStyle(
                                              fontSize: AppTheme.fontSizeSubtitle,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: AppTheme.spacingS),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: unitPrice.isActive
                                                   ? AppTheme.success.withOpacity(0.1)
                                                   : Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              unitPrice.isActive ? '启用' : '停用',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: unitPrice.isActive
                                                     ? AppTheme.success
                                                     : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${unitPrice.unitPrice.toStringAsFixed(2)} 元',
                                        style: const TextStyle(
                                          fontSize: AppTheme.fontSizeHeading,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '生效日期: ${DateFormat('yyyy年MM月dd日').format(unitPrice.effectiveDate)}',
                                        style: TextStyle(
                                          fontSize: AppTheme.fontSizeCaption,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      if (unitPrice.notes?.isNotEmpty == true) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '备注: ${unitPrice.notes}',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeCaption,
                                            color: AppTheme.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // 操作按钮
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: AppTheme.textSecondary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddEditBottomSheet(unitPrice: unitPrice);
                                    } else if (value == 'delete') {
                                      _deleteUnitPrice(unitPrice);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18, color: AppTheme.primaryBlue),
                                          const SizedBox(width: 8),
                                          const Text('编辑'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: AppTheme.error),
                                          const SizedBox(width: 8),
                                          const Text('删除'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBottomSheet(),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}