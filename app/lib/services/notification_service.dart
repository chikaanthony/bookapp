import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final SupabaseClient _supabase = Supabase.instance.client;

  FirebaseMessaging? get _firebaseMessaging {
    if (_fcm != null) return _fcm;
    try {
      _fcm = FirebaseMessaging.instance;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Messaging not available: $e');
      }
      _fcm = null;
    }
    return _fcm;
  }

  /// Initializes permissions and notification message streams.
  Future<void> initialize(BuildContext context) async {
    final messaging = _firebaseMessaging;
    if (messaging == null) {
      if (kDebugMode) {
        print('⚠️ Skipping notification initialization because Firebase Messaging is unavailable.');
      }
      return;
    }

    try {
      // 1. Request OS level permissions
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('🔔 User notification permission status: ${settings.authorizationStatus}');
      }

      // 2. Synchronize FCM token if user is already signed in
      await syncDeviceToken();

      // 3. Listen to token refresh events
      messaging.onTokenRefresh.listen((newToken) async {
        await _saveTokenToSupabase(newToken);
      });

      // 4. Handle Foreground Messages (In-App Notification Alerts)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (context.mounted && message.notification != null) {
          _showInAppBanner(context, message);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize notification service: $e');
      }
    }
  }

  /// Retrieves the current token and uploads it to Supabase if authenticated.
  Future<void> syncDeviceToken() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final messaging = _firebaseMessaging;
    if (messaging == null) return;

    try {
      String? token = await messaging.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching/syncing FCM device token: $e');
      }
    }
  }

  /// Helper to upsert the FCM token into device_tokens table.
  Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    String deviceType = 'web';
    if (!kIsWeb) {
      if (Platform.isAndroid) deviceType = 'android';
      if (Platform.isIOS) deviceType = 'ios';
    }

    try {
      await _supabase.from('device_tokens').upsert({
        'token': token,
        'user_id': user.id,
        'device_type': deviceType,
      });
      if (kDebugMode) {
        print('🚀 FCM Token successfully synchronized to Supabase.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving device token to database: $e');
      }
    }
  }

  /// Displays an in-app banner for active foreground notifications.
  void _showInAppBanner(BuildContext context, RemoteMessage message) {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.black87,
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFFC7A246)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        body,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
