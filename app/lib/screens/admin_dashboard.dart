import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'landing_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _todaysRevenue = 0; 
  bool _isAuthorized = true;
  List<Map<String, dynamic>> _currentBookings = [];
  int _currentTabIndex = 0;

  double _chartScale = 1.0;
  double _chartScrollOffset = 0.0;
  double _baseScale = 1.0;
  double _baseScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _checkAccessAndFetchMetrics();
  }

  Future<void> _checkAccessAndFetchMetrics() async {
    final user = Supabase.instance.client.auth.currentUser;
    final String userEmail = user?.email ?? '';

    if (userEmail != 'chikaanthony896@gmail.com') {
      debugPrint('⚡ SECURITY ALERT: Unauthorized access attempt by $userEmail');
      _isAuthorized = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LandingPage()),
        );
      });
      return;
    }

    try {
      final now = DateTime.now();
      final todayYear = now.year;
      final todayMonth = now.month;
      final todayDay = now.day;
      
      final completedBookings = await Supabase.instance.client
          .from('booking_history')
          .select();
          
      int revenue = 0;
      for (var booking in completedBookings) {
        final completedAtStr = booking['created_at']?.toString() ?? booking['completed_at']?.toString() ?? '';
        if (completedAtStr.isNotEmpty) {
          try {
            final completedAtDate = DateTime.parse(completedAtStr).toLocal();
            if (completedAtDate.year == todayYear &&
                completedAtDate.month == todayMonth &&
                completedAtDate.day == todayDay) {
              revenue += int.tryParse(booking['price']?.toString() ?? '') ?? 0;
            }
          } catch (_) {}
        }
      }
      
      if (mounted) {
        setState(() {
          _todaysRevenue = revenue;
        });
      }
    } catch (e) {
      debugPrint('Metrics fetch error: $e');
    }
  }

  void _finishCut(String bookingId) async {
    try {
      // 1. Fetch current booking details from bookings
      final booking = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      // 2. Insert copy into booking_history (let it auto-generate its timestamp)
      await Supabase.instance.client
          .from('booking_history')
          .insert({
            'user_name': booking['client_name'],
            'service': booking['service_type'],
            'price': booking['price'],
            'user_id': booking['user_id'],
            'status': 'completed',
          });

      // 3. Delete the original row from bookings
      await Supabase.instance.client
          .from('bookings')
          .delete()
          .eq('id', bookingId);
          
      _checkAccessAndFetchMetrics();
    } catch (e) {
      debugPrint('Error finishing cut: $e');
    }
  }
  
  void _markNoShow(String bookingId) async {
    try {
      // Permanently delete the booking from bookings
      await Supabase.instance.client
          .from('bookings')
          .delete()
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('Error cancelling cut: $e');
    }
  }
  
  void _callNextClient() {
    if (_currentBookings.isNotEmpty) {
      final nextClient = _currentBookings.first;
      final name = nextClient['client_name'] ?? 'Unknown Client';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Ringing $name to the chair!'),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Queue is currently empty.'),
        ),
      );
    }
  }

  Widget _buildTrailingMenu(String id, String name) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black54),
      onSelected: (value) {
        if (value == 'finish') {
          _finishCut(id);
        } else if (value == 'notify') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification sent to $name.')));
        } else if (value == 'cancel') {
          _markNoShow(id);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'finish', child: Text('Finish Cut')),
        const PopupMenuItem(value: 'notify', child: Text('Notify Client')),
        const PopupMenuItem(
          value: 'cancel', 
          child: Text('Cancel Request', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('status', 'pending'),
      builder: (context, snapshot) {
        var fetchedBookings = snapshot.data ?? [];
        var pendingBookings = List<Map<String, dynamic>>.from(fetchedBookings);

        // Sort the final list strictly in ASCENDING order using the 'created_at' string
        pendingBookings.sort((a, b) => (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''));

        var bookings = pendingBookings;
        final todaysBookings = pendingBookings;

        // Cache the live bookings for the Call Next action button
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentBookings.length != bookings.length) {
            _currentBookings = bookings;
          }
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9F9F9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
              tooltip: 'Back to Main',
              onPressed: () {
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LandingPage()),
                  );
                }
              },
            ),
            title: const Text(
              'CELEBRITY BARBERS',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 1.0,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'),
                  radius: 16,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _currentTabIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _currentTabIndex == 0 ? Colors.black : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_ind_outlined, 
                                    color: _currentTabIndex == 0 ? Colors.white : Colors.black54, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Live Queue',
                                    style: TextStyle(
                                      color: _currentTabIndex == 0 ? Colors.white : Colors.black54, 
                                      fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _currentTabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _currentTabIndex == 1 ? Colors.black : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bar_chart_outlined, 
                                    color: _currentTabIndex == 1 ? Colors.white : Colors.black54, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Analytics',
                                    style: TextStyle(
                                      color: _currentTabIndex == 1 ? Colors.white : Colors.black54, 
                                      fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === TAB CONTENT ===
                  if (_currentTabIndex == 0) ...[
                    // === LIVE QUEUE TAB ===
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Users',
                                  style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${bookings.length}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Revenue",
                                  style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
StreamBuilder<List<Map<String, dynamic>>>(
                                   stream: Supabase.instance.client
                                       .from('booking_history')
                                       .stream(primaryKey: ['id']),
                                  builder: (context, completedSnap) {
                                    int liveRevenue = 0;
                                    if (completedSnap.hasData) {
                                      final now = DateTime.now();
                                      final todayYear = now.year;
                                      final todayMonth = now.month;
                                      final todayDay = now.day;
                                      for (var b in completedSnap.data!) {
                                        final completedAtStr = b['completed_at']?.toString() ?? b['created_at']?.toString() ?? '';
                                        if (completedAtStr.isNotEmpty) {
                                          try {
                                            final completedAtDate = DateTime.parse(completedAtStr).toLocal();
                                            if (completedAtDate.year == todayYear &&
                                                completedAtDate.month == todayMonth &&
                                                completedAtDate.day == todayDay) {
                                              liveRevenue += int.tryParse(b['price']?.toString() ?? '') ?? 0;
                                            }
                                          } catch (_) {}
                                        }
                                      }
                                    }
                                    // If no data yet, show 0.
                                    return Text(
                                      currencyFormat.format(liveRevenue),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF967300),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Lineup',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator(color: Colors.black)),
                      )
                    else if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(child: Text('Error loading queue: ${snapshot.error}')),
                      )
                    else if (bookings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Queue is currently empty.',
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bookings.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == bookings.length) {
                            return const SizedBox(height: 100);
                          }
                          
                          final booking = bookings[index];
                          final bookingId = booking['id'].toString();
                          final clientName = booking['client_name'] ?? 'Unknown Client';
                          final serviceType = booking['service_type'] ?? 'Standard Cut';
                          final price = int.tryParse(booking['price']?.toString() ?? '') ?? 1800;
                          final clientPhone = booking['client_phone'] as String?;
                          
                          if (index == 0) {
                            return _buildActiveChairTile(bookingId, clientName, serviceType, price, currencyFormat, clientPhone);
                          } else {
                            return _buildWaitingTile(bookingId, clientName, serviceType, price, currencyFormat, clientPhone);
                          }
                        },
                      ),
                  ] else ...[
                    // === ANALYTICS TAB ===
                    _buildAnalyticsView(currencyFormat),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            color: const Color(0xFFF9F9F9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 8.0, top: 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _callNextClient,
                      icon: const Icon(Icons.notifications_active_outlined, size: 20),
                      label: const Text(
                        'NEXT UP / CALL CLIENT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black12)),
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: const Color(0xFFF9F9F9),
                    elevation: 0,
                    currentIndex: _currentTabIndex,
                    onTap: (index) => setState(() => _currentTabIndex = index),
                    selectedItemColor: const Color(0xFF967300),
                    unselectedItemColor: Colors.black54,
                    showUnselectedLabels: true,
                    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.assignment_ind_outlined),
                        activeIcon: Icon(Icons.assignment_ind),
                        label: 'Live Queue',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.bar_chart_outlined),
                        label: 'Analytics',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildActiveChairTile(String id, String name, String service, dynamic price, NumberFormat format, String? phone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?img=12'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF967300),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  service,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                if (phone != null && phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: SelectableText(
                      '📞 $phone',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400], // Matches the app dark mode dashboard
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  format.format(price),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF967300), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _finishCut(id),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
            child: const Text(
              'FINISH\nCUT',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
            ),
          ),
          _buildTrailingMenu(id, name),
        ],
      ),
    );
  }

  Widget _buildWaitingTile(String id, String name, String service, dynamic price, NumberFormat format, String? phone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/150?img=13'),
                fit: BoxFit.cover,
                opacity: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  service,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 2),
                Text(
                  phone != null && phone.isNotEmpty ? '📞 $phone' : 'No phone provided',
                  style: TextStyle(
                    fontSize: 12,
                    color: phone != null && phone.isNotEmpty ? Colors.green[700] : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  format.format(price),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF967300), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          _buildTrailingMenu(id, name),
        ],
      ),
    );
  }

  // ================================================================
  // ANALYTICS TAB VIEW
  // ================================================================
  Widget _buildAnalyticsView(NumberFormat currencyFormat) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
           .from('booking_history')
           .stream(primaryKey: ['id'])
           .order('completed_at', ascending: true),
      builder: (context, completedSnap) {
        final completedBookings = completedSnap.data ?? [];
        
        // Calculate 7-day revenue data based on completion timestamp
        final now = DateTime.now();
        final List<String> dayLabels = [];
        final List<double> dailyRevenues = [];
        double weekTotal = 0;

        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final dayStr = day.toIso8601String().split('T').first;
          dayLabels.add(DateFormat('EEE').format(day).toUpperCase().substring(0, 3));
          
          double dayRevenue = 0;
          for (var b in completedBookings) {
            final completedAtStr = b['created_at']?.toString() ?? b['completed_at']?.toString() ?? '';
            if (completedAtStr.startsWith(dayStr)) {
              dayRevenue += (int.tryParse(b['price']?.toString() ?? '') ?? 0).toDouble();
            }
          }
          dailyRevenues.add(dayRevenue);
          weekTotal += dayRevenue;
        }
        
        // Calculate last week total for growth % based on completion timestamp
        double lastWeekTotal = 0;
        for (int i = 13; i >= 7; i--) {
          final day = now.subtract(Duration(days: i));
          final dayStr = day.toIso8601String().split('T').first;
          for (var b in completedBookings) {
            final completedAtStr = b['created_at']?.toString() ?? b['completed_at']?.toString() ?? '';
            if (completedAtStr.startsWith(dayStr)) {
              lastWeekTotal += (int.tryParse(b['price']?.toString() ?? '') ?? 0).toDouble();
            }
          }
        }
        
        String growthText;
        if (lastWeekTotal > 0) {
          final pct = ((weekTotal - lastWeekTotal) / lastWeekTotal * 100);
          growthText = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}% from last week';
        } else if (weekTotal > 0) {
          growthText = '+100% from last week';
        } else {
          growthText = 'No data from last week';
        }

        // Get sorted recent transactions for the history list, chronologically descending
        final recentTransactions = List<Map<String, dynamic>>.from(completedBookings);
        recentTransactions.sort((a, b) {
          final aDate = a['created_at']?.toString() ?? a['completed_at']?.toString() ?? '';
          final bDate = b['created_at']?.toString() ?? b['completed_at']?.toString() ?? '';
          return bDate.compareTo(aDate);
        });

        // Extract unique days (Y-M-D) to dynamically assign alternating workday themes
        final List<String> uniqueDates = [];
        for (var tx in recentTransactions) {
          final dateStr = tx['completed_at']?.toString() ?? tx['created_at']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            final ymd = dateStr.split('T').first;
            if (!uniqueDates.contains(ymd)) {
              uniqueDates.add(ymd);
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            // OVERVIEW Label
            const Text(
              'OVERVIEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Color(0xFF967300),
              ),
            ),
            const SizedBox(height: 12),
            // Revenue header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    '7-Day\nRevenue\nTrend',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(weekTotal.toInt()),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      growthText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF967300),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Chart Card
            LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth - 40; // account for padding
                
                return GestureDetector(
                  onScaleStart: (details) {
                    _baseScale = _chartScale;
                    _baseScrollOffset = _chartScrollOffset;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _chartScale = (_baseScale * details.horizontalScale).clamp(1.0, 5.0);
                      final maxScroll = chartWidth * (_chartScale - 1.0);
                      _chartScrollOffset = (_baseScrollOffset + details.focalPointDelta.dx).clamp(-maxScroll, 0.0);
                    });
                  },
                  onDoubleTap: () {
                    setState(() {
                      _chartScale = 1.0;
                      _chartScrollOffset = 0.0;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _RevenueChartPainter(
                              dailyRevenues,
                              _chartScale,
                              _chartScrollOffset,
                              dayLabels,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Transaction History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TRANSACTION HISTORY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF Export coming soon.')),
                    );
                  },
                  child: const Text(
                    'Export PDF',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF967300),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transaction List
            if (recentTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No completed transactions yet.',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(recentTransactions.length, 20),
                separatorBuilder: (context, index) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  final tx = recentTransactions[index];
                  final name = tx['user_name']?.toString() ?? tx['client_name']?.toString() ?? 'Unknown';
                  final service = tx['service']?.toString() ?? tx['service_type']?.toString() ?? 'Haircut';
                  final price = int.tryParse(tx['price']?.toString() ?? '') ?? 0;
                  final dateStr = tx['created_at']?.toString() ?? tx['completed_at']?.toString() ?? '';
                  
                  String ymd = '';
                  String formattedDateHeader = '';
                  if (dateStr.isNotEmpty) {
                    try {
                      final parsedDate = DateTime.parse(dateStr).toLocal();
                      ymd = dateStr.split('T').first;
                      formattedDateHeader = DateFormat('EEEE, MMMM d').format(parsedDate);
                    } catch (_) {}
                  }
                  
                  // Check if this card starts a new date group
                  bool isNewDayGroup = false;
                  if (index == 0) {
                    isNewDayGroup = true;
                  } else {
                    final prevTx = recentTransactions[index - 1];
                    final prevDateStr = prevTx['created_at']?.toString() ?? prevTx['completed_at']?.toString() ?? '';
                    if (prevDateStr.isNotEmpty) {
                      final prevYmd = prevDateStr.split('T').first;
                      if (prevYmd != ymd) {
                        isNewDayGroup = true;
                      }
                    }
                  }

                  final dateIndex = uniqueDates.indexOf(ymd);
                  final isEvenDay = dateIndex % 2 == 0;
                  
                  final cardBgColor = isEvenDay ? const Color(0xFFF4F9F4) : const Color(0xFFFFFBEA);
                  final accentColor = isEvenDay ? const Color(0xFF4CAF50) : const Color(0xFFFFB300);
                  final dotColor = isEvenDay ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

                  final cardWidget = Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      border: Border(
                        left: BorderSide(color: accentColor, width: 4),
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isNewDayGroup && formattedDateHeader.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
                          child: Text(
                            formattedDateHeader.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        cardWidget,
                      ],
                    );
                  }
                  
                  return cardWidget;
                },
              ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }
}

// ================================================================
// CUSTOM LINE CHART PAINTER
// ================================================================
class _RevenueChartPainter extends CustomPainter {
  final List<double> data;
  final double scale;
  final double scrollOffset;
  final List<String> dayLabels;

  _RevenueChartPainter(this.data, this.scale, this.scrollOffset, this.dayLabels);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = maxVal - minVal;

    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    // Clip vector operations to the layout bounds so they don't draw outside when zoomed
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Reserve 30px at the bottom of the canvas height for day labels
    final chartHeight = size.height - 30;

    for (int i = 0; i < data.length; i++) {
      final x = ((i / (data.length - 1)) * size.width * scale) + scrollOffset;
      final normalizedY = range == 0 ? 0.5 : (data[i] - minVal) / range;
      final y = chartHeight - (normalizedY * (chartHeight - 20)) - 10;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        // Crisp straight connection lines
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw dots at each data point
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }

    // Render day labels aligned directly beneath each point
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );
    
    for (int i = 0; i < data.length; i++) {
      if (i < dayLabels.length) {
        final x = ((i / (data.length - 1)) * size.width * scale) + scrollOffset;
        
        final textSpan = TextSpan(
          text: dayLabels[i],
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        );
        textPainter.text = textSpan;
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - 15),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.data != data ||
        oldDelegate.dayLabels != dayLabels;
  }
}