import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // 模拟登录过程
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
    });
    
    // 登录成功，跳转到主界面
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                          vertical: isKeyboardVisible ? AppTheme.spacingM : AppTheme.spacingL,
                        ),
                        child: Column(
                          children: [
                            // 动态顶部间距
                            SizedBox(height: isKeyboardVisible ? AppTheme.spacingM : AppTheme.spacingXXL),
                            
                            // Logo 和标题区域 - 键盘弹出时缩小
                            _buildHeader(isCompact: isKeyboardVisible),
                            
                            // 动态间距
                            SizedBox(height: isKeyboardVisible ? AppTheme.spacingL : AppTheme.spacingXL),
                            
                            // 登录表单
                            _buildLoginForm(),
                            
                            // 动态间距
                            SizedBox(height: isKeyboardVisible ? AppTheme.spacingL : AppTheme.spacingXL),
                            
                            // 登录按钮 - 始终保持在合适位置
                            _buildLoginButton(),
                            
                            // 底部弹性空间
                            if (!isKeyboardVisible) Spacer(),
                            
                            // 底部安全间距
                            SizedBox(height: AppTheme.spacingM),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({bool isCompact = false}) {
    return Column(
      children: [
        // Logo 容器 - 键盘弹出时缩小
        Container(
          width: isCompact ? 80 : 120,
          height: isCompact ? 80 : 120,
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
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            Icons.local_gas_station_rounded,
            size: isCompact ? 40 : 60,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: isCompact ? AppTheme.spacingM : AppTheme.spacingL),
        
        // 应用标题 - 键盘弹出时调整字体大小
        Text(
          '智能抄表',
          style: TextStyle(
            fontSize: isCompact ? AppTheme.fontSizeDisplay : AppTheme.fontSizeDisplay + 4,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        
        if (!isCompact) ...[
           SizedBox(height: AppTheme.spacingS),
           Text(
             '智能识别，高效管理',
             style: TextStyle(
               fontSize: AppTheme.fontSizeBody,
               color: AppTheme.textSecondary,
               letterSpacing: 0.5,
             ),
           ),
         ]
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingL + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '登录账户',
              style: TextStyle(
                fontSize: AppTheme.fontSizeHeading,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            
            SizedBox(height: AppTheme.spacingL + 4),
            
            // 用户名输入框
            _buildInputField(
              controller: _usernameController,
              labelText: '用户名',
              hintText: '请输入用户名',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.spacingL),
            
            // 密码输入框
            _buildInputField(
              controller: _passwordController,
              labelText: '密码',
              hintText: '请输入密码',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (value.length < 6) {
                  return '密码长度不能少于6位';
                }
                return null;
              },
            ),
            
            SizedBox(height: AppTheme.spacingL),
            
            // 记住密码和注册选项
            Row(
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '记住密码',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeBody,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                    child: Text(
                      '注册账号',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeBody,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        style: TextStyle(
          fontSize: AppTheme.fontSizeBody,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: AppTheme.textHint,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.only(right: 12),
            child: Icon(
              prefixIcon,
              color: AppTheme.primaryBlue,
              size: 22,
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textSecondary,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
              color: AppTheme.primaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
              color: AppTheme.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(
              color: AppTheme.error,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey.shade400 : AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: EdgeInsets.symmetric(vertical: 18),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingM),
                  Text(
                    '登录中...',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeBody + 1,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            : Text(
                '登录',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeBody + 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  // Widget _buildFooterOptions() {
  //   return Column(
  //     children: [
  //       // 分割线
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Divider(
  //               color: Colors.grey.shade300,
  //               thickness: 1,
  //             ),
  //           ),
  //           Padding(
  //             padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
  //             child: Text(
  //               '其他方式',
  //               style: TextStyle(
  //                 fontSize: AppTheme.fontSizeCaption,
  //                 color: AppTheme.textHint,
  //               ),
  //             ),
  //           ),
  //           Expanded(
  //             child: Divider(
  //               color: Colors.grey.shade300,
  //               thickness: 1,
  //             ),
  //           ),
  //         ],
  //       ),
  //
  //       SizedBox(height: AppTheme.spacingL),
  //
  //       // 快速登录选项
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         children: [
  //           _buildQuickLoginButton(
  //             icon: Icons.fingerprint,
  //             label: '指纹登录',
  //             onTap: () {
  //               _showComingSoonDialog('指纹登录');
  //             },
  //           ),
  //           _buildQuickLoginButton(
  //             icon: Icons.face,
  //             label: '面容登录',
  //             onTap: () {
  //               _showComingSoonDialog('面容登录');
  //             },
  //           ),
  //           _buildQuickLoginButton(
  //             icon: Icons.qr_code_scanner,
  //             label: '扫码登录',
  //             onTap: () {
  //               _showComingSoonDialog('扫码登录');
  //             },
  //           ),
  //         ],
  //       ),
  //
  //       SizedBox(height: AppTheme.spacingXL),
  //
  //       // 注册提示
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text(
  //             '还没有账户？',
  //             style: TextStyle(
  //               fontSize: AppTheme.fontSizeBody,
  //               color: AppTheme.textSecondary,
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pushNamed(context, '/register');
  //             },
  //             child: Text(
  //               '立即注册',
  //               style: TextStyle(
  //                 fontSize: AppTheme.fontSizeBody,
  //                 color: AppTheme.primaryBlue,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildQuickLoginButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            SizedBox(height: AppTheme.spacingS),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeCaption,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          title: Text(
            '忘记密码',
            style: TextStyle(
              fontSize: AppTheme.fontSizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '请联系管理员重置密码，或通过注册邮箱找回密码。',
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

  void _showComingSoonDialog(String feature) {
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
                Icons.info_outline,
                color: AppTheme.info,
              ),
              SizedBox(width: AppTheme.spacingS),
              Text(
                '功能提示',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            '$feature功能即将上线，敬请期待！',
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
}