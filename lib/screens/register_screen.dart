import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // 启动动画
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (!_agreeToTerms) {
      _showErrorDialog('请先同意用户协议和隐私政策');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // 模拟注册过程
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
    });
    
    // 注册成功，显示成功对话框
    _showSuccessDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '注册账户',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontSizeTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                children: [
                  SizedBox(height: AppTheme.spacingL),
                  
                  // Logo 和标题区域
                  _buildHeader(),
                  
                  SizedBox(height: AppTheme.spacingXL),
                  
                  // 注册表单
                  _buildRegisterForm(),
                  
                  SizedBox(height: AppTheme.spacingL),
                  
                  // 用户协议
                  _buildTermsAgreement(),
                  
                  SizedBox(height: AppTheme.spacingL),
                  
                  // 注册按钮
                  _buildRegisterButton(),
                  
                  SizedBox(height: AppTheme.spacingL),
                  
                  // 登录提示
                  _buildLoginPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo 容器
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Icon(
            Icons.person_add_rounded,
            size: 50,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: AppTheme.spacingM),
        
        // 标题
        const Text(
          '创建新账户',
          style: TextStyle(
            fontSize: AppTheme.fontSizeDisplay,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        
        SizedBox(height: AppTheme.spacingS),
        const Text(
          '请填写以下信息完成注册',
          style: TextStyle(
            fontSize: AppTheme.fontSizeBody,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户名输入框
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: '用户名',
                hintText: '请输入用户名',
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryBlue,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                if (value.length < 3) {
                  return '用户名长度不能少于3位';
                }
                if (value.length > 20) {
                  return '用户名长度不能超过20位';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.spacingM),
            
            // 邮箱输入框
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: '邮箱',
                hintText: '请输入邮箱地址',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入邮箱地址';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(value)) {
                  return '请输入有效的邮箱地址';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.spacingM),
            
            // 手机号输入框
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '手机号',
                hintText: '请输入手机号码',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入手机号码';
                }
                if (!RegExp(r'^1[3-9]\d{9}\$').hasMatch(value)) {
                  return '请输入有效的手机号码';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.spacingM),
            
            // 密码输入框
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: '密码',
                hintText: '请输入密码',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryBlue,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6) {
                  return '密码长度不能少于6位';
                }
                if (value.length > 20) {
                  return '密码长度不能超过20位';
                }
                if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                  return '密码必须包含字母和数字';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.spacingM),
            
            // 确认密码输入框
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: '确认密码',
                hintText: '请再次输入密码',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryBlue,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请确认密码';
                }
                if (value != _passwordController.text) {
                  return '两次输入的密码不一致';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAgreement() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          activeColor: AppTheme.primaryBlue,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreeToTerms = !_agreeToTerms;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeCaption,
                    color: AppTheme.textSecondary,
                  ),
                  children: [
                    TextSpan(text: '我已阅读并同意'),
                    TextSpan(
                      text: '《用户协议》',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: '和'),
                    TextSpan(
                      text: '《隐私政策》',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingM),
                  Text(
                    '注册中...',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                '注册',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '已有账户？',
          style: TextStyle(
            fontSize: AppTheme.fontSizeBody,
            color: AppTheme.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            '立即登录',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.error,
              ),
              SizedBox(width: AppTheme.spacingS),
              Text(
                '注册失败',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '确定',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppTheme.success,
              ),
              SizedBox(width: AppTheme.spacingS),
              Text(
                '注册成功',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            '恭喜您！账户注册成功，请返回登录页面进行登录。',
            style: TextStyle(
              fontSize: AppTheme.fontSizeBody,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
                Navigator.of(context).pop(); // 返回登录页面
              },
              child: Text(
                '去登录',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}