import 'package:flutter/material.dart';
import '../models/unit_price.dart';
import '../services/storage_service.dart';

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

  void _showAddEditDialog({UnitPrice? unitPrice}) {
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(isEdit ? '编辑单价' : '添加单价'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 表计类型选择
                DropdownButtonFormField<String>(
                  value: selectedMeterType,
                  decoration: const InputDecoration(
                    labelText: '表计类型',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                
                // 单价输入
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: '单价 (元)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                
                // 生效日期选择
                ListTile(
                  title: const Text('生效日期'),
                  subtitle: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.calendar_today),
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
                ),
                const SizedBox(height: 16),
                
                // 是否启用
                SwitchListTile(
                  title: const Text('启用'),
                  value: isEnabled,
                  onChanged: (value) {
                    setModalState(() {
                      isEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // 备注
                TextFormField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入单价')),
                  );
                  return;
                }
                
                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入有效的单价')),
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
                    notes: remarksController.text,
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
                    SnackBar(content: Text(isEdit ? '单价更新成功' : '单价添加成功')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失败: $e')),
                  );
                }
              },
              child: Text(isEdit ? '更新' : '添加'),
            ),
          ],
        ),
      ),
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
      appBar: AppBar(
        title: const Text('单价管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unitPrices.isEmpty
              ? const Center(
                  child: Text(
                    '暂无单价配置\n点击右下角按钮添加',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _unitPrices.length,
                  itemBuilder: (context, index) {
                    final unitPrice = _unitPrices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: unitPrice.isEnabled ? Colors.green : Colors.grey,
                          child: Icon(
                            unitPrice.meterType == '水表'
                                ? Icons.water_drop
                                : unitPrice.meterType == '电表'
                                    ? Icons.electrical_services
                                    : Icons.local_gas_station,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${unitPrice.meterType} - ${unitPrice.unitPrice}元',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('生效日期: ${unitPrice.effectiveDate.year}-${unitPrice.effectiveDate.month.toString().padLeft(2, '0')}-${unitPrice.effectiveDate.day.toString().padLeft(2, '0')}'),
                            Text('状态: ${unitPrice.isEnabled ? '启用' : '禁用'}'),
                            if (unitPrice.remarks.isNotEmpty)
                              Text('备注: ${unitPrice.remarks}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('编辑'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('删除', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditDialog(unitPrice: unitPrice);
                            } else if (value == 'delete') {
                              _deleteUnitPrice(unitPrice);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}