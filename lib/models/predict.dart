// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

Welcome welcomeFromJson(String str) => Welcome.fromJson(json.decode(str));

String welcomeToJson(Welcome data) => json.encode(data.toJson());

class Welcome {
    String station;
    DateTime date;
    double predictedLevelM;

    Welcome({
        required this.station,
        required this.date,
        required this.predictedLevelM,
    });

    factory Welcome.fromJson(Map<String, dynamic> json) => Welcome(
        station: json["station"],
        date: DateTime.parse(json["date"]),
        predictedLevelM: json["predicted_level_m"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "station": station,
        "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "predicted_level_m": predictedLevelM,
    };
}
