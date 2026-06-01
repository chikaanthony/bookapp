import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'landing_page.dart';
import 'queue_view.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String? selectedService;
  String? selectedDate;
  String? phoneNumber;
  
  String firstName = 'CELEB';
  String? avatarUrl;
  bool _isBooking = false;
  
  List<Map<String, String>> dynamicDates = [];

  final List<Map<String, String>> services = [
    {
      "title": "Full Haircut",
      "price": "₦1200",
      "description": "Full consultation, precision fade, beard sculpt & hot towel finish."
    },
    {
      "title": "Full Haircut + Dye",
      "price": "₦1800",
      "description": "Premium haircut with full color service for a complete style refresh."
    },
    {
      "title": "Hair Lining",
      "price": "₦600",
      "description": "Sharp, clean hairline shaping and edge detail for crisp results."
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _generateDates();
  }
  
  void _loadUserData() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final fullName = currentUser?.userMetadata?['full_name'] as String? ?? 'CELEB';
    firstName = fullName.split(' ').first.toUpperCase();
    avatarUrl = currentUser?.userMetadata?['avatar_url'] as String?;
  }
  
  void _generateDates() {
    final now = DateTime.now();
    for (int i = 0; i < 5; i++) {
      final date = now.add(Duration(days: i));
      final dayStr = DateFormat('EEE').format(date).toUpperCase();
      final dateStr = DateFormat('dd').format(date);
      dynamicDates.add({"day": dayStr, "date": dateStr, "fullDate": date.toIso8601String()});
    }
    
    // Default to the current day
    if (dynamicDates.isNotEmpty) {
      selectedDate = dynamicDates.first['date'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC), // Very light, almost white background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFCFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            tooltip: 'Log Out',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => CircleAvatar(
                        backgroundColor: Colors.black87,
                        radius: 16,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0] : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: Colors.black87,
                    radius: 16,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0] : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Greeting
              Text(
                'WELCOME BACK,\n$firstName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  height: 1.2,
                  fontFamily: 'Times New Roman', // Serif look
                ),
              ),
              const SizedBox(height: 24),
              
              // Loyalty Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[400]!, width: 2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[400]!, width: 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '2 CUTS AWAY FROM A FREE VIP\nLINEUP.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Services
              ...services.map((service) => _buildServiceCard(
                    title: service['title']!,
                    description: service['description']!,
                    price: service['price']!,
                  )),

              const SizedBox(height: 32),

              // Phone Number
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'PHONE NUMBER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    ' (Optional)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  phoneNumber = value.isEmpty ? null : value;
                },
                decoration: InputDecoration(
                  hintText: 'Phone Number (Optional)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 32),

              // Date Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT DATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dynamicDates.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final dateInfo = dynamicDates[index];
                    return _buildDateCard(dateInfo['day']!, dateInfo['date']!);
                  },
                ),
              ),

              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFF9F9F9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                '© 2024 Celebrity Barbers. Precise. Exclusive. Professional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 32.0, top: 16.0),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isBooking ? null : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    elevation: 0,
                  ),
                  child: _isBooking
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'BOOK SESSION',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBooking() async {
    if (selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service.')),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final selectedServiceInfo = services.firstWhere((s) => s['title'] == selectedService);
      final rawPrice = selectedServiceInfo['price']!;
      final cleanPriceValue = int.parse(rawPrice.replaceAll(RegExp(r'[^0-9]'), ''));

      final user = Supabase.instance.client.auth.currentUser;

      final response = await Supabase.instance.client.from('bookings').insert({
        'client_name': user?.userMetadata?['full_name'] ?? 'Unknown Celeb',
        'service_type': selectedService,
        'price': cleanPriceValue,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'user_id': user?.id,
        'client_phone': phoneNumber,
      }).select().single();

      final String bookingId = response['id'].toString();

      // Fetch all pending bookings
      final allPendingBookings = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('status', 'pending');

      // Sort the final list strictly in ASCENDING order using the 'created_at' string
      allPendingBookings.sort((a, b) => (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''));

      // Calculate global position across ALL pending bookings (matching admin dashboard logic)
      int clientsAhead = 0;

      for (final booking in allPendingBookings) {
        if (booking['id'].toString() == bookingId) {
          break;
        }
        clientsAhead++;
      }
      final userPosition = clientsAhead + 1;

      if (mounted) {
        _showConfirmationModal(userPosition, clientsAhead, bookingId);
      }
    } catch (e) {
      debugPrint('⚡ Booking Engine Insert Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error booking session. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  void _showConfirmationModal(int userPosition, int clientsAhead, String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFF2F2F2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  'POSITION #$userPosition',
                  style: const TextStyle(
                    color: Color(0xFFC7A246), // Gold color from image
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  clientsAhead == 0
                      ? 'You are next in line.'
                      : clientsAhead == 1
                          ? '1 client ahead of you.'
                          : '$clientsAhead clients ahead of you.',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
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
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
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
                          const Icon(Icons.content_copy, size: 20, color: Colors.black87),
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
                      // 1. First, pop the modal dialog layer safely off the context stack
                      Navigator.pop(context);
                      
                      // 2. Transition the viewport seamlessly onto the QueueView screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QueueView(
                            userPosition: userPosition,
                            clientsAhead: clientsAhead,
                            bookingId: bookingId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'TAKE ME TO QUEUE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String description,
    required String price,
  }) {
    final isSelected = selectedService == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedService = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[50] : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.black12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Times New Roman', // Serif look
                    color: Colors.black87,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.brown[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(String day, String date) {
    final isSelected = selectedDate == date;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = date;
        });
      },
      child: Container(
        width: 65,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Times New Roman', // Serif look
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}