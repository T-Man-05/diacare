/// Model for blood sugar chart data
class ChartData {
  final String title;
  final Map<String, List<int>> data;
  final List<String> hours;

  ChartData({
    required this.title,
    required this.data,
    required this.hours,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>? ?? {};
    return ChartData(
      title: json['title'] ?? '',
      data: {
        'before_meal': (dataMap['before_meal'] as List<dynamic>?)
                ?.map((e) => (e is int) ? e : (e as num).toInt())
                .toList() ??
            [],
        'after_meal': (dataMap['after_meal'] as List<dynamic>?)
                ?.map((e) => (e is int) ? e : (e as num).toInt())
                .toList() ??
            [],
      },
      hours:
          (json['hours'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'data': data,
      'hours': hours,
    };
  }
}
