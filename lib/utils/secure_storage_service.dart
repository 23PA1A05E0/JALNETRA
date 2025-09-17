import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Service for managing secure storage
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();
  
  static SecureStorageService get instance => _instance;
  
  final Logger _logger = Logger();
  
  /// Initialize the secure storage service
  Future<void> initialize() async {
    _logger.i('Initializing secure storage service');
    // Additional initialization if needed
  }
  
  /// Store a value securely
  Future<void> store(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      _logger.d('Stored secure value for key: $key');
    } catch (e) {
      _logger.e('Error storing secure value for key $key: $e');
      rethrow;
    }
  }
  
  /// Retrieve a value securely
  Future<String?> retrieve(String key) async {
    try {
      final value = await _storage.read(key: key);
      _logger.d('Retrieved secure value for key: $key');
      return value;
    } catch (e) {
      _logger.e('Error retrieving secure value for key $key: $e');
      return null;
    }
  }
  
  /// Delete a value securely
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      _logger.d('Deleted secure value for key: $key');
    } catch (e) {
      _logger.e('Error deleting secure value for key $key: $e');
      rethrow;
    }
  }
  
  /// Delete all values
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _logger.d('Deleted all secure values');
    } catch (e) {
      _logger.e('Error deleting all secure values: $e');
      rethrow;
    }
  }
  
  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      _logger.e('Error checking if key exists $key: $e');
      return false;
    }
  }
  
  /// Get all keys
  Future<Map<String, String>> getAll() async {
    try {
      final allValues = await _storage.readAll();
      _logger.d('Retrieved all secure values');
      return allValues;
    } catch (e) {
      _logger.e('Error retrieving all secure values: $e');
      return {};
    }
  }
  
  // Common keys for the app
  static const String apiKey = 'api_key';
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String settings = 'settings';
  static const String lastSyncTime = 'last_sync_time';
}
