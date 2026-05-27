import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'live_queue.dart';

class QueueView extends StatefulWidget {
  final int userPosition;
  final int clientsAhead;
  final String bookingId;
  
  const QueueView({
    Key? key, 
    required this.userPosition, 
    required this.clientsAhead,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  late final StreamSubscription<List<Map<String, dynamic>>> _bookingSubscription;

  @override
  void initState() {
    super.initState();

    _bookingSubscription = Supabase.instance.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('id', widget.bookingId) // Target this user's specific booking
        .listen((data) {
          if (data.isNotEmpty) {
            final currentStatus = data.first['status'];
            if (currentStatus == 'completed' || currentStatus == 'cancelled') {
              _handleStatusRedirection(currentStatus);
            }
          }
        });
  }

  @override
  void dispose() {
    _bookingSubscription.cancel();
    super.dispose();
  }

  void _handleStatusRedirection(String status) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Your booking has been $status.')),
    );
    // Pop back to the BookingPage
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // We will manually place a clean back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          tooltip: 'Back to Booking',
          onPressed: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('Your Queue', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'POSITION #${widget.userPosition}',
                style: const TextStyle(
                  color: Color(0xFFC7A246),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.clientsAhead == 0
                    ? 'You are next in line.'
                    : widget.clientsAhead == 1
                        ? '1 client ahead of you.'
                        : '${widget.clientsAhead} clients ahead of you.',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              // Account details placeholder – you can customize as needed
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.black12, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACCOUNT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '9161312015',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.content_copy, size: 20, color: Colors.black87),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.black12, height: 1),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'BANK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'OPay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'NAME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Chika Bright\nAnthony',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Transition to the new Live Queue page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LiveQueuePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'TAKE ME TO QUEUE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
