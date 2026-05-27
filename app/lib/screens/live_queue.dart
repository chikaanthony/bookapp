import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveQueuePage extends StatefulWidget {
  const LiveQueuePage({super.key});

  @override
  State<LiveQueuePage> createState() => _LiveQueuePageState();
}

class _LiveQueuePageState extends State<LiveQueuePage> {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _placeholderKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  
  final ValueNotifier<double> _stickyTop = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isReady = ValueNotifier<bool>(false);
  
  final double _rowHeight = 96.0; 
  String _activeClientName = '';

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    _activeClientName = metadata['full_name'] ?? metadata['name'] ?? metadata['email'] ?? '';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateStickyPosition();
    });
    _scrollController.addListener(_updateStickyPosition);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stickyTop.dispose();
    _isReady.dispose();
    super.dispose();
  }

  void _updateStickyPosition() {
    if (!mounted || _placeholderKey.currentContext == null || _stackKey.currentContext == null) return;
    
    final RenderBox stackBox = _stackKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox placeholderBox = _placeholderKey.currentContext!.findRenderObject() as RenderBox;
    
    final Offset localOffset = stackBox.globalToLocal(placeholderBox.localToGlobal(Offset.zero));
    
    double y = localOffset.dy;
    double minTop = 0;
    double maxTop = stackBox.size.height - _rowHeight;
    
    if (y < minTop) y = minTop;
    if (y > maxTop) y = maxTop;
    
    if (_stickyTop.value != y) {
      _stickyTop.value = y;
    }
    if (!_isReady.value) {
      _isReady.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFCFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
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
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 32.0, top: 16.0),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.notifications_active_outlined, size: 20),
            label: const Text(
              'NOTIFY ME',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('bookings')
            .stream(primaryKey: ['id'])
            .eq('status', 'pending')
            .order('created_at', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading live queue: ${snapshot.error}'));
          }

          final List<Map<String, dynamic>> bookings = snapshot.data ?? [];
          
          int activeIndex = bookings.indexWhere((b) => b['client_name'] == _activeClientName);
          final bool hasActiveBooking = activeIndex != -1;
          
          final List<Map<String, dynamic>> aheadList = hasActiveBooking 
              ? bookings.sublist(0, activeIndex) 
              : bookings;
              
          final List<Map<String, dynamic>> behindList = hasActiveBooking 
              ? bookings.sublist(activeIndex + 1) 
              : [];
          
          // Guarantee sticky position recalculation when layout finishes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateStickyPosition();
          });

          return Stack(
            key: _stackKey,
            children: [
              CustomScrollView(
                controller: _scrollController,
                cacheExtent: 10000, 
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Live Que',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'Caveat', 
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Real-time schedule update',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final b = aheadList[index];
                          return _buildQueueItem(
                            b['client_name']?.toString() ?? 'Client',
                            index == 0 ? 'IN CHAIR' : 'WAITING',
                            'No ${index + 1}',
                            index == 0,
                          );
                        },
                        childCount: aheadList.length,
                      ),
                    ),
                  ),
                  if (hasActiveBooking)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        key: _placeholderKey,
                        height: _rowHeight,
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final b = behindList[index];
                          final absoluteIndex = hasActiveBooking ? activeIndex + 1 + index : aheadList.length + index;
                          return _buildQueueItem(
                            b['client_name']?.toString() ?? 'Client',
                            'WAITING',
                            'No ${absoluteIndex + 1}',
                            false,
                          );
                        },
                        childCount: behindList.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
              
              if (hasActiveBooking)
                ValueListenableBuilder<bool>(
                  valueListenable: _isReady,
                  builder: (context, isReady, child) {
                    if (!isReady) return const SizedBox.shrink();
                    
                    return ValueListenableBuilder<double>(
                      valueListenable: _stickyTop,
                      builder: (context, top, child) {
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          child: _buildActiveUserRow(activeIndex + 1),
                        );
                      },
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveUserRow(int position) {
    // Basic calculation for wait time, 30 mins per client ahead
    final waitMins = (position - 1) * 30;
    
    return Container(
      height: _rowHeight - 16, 
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _activeClientName.isNotEmpty ? _activeClientName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  position == 1 ? 'You are Next' : 'In Queue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC7A246),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE UPDATE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Color(0xFFC7A246),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Position: ${position}${_getOrdinalSuffix(position)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                waitMins == 0 ? 'Wait: Next' : 'Wait: ${waitMins}m',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getOrdinalSuffix(int i) {
    var j = i % 10, k = i % 100;
    if (j == 1 && k != 11) return "st";
    if (j == 2 && k != 12) return "nd";
    if (j == 3 && k != 13) return "rd";
    return "th";
  }

  Widget _buildQueueItem(String name, String status, String number, bool inChair) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: inChair ? Colors.black54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
