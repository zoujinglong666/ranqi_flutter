import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/service_fee.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

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

  void _showAddEditBottomSheet({ServiceFee? serviceFee, required String feeType}) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge),
                topRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: AppTheme.textSecondary),
                    ),
                    Expanded(
                      child: Text(
                        isEdit ? '编辑$feeType' : '添加$feeType',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeTitle,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // 平衡关闭按钮
                  ],
                ),
              ),
              
              // 表单内容
              Expanded(
                child: SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 楼层输入
                      Text(
                        '楼层',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSubtitle,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      TextField(
                        controller: floorController,
                        decoration: InputDecoration(
                          hintText: '请输入楼层',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingL),
                      
                      // 房间号输入
                      Text(
                        '房间号',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSubtitle,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      TextField(
                        controller: roomController,
                        decoration: InputDecoration(
                          hintText: '请输入房间号',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingL),
                
                      // 费用金额输入
                      Text(
                        '费用金额',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSubtitle,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '请输入费用金额',
                          suffixText: '元',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingL),
                      
                      // 月份选择
                      Text(
                        '所属月份',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSubtitle,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      InkWell(
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
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingM,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${selectedMonth.year}年${selectedMonth.month}月',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeBody,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingL),
                      
                      // 备注输入
                      Text(
                        '备注',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSubtitle,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      TextField(
                        controller: remarksController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '请输入备注信息（可选）',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingXL * 2),
                    ],
                  ),
                ),
              ),
              
              // 底部操作按钮
              Container(
                padding: EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    if (isEdit) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('确认删除'),
                                content: Text('确定要删除这条${feeType}记录吗？'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text('删除', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              try {
                                await StorageService.deleteServiceFee(serviceFee!.id);
                                Navigator.of(context).pop();
                                _loadServiceFees();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('删除成功')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('删除失败: $e')),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                          ),
                          child: Text('删除'),
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingM),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (floorController.text.isEmpty ||
                              roomController.text.isEmpty ||
                              amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('请填写完整信息'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('请输入有效的费用金额'),
                                backgroundColor: Colors.red,
                              ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        child: Text(
                          isEdit ? '更新' : '添加',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: AppTheme.spacingM),
            Text(
              '暂无${feeType}记录',
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.spacingS),
            Text(
              '点击右下角按钮添加记录',
              style: TextStyle(
                fontSize: AppTheme.fontSizeCaption,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingM),
      itemCount: fees.length,
      itemBuilder: (context, index) {
        final fee = fees[index];
        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showAddEditBottomSheet(serviceFee: fee, feeType: feeType),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  // 左侧图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (feeType == '公共服务费' ? AppTheme.primaryBlue : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      feeType == '公共服务费' ? Icons.public : Icons.cleaning_services,
                      color: feeType == '公共服务费' ? AppTheme.primaryBlue : Colors.green,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingM),
                  
                  // 中间内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${fee.floor}-${fee.roomNumber}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSubtitle,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingXS),
                        Row(
                          children: [
                            Text(
                              '¥${fee.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeBody,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingS),
                            Text(
                              '${fee.month.year}年${fee.month.month}月',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeCaption,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (fee.remarks != null && fee.remarks!.isNotEmpty) ...[
                          SizedBox(height: AppTheme.spacingXS),
                          Text(
                            fee.remarks!,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeCaption,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // 右侧操作按钮
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppTheme.textSecondary),
                            SizedBox(width: AppTheme.spacingS),
                            Text(
                              '编辑',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeBody,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: AppTheme.spacingS),
                            Text(
                              '删除',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeBody,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditBottomSheet(serviceFee: fee, feeType: feeType);
                      } else if (value == 'delete') {
                        _deleteServiceFee(fee);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          '服务费管理',
          style: TextStyle(
            fontSize: AppTheme.fontSizeTitle,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: AppTheme.fontSizeBody,
            fontWeight: FontWeight.w600,
          ),
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
          _showAddEditBottomSheet(feeType: feeType);
        },
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        child: Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }
}