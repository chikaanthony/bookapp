import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/landing_page.dart';
import 'screens/booking_page.dart';
import 'screens/queue_view.dart';
import 'screens/admin_dashboard.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://wjxdzgkxnccsvtyjzlto.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqeGR6Z2t4bmNjc3Z0eWp6bHRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MTU3NzgsImV4cCI6MjA5NTM5MTc3OH0.uMqy_-1k3FHDVZ0U0U-dxkop13OHHz1A-Cw_KorkECM',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Helper to check for a pending booking for the current user
  Future<Map<String, dynamic>?> _fetchPendingBooking() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('⚡ Auth Router: No current user session found.');
      return null;
    }

    final meta = user.userMetadata;
    final String clientName = meta?['full_name'] ?? meta?['name'] ?? user.email ?? '';

    if (clientName.trim().isEmpty) {
      debugPrint('⚡ Auth Router: Client identifier is empty. Bypassing database lookup to prevent hang.');
      return null;
    }

    try {
      debugPrint('⚡ Auth Router: Checking bookings table for client: $clientName');
      final bookings = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('client_name', clientName)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1)
          .timeout(const Duration(seconds: 3));
      
      debugPrint('⚡ Auth Router: Query complete. Found ${bookings.length} record(s)');
      if (bookings.isEmpty) return null;
      return bookings.first as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Auth Router Database Error or Timeout: $e');
      return null; // Safe fallback on error or timeout
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Celebrity Barbers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, authSnapshot) {
          // 1. Guard against native auth initialization stream crashes
          if (authSnapshot.hasError) {
            debugPrint('❌ Native Auth Stream Error Intercepted: ${authSnapshot.error}');
            return const LandingPage(); // Clear the crash and let them retry cleanly
          }

          // 2. Handle standard loading state while stream settles
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.black)),
            );
          }

          final session = authSnapshot.data?.session;
          if (session == null) {
            // Not logged in – show landing page
            return const LandingPage();
          }
          
          final String userEmail = session.user.email ?? '';
          if (userEmail == 'chikaanthony896@gmail.com') {
            return const NotificationWrapper(child: AdminDashboard()); // Send straight to management portal
          }
          
          // Logged in as standard user – determine if there is a pending booking
          return NotificationWrapper(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _fetchPendingBooking(),
              builder: (context, bookingSnap) {
                // Show loading indicator while waiting
                if (bookingSnap.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    ),
                  );
                }
                // If the future completed with an error, log and fallback
                if (bookingSnap.hasError) {
                  debugPrint('⚡ Routing Engine Error: ${bookingSnap.error}');
                  return const BookingPage();
                }
                // If a pending booking exists, show the queue view
                if (bookingSnap.hasData && bookingSnap.data != null) {
                  final booking = bookingSnap.data!;
                  final userPosition = booking['queue_position'] ?? 1;
                  final clientsAhead = (userPosition - 1).clamp(0, userPosition);
                  return QueueView(
                    userPosition: userPosition,
                    clientsAhead: clientsAhead,
                    bookingId: booking['id'].toString(),
                  );
                }
                // No pending booking – go to booking page
                return const BookingPage();
              },
            ),
          );
        },
      ),
    );
  }
}

class NotificationWrapper extends StatefulWidget {
  final Widget child;
  const NotificationWrapper({super.key, required this.child});

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
