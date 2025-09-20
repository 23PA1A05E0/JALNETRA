// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

Welcome welcomeFromJson(String str) => Welcome.fromJson(json.decode(str));

String welcomeToJson(Welcome data) => json.encode(data.toJson());

class Welcome {
    String status;
    String station;
    int horizonDays;
    List<Forecast> forecast;

    Welcome({
        required this.status,
        required this.station,
        required this.horizonDays,
        required this.forecast,
    });

    factory Welcome.fromJson(Map<String, dynamic> json) => Welcome(
        status: json["status"],
        station: json["station"],
        horizonDays: json["horizon_days"],
        forecast: List<Forecast>.from(json["forecast"].map((x) => Forecast.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "station": station,
        "horizon_days": horizonDays,
        "forecast": List<dynamic>.from(forecast.map((x) => x.toJson())),
    };
}

class Forecast {
    DateTime date;
    double forecast;

    Forecast({
        required this.date,
        required this.forecast,
    });

    factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(
        date: DateTime.parse(json["date"]),
        forecast: json["forecast"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "date": date.toIso8601String(),
        "forecast": forecast,
    };
}
