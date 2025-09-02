class ExportConfig {
  final String companyName;
  final String companyLogo;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String contactPhone;
  final String contactEmail;
  final String watermarkText;
  final bool showWatermark;
  final String reportFooter;
  final String qrCodeUrl;
  final bool showQrCode;

  /// 获取是否启用水印
  bool get enableWatermark => showWatermark;

  ExportConfig({
    required this.companyName,
    this.companyLogo = '',
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.contactPhone = '',
    this.contactEmail = '',
    this.watermarkText = '',
    this.showWatermark = true,
    this.reportFooter = '',
    this.qrCodeUrl = '',
    this.showQrCode = false,
    bool? enableWatermark,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyLogo': companyLogo,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'watermarkText': watermarkText,
      'showWatermark': showWatermark,
      'reportFooter': reportFooter,
      'qrCodeUrl': qrCodeUrl,
      'showQrCode': showQrCode,
    };
  }

  factory ExportConfig.fromJson(Map<String, dynamic> json) {
    return ExportConfig(
      companyName: json['companyName'] ?? '',
      companyLogo: json['companyLogo'] ?? '',
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      watermarkText: json['watermarkText'] ?? '',
      showWatermark: json['showWatermark'] ?? true,
      reportFooter: json['reportFooter'] ?? '',
      qrCodeUrl: json['qrCodeUrl'] ?? '',
      showQrCode: json['showQrCode'] ?? false,
    );
  }

  ExportConfig copyWith({
    String? companyName,
    String? companyLogo,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? contactPhone,
    String? contactEmail,
    String? watermarkText,
    bool? showWatermark,
    String? reportFooter,
    String? qrCodeUrl,
    bool? showQrCode,
  }) {
    return ExportConfig(
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      watermarkText: watermarkText ?? this.watermarkText,
      showWatermark: showWatermark ?? this.showWatermark,
      reportFooter: reportFooter ?? this.reportFooter,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      showQrCode: showQrCode ?? this.showQrCode,
    );
  }

  /// 获取默认配置
  static ExportConfig getDefault() {
    return ExportConfig(
      companyName: '阿Q公寓',
      bankName: '中国工商银行',
      accountNumber: '6222 0000 0000 0000',
      accountName: '请设置收款人姓名',
      watermarkText: '燃气管理系统',
      showWatermark: true,
      reportFooter: '如有疑问，请及时联系管理员',
    );
  }
}