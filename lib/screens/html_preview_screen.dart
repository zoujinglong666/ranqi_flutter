import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

class HtmlPreviewScreen extends StatefulWidget {
  final String htmlContent;
  final String title;

  const HtmlPreviewScreen({
    Key? key,
    required this.htmlContent,
    required this.title,
  }) : super(key: key);

  @override
  State<HtmlPreviewScreen> createState() => _HtmlPreviewScreenState();
}

class _HtmlPreviewScreenState extends State<HtmlPreviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
            tooltip: '刷新',
          ),
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () {
              _controller.runJavaScript('document.body.style.zoom = "1.2"');
            },
            tooltip: '放大',
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () {
              _controller.runJavaScript('document.body.style.zoom = "0.8"');
            },
            tooltip: '缩小',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在加载预览...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSizeBody,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, true); // 返回true表示用户确认要导出
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: Icon(Icons.file_download, color: Colors.white),
        label: Text(
          '确认导出',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}