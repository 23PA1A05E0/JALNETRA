// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

Welcome welcomeFromJson(String str) => Welcome.fromJson(json.decode(str));

String welcomeToJson(Welcome data) => json.encode(data.toJson());

class Welcome {
    Map<String, double> averageDepth;
    Map<String, double> maxDepth;
    Map<String, double> minDepth;
    Map<String, Map<String, double>> yearlyChange;
    Map<String, Map<String, double>> monthlyTrend;
    Map<String, Map<String, double>> dailyTrend;
    Map<String, StationSummary> stationSummary;

    Welcome({
        required this.averageDepth,
        required this.maxDepth,
        required this.minDepth,
        required this.yearlyChange,
        required this.monthlyTrend,
        required this.dailyTrend,
        required this.stationSummary,
    });

    factory Welcome.fromJson(Map<String, dynamic> json) => Welcome(
        averageDepth: Map.from(json["average_depth"]).map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
        maxDepth: Map.from(json["max_depth"]).map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
        minDepth: Map.from(json["min_depth"]).map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
        yearlyChange: Map.from(json["yearly_change"]).map((k, v) => MapEntry<String, Map<String, double>>(k, Map.from(v).map((k, v) => MapEntry<String, double>(k, v?.toDouble())))),
        monthlyTrend: Map.from(json["monthly_trend"]).map((k, v) => MapEntry<String, Map<String, double>>(k, Map.from(v).map((k, v) => MapEntry<String, double>(k, v?.toDouble())))),
        dailyTrend: Map.from(json["daily_trend"]).map((k, v) => MapEntry<String, Map<String, double>>(k, Map.from(v).map((k, v) => MapEntry<String, double>(k, v?.toDouble())))),
        stationSummary: Map.from(json["station_summary"]).map((k, v) => MapEntry<String, StationSummary>(k, StationSummary.fromJson(v))),
    );

    Map<String, dynamic> toJson() => {
        "average_depth": Map.from(averageDepth).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "max_depth": Map.from(maxDepth).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "min_depth": Map.from(minDepth).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "yearly_change": Map.from(yearlyChange).map((k, v) => MapEntry<String, dynamic>(k, Map.from(v).map((k, v) => MapEntry<String, dynamic>(k, v)))),
        "monthly_trend": Map.from(monthlyTrend).map((k, v) => MapEntry<String, dynamic>(k, Map.from(v).map((k, v) => MapEntry<String, dynamic>(k, v)))),
        "daily_trend": Map.from(dailyTrend).map((k, v) => MapEntry<String, dynamic>(k, Map.from(v).map((k, v) => MapEntry<String, dynamic>(k, v)))),
        "station_summary": Map.from(stationSummary).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
    };
}

class StationSummary {
    double avgDepth;
    double maxDepth;
    double minDepth;
    Map<String, double> yearlyChange;

    StationSummary({
        required this.avgDepth,
        required this.maxDepth,
        required this.minDepth,
        required this.yearlyChange,
    });

    factory StationSummary.fromJson(Map<String, dynamic> json) => StationSummary(
        avgDepth: json["avg_depth"]?.toDouble(),
        maxDepth: json["max_depth"]?.toDouble(),
        minDepth: json["min_depth"]?.toDouble(),
        yearlyChange: Map.from(json["yearly_change"]).map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
    );

    Map<String, dynamic> toJson() => {
        "avg_depth": avgDepth,
        "max_depth": maxDepth,
        "min_depth": minDepth,
        "yearly_change": Map.from(yearlyChange).map((k, v) => MapEntry<String, dynamic>(k, v)),
    };
}
