import 'package:flutter/material.dart';
import '../models/service_fee.dart';
import '../services/storage_service.dart';

class ServiceFeeManagementScreen extends StatefulWidget {
  const ServiceFeeManagementScreen({Key? key}) : super(key: key);

  @override
  _ServiceFeeManagementScreenState createState() => _ServiceFeeManagementScreenState();
}

class _ServiceFeeManagementScreenState extends State<ServiceFeeManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ServiceFee> _publicServiceFees = [];
  List<ServiceFee> _sanitationFees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadServiceFees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceFees() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final publicFees = await StorageService.getServiceFeesByType('公共服务费');
      final sanitationFees = await StorageService.getServiceFeesByType('卫生费');
      
      setState(() {
        _publicServiceFees = publicFees;
        _sanitationFees = sanitationFees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载服务费数据失败: $e')),
      );
    }
  }

  void _showAddEditDialog({ServiceFee? serviceFee, required String feeType}) {
    final isEdit = serviceFee != null;
    final floorController = TextEditingController(
      text: serviceFee?.floor ?? '',
    );
    final roomController = TextEditingController(
      text: serviceFee?.roomNumber ?? '',
    );
    final amountController = TextEditingController(
      text: serviceFee?.amount.toString() ?? '',
    );
    final remarksController = TextEditingController(
      text: serviceFee?.remarks ?? '',
    );
    DateTime selectedMonth = serviceFee?.month ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(isEdit ? '编辑$feeType' : '添加$feeType'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 楼层输入
                TextFormField(
                  controller: floorController,
                  decoration: const InputDecoration(
                    labelText: '楼层',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 房间号输入
                TextFormField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: '房间号',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 费用金额输入
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: '费用金额 (元)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                
                // 月份选择
                ListTile(
                  title: const Text('所属月份'),
                  subtitle: Text('${selectedMonth.year}年${selectedMonth.month}月'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (date != null) {
                      setModalState(() {
                        selectedMonth = DateTime(date.year, date.month);
                      });
                    }
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
                if (floorController.text.isEmpty ||
                    roomController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写完整信息')),
                  );
                  return;
                }
                
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入有效的费用金额')),
                  );
                  return;
                }
                
                try {
                  final newServiceFee = ServiceFee(
                    id: serviceFee?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    floor: floorController.text,
                    roomNumber: roomController.text,
                    feeType: feeType,
                    amount: amount,
                    month: selectedMonth,
                    remarks: remarksController.text.isEmpty ? null : remarksController.text,
                    createdAt: serviceFee?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  if (isEdit) {
                    await StorageService.updateServiceFee(newServiceFee);
                  } else {
                    await StorageService.saveServiceFee(newServiceFee);
                  }
                  
                  Navigator.of(context).pop();
                  _loadServiceFees();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? '$feeType更新成功' : '$feeType添加成功')),
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

  void _deleteServiceFee(ServiceFee serviceFee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除${serviceFee.floor}-${serviceFee.roomNumber}的${serviceFee.feeType}记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await StorageService.deleteServiceFee(serviceFee.id);
                Navigator.of(context).pop();
                _loadServiceFees();
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

  Widget _buildServiceFeeList(List<ServiceFee> fees, String feeType) {
    if (fees.isEmpty) {
      return Center(
        child: Text(
          '暂无${feeType}记录\n点击右下角按钮添加',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fees.length,
      itemBuilder: (context, index) {
        final fee = fees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: feeType == '公共服务费' ? Colors.blue : Colors.green,
              child: Icon(
                feeType == '公共服务费' ? Icons.public : Icons.cleaning_services,
                color: Colors.white,
              ),
            ),
            title: Text(
              '${fee.floor}-${fee.roomNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('金额: ¥${fee.amount.toStringAsFixed(2)}'),
                Text('月份: ${fee.month.year}年${fee.month.month}月'),
                if (fee.remarks != null && fee.remarks!.isNotEmpty)
                  Text('备注: ${fee.remarks}'),
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
                  _showAddEditDialog(serviceFee: fee, feeType: feeType);
                } else if (value == 'delete') {
                  _deleteServiceFee(fee);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务费管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '公共服务费'),
            Tab(text: '卫生费'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildServiceFeeList(_publicServiceFees, '公共服务费'),
                _buildServiceFeeList(_sanitationFees, '卫生费'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentIndex = _tabController.index;
          final feeType = currentIndex == 0 ? '公共服务费' : '卫生费';
          _showAddEditDialog(feeType: feeType);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}