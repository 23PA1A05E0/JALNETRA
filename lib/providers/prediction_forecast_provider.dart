import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/groundwater_data_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Provider for the GroundwaterDataService
final groundwaterDataServiceProvider = Provider((ref) => GroundwaterDataService());

// Provider for prediction data
final predictionDataProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, location) async {
  final service = ref.watch(groundwaterDataServiceProvider);
  try {
    return await service.getPredictionData(location);
  } catch (e, st) {
    logger.e('Error fetching prediction data for $location', error: e, stackTrace: st);
    return null;
  }
});

// Provider for forecast data
final forecastDataProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, location) async {
  final service = ref.watch(groundwaterDataServiceProvider);
  try {
    return await service.getForecastData(location);
  } catch (e, st) {
    logger.e('Error fetching forecast data for $location', error: e, stackTrace: st);
    return null;
  }
});

// Provider for all prediction data
final allPredictionDataProvider = FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final service = ref.watch(groundwaterDataServiceProvider);
  try {
    final Map<String, Map<String, dynamic>> allData = {};
    final locations = service.getAvailableLocations();
    
    for (final location in locations) {
      final predictionData = await service.getPredictionData(location);
      if (predictionData != null) {
        allData[location] = predictionData;
      }
    }
    
    return allData;
  } catch (e, st) {
    logger.e('Error fetching all prediction data', error: e, stackTrace: st);
    return {};
  }
});

// Provider for all forecast data
final allForecastDataProvider = FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final service = ref.watch(groundwaterDataServiceProvider);
  try {
    final Map<String, Map<String, dynamic>> allData = {};
    final locations = service.getAvailableLocations();
    
    for (final location in locations) {
      final forecastData = await service.getForecastData(location);
      if (forecastData != null) {
        allData[location] = forecastData;
      }
    }
    
    return allData;
  } catch (e, st) {
    logger.e('Error fetching all forecast data', error: e, stackTrace: st);
    return {};
  }
});

// Provider for prediction statistics
final predictionStatsProvider = Provider.family<Map<String, dynamic>, String>((ref, location) {
  final predictionData = ref.watch(predictionDataProvider(location));
  
  return predictionData.when(
    data: (data) {
      if (data == null) return {};
      
      return {
        'predictedDepth': data['predictedDepth'] ?? 0.0,
        'confidence': data['confidence'] ?? 0.0,
        'accuracy': data['accuracy'] ?? 0.0,
        'modelVersion': data['modelVersion'] ?? 'Unknown',
        'predictionDate': data['predictionDate'] ?? '',
        'dataSource': data['dataSource'] ?? 'API',
      };
    },
    loading: () => {},
    error: (error, stack) => {},
  );
});

// Provider for forecast statistics
final forecastStatsProvider = Provider.family<Map<String, dynamic>, String>((ref, location) {
  final forecastData = ref.watch(forecastDataProvider(location));
  
  return forecastData.when(
    data: (data) {
      if (data == null) return {};
      
      final forecastDataList = data['forecastData'] as List<Map<String, dynamic>>? ?? [];
      
      return {
        'forecastPeriod': data['forecastPeriod'] ?? '30 days',
        'reliability': data['reliability'] ?? 0.0,
        'modelVersion': data['modelVersion'] ?? 'Unknown',
        'forecastDate': data['forecastDate'] ?? '',
        'dataSource': data['dataSource'] ?? 'API',
        'forecastCount': forecastDataList.length,
        'averagePredictedDepth': forecastDataList.isNotEmpty 
            ? forecastDataList.map((d) => d['predictedDepth'] as double).reduce((a, b) => a + b) / forecastDataList.length
            : 0.0,
        'trend': forecastDataList.isNotEmpty 
            ? (forecastDataList.last['predictedDepth'] as double) - (forecastDataList.first['predictedDepth'] as double)
            : 0.0,
      };
    },
    loading: () => {},
    error: (error, stack) => {},
  );
});

// Provider for combined prediction and forecast data
final combinedPredictionForecastProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, location) async {
  final predictionData = ref.watch(predictionDataProvider(location));
  final forecastData = ref.watch(forecastDataProvider(location));
  
  return {
    'location': location,
    'prediction': predictionData.value,
    'forecast': forecastData.value,
    'lastUpdated': DateTime.now().toIso8601String(),
  };
});

// Provider for prediction alerts
final predictionAlertsProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, location) {
  final predictionData = ref.watch(predictionDataProvider(location));
  final forecastData = ref.watch(forecastDataProvider(location));
  
  final alerts = <Map<String, dynamic>>[];
  
  predictionData.whenData((data) {
    if (data != null) {
      final predictedDepth = data['predictedDepth'] as double? ?? 0.0;
      final confidence = data['confidence'] as double? ?? 0.0;
      
      if (predictedDepth < -10.0) {
        alerts.add({
          'type': 'critical_prediction',
          'message': 'Predicted groundwater level critically low',
          'severity': 'high',
          'predictedDepth': predictedDepth,
          'confidence': confidence,
        });
      }
      
      if (confidence < 0.7) {
        alerts.add({
          'type': 'low_confidence',
          'message': 'Low confidence in prediction accuracy',
          'severity': 'medium',
          'confidence': confidence,
        });
      }
    }
  });
  
  forecastData.whenData((data) {
    if (data != null) {
      final forecastDataList = data['forecastData'] as List<Map<String, dynamic>>? ?? [];
      if (forecastDataList.isNotEmpty) {
        final trend = (forecastDataList.last['predictedDepth'] as double) - (forecastDataList.first['predictedDepth'] as double);
        
        if (trend < -2.0) {
          alerts.add({
            'type': 'declining_forecast',
            'message': 'Forecast shows significant decline in groundwater levels',
            'severity': 'high',
            'trend': trend,
          });
        }
      }
    }
  });
  
  return alerts;
});
