class AppSettings {
  const AppSettings({
    this.onboardingCompleted = false,
    this.llmEnabled = false,
    this.llmBaseUrl = '',
    this.llmApiKey = '',
    this.llmModel = '',
  });

  final bool onboardingCompleted;
  final bool llmEnabled;
  final String llmBaseUrl;
  final String llmApiKey;
  final String llmModel;

  bool get hasLlmConfig =>
      llmEnabled &&
      llmBaseUrl.trim().isNotEmpty &&
      llmApiKey.trim().isNotEmpty &&
      llmModel.trim().isNotEmpty;

  AppSettings copyWith({
    bool? onboardingCompleted,
    bool? llmEnabled,
    String? llmBaseUrl,
    String? llmApiKey,
    String? llmModel,
  }) {
    return AppSettings(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      llmEnabled: llmEnabled ?? this.llmEnabled,
      llmBaseUrl: llmBaseUrl ?? this.llmBaseUrl,
      llmApiKey: llmApiKey ?? this.llmApiKey,
      llmModel: llmModel ?? this.llmModel,
    );
  }

  Map<String, Object?> toJson() => {
    'onboardingCompleted': onboardingCompleted,
    'llmEnabled': llmEnabled,
    'llmBaseUrl': llmBaseUrl,
    'llmApiKey': llmApiKey,
    'llmModel': llmModel,
  };

  static AppSettings fromJson(Map<String, Object?> json) {
    return AppSettings(
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      llmEnabled: json['llmEnabled'] as bool? ?? false,
      llmBaseUrl: json['llmBaseUrl'] as String? ?? '',
      llmApiKey: json['llmApiKey'] as String? ?? '',
      llmModel: json['llmModel'] as String? ?? '',
    );
  }
}
