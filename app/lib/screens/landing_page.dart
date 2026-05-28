import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? selectedService;
  String? selectedSlot;
  bool isLoadingGoogle = false;
  @override
  void initState() {
    super.initState();
  }

  final List<Map<String, String>> services = [
    {"title": "Full haircut + full dye", "price": "₦1800", "duration": "90 min session"},
    {"title": "Full haircut", "price": "₦1000", "duration": "45 min session"},
  ];

  final List<String> dailySlots = [
    "09:00 AM",
    "11:30 AM",
    "02:00 PM",
    "04:30 PM",
  ];

  void _handleGoogleLogin() async {
    setState(() {
      isLoadingGoogle = true;
    });
    
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? 'https://celebritybarbers.vercel.app' : 'celebritybarbers://login-callback/',
        queryParams: {
          'client_id': '442583132863-prep3v2m41ogt8r6nfhnlfc2vstb0q94.apps.googleusercontent.com',
        },
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
    }
    
    if (mounted) {
      setState(() {
        isLoadingGoogle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Premium light mode aesthetic
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Celebrity Barbers',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.orange[200],
              radius: 16,
              child: const Icon(Icons.person, color: Colors.black87, size: 20),
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
              const SizedBox(height: 32),
              // Hero Section
              const Text(
                'Premium\ngrooming,\nbooked in\nseconds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.black87,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A zero-stress experience for the\nmodern professional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              
              // Google Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoadingGoogle ? null : _handleGoogleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isLoadingGoogle
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                              height: 20,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Book Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SECURE PROFESSIONAL PORTAL',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 48),

              // Showcase Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&q=80&w=1000', // Premium barber image
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),

              // Services Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'PRICING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.brown[600],
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ...services.map((service) => _buildServiceCard(
                    title: service['title']!,
                    duration: service['duration']!,
                    price: service['price']!,
                  )),

              const SizedBox(height: 32),

              // Daily Slots Section
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'DAILY SLOTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: dailySlots.map((slot) => _buildSlotChip(slot)).toList(),
                ),
              ),

              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Celebrity Barbers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: [
                _footerLink('Services'),
                _footerLink('Availability'),
                _footerLink('Privacy'),
                _footerLink('Terms'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2024 Celebrity Barbers. Precise. Exclusive.\nProfessional.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String duration,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[100] : const Color(0xFFFCFCFC),
          border: Border.all(
            color: isSelected ? Colors.black26 : Colors.black12,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.brown[700],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotChip(String slot) {
    final isSelected = selectedSlot == slot;
    
    // Split text if it matches the pattern "09:00 AM" to match layout potentially
    final parts = slot.split(' ');
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSlot = slot;
        });
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF9F9F9),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              parts[0],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            if (parts.length > 1)
              Text(
                parts[1],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    );
  }
}
