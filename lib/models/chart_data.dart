/// Model for blood sugar chart data
class ChartData {
  final String title;
  final Map<String, List<int>> data;
  final List<String> days;

  ChartData({
    required this.title,
    required this.data,
    required this.days,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>? ?? {};
    return ChartData(
      title: json['title'] ?? '',
      data: {
        'before_meal': (dataMap['before_meal'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
        'after_meal': (dataMap['after_meal'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
      },
      days:
          (json['days'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'data': data,
      'days': days,
    };
  }
}
