import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;
  final String title;
  final Function()? onExport;

  const ImagePreviewScreen({
    Key? key,
    required this.imagePath,
    required this.title,
    this.onExport,
  }) : super(key: key);

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  bool _isLoading = false;

  Future<void> _exportImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.onExport != null) {
        widget.onExport!();
      }
      
      // 返回true表示用户选择了导出
      Navigator.of(context).pop(true);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openFileLocation() {
    final directory = File(widget.imagePath).parent.path;
    Process.run('explorer', [directory]);
  }

  void _shareImage() {
    ExportService.shareFile(widget.imagePath, '月度报告图片');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // 分享按钮
          IconButton(
            onPressed: _shareImage,
            icon: const Icon(Icons.share),
            tooltip: '分享',
          ),
          // 导出按钮
          _isLoading
              ? Container(
                  padding: const EdgeInsets.all(14),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _exportImages,
                  icon: const Icon(Icons.download),
                  tooltip: '导出',
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black, // 黑色背景，更好的图片展示效果
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '图片加载失败',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}