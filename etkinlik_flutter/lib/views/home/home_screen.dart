import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/event_model.dart';
import '../../models/category_model.dart';
import '../event_detail/event_detail_screen.dart';
import '../auth/login_register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  // --- filtreleme ve sıralama durum değişkenleri ---
  String _selectedDateFilter = 'Tüm Tarihler';
  RangeValues _priceRange = const RangeValues(0, 5000);
  final Set<String> _selectedVenues = {};
  String _sortBy = 'Öne Çıkanlar';
  String _venueSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAuthRequiredDialog(BuildContext context, String actionText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Giriş Yapmanız Gerekiyor',
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$actionText için lütfen giriş yapın veya ücretsiz kayıt olun.',
          style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.black45)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginRegisterScreen(initialIsRegister: false)),
              );
            },
            child: const Text('Giriş Yap / Kayıt Ol', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override //öne çıkan etkinlik tarihe göre
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    EventModel? featuredEvent;
    final now = DateTime.now();
    final upcomingEvents = eventProvider.events.where((e) => e.startDatetime.isAfter(now)).toList();
    if (upcomingEvents.isNotEmpty) {
      upcomingEvents.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
      featuredEvent = upcomingEvents.first;
      //gelecekte etkinlik yoksa
    } else if (eventProvider.events.isNotEmpty) {
      featuredEvent = eventProvider.events.first;
    }

    return Scaffold(//refresh
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          await eventProvider.fetchEvents();
          await eventProvider.fetchCategories();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //  öne çıkan etkinlik
              if (featuredEvent != null && _searchController.text.isEmpty && eventProvider.selectedCategoryId == null) ...[
                _buildHeroBanner(context, featuredEvent, authProvider, eventProvider),
                const SizedBox(height: 28),
              ],

              // arama çubuğu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // arama kutusu degisiminde provider arama filtresi tetiklemesi
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => eventProvider.setSearchQuery(val),
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Konser, tiyatro, stand-up, mekan veya şehir ara...',
                        hintStyle: GoogleFonts.inter(color: Colors.black38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF0066FF)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.black45),
                                onPressed: () {
                                  _searchController.clear();
                                  // provider arama filtresi temizleme tetiklemesi
                                  eventProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    //kategori menüsü
                    Row(
                      children: [
                        PopupMenuButton<int?>(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          offset: const Offset(0, 48),
                          onSelected: (int? categoryId) {
                            // provider kategori filtresi secim tetiklemesi
                            eventProvider.selectCategory(categoryId);
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem<int?>(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      color: eventProvider.selectedCategoryId == null
                                          ? const Color(0xFF0066FF)
                                          : Colors.black54,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Tüm Kategoriler',
                                      style: TextStyle(
                                        color: eventProvider.selectedCategoryId == null
                                            ? const Color(0xFF0066FF)
                                            : Colors.black87,
                                        fontWeight: eventProvider.selectedCategoryId == null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...eventProvider.categories.map((cat) {
                                final isSelected = eventProvider.selectedCategoryId == cat.id;
                                return PopupMenuItem<int?>(
                                  value: cat.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        color: isSelected ? const Color(0xFF0066FF) : Colors.black45,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          color: isSelected ? const Color(0xFF0066FF) : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ];
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.filter_list, color: Color(0xFF0066FF), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  eventProvider.selectedCategoryId != null
                                      ? (eventProvider.categories.firstWhere(
                                          (c) => c.id == eventProvider.selectedCategoryId,
                                          orElse: () => CategoryModel(id: -1, name: 'Tüm Kategoriler', slug: ''),
                                        ).name)
                                      : 'Tüm Kategoriler',
                                  style: GoogleFonts.outfit(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // --- BAŞLIK, ETKİNLİK SAYISI & SIRALAMA DROPDOWN ---
              LayoutBuilder(
                builder: (context, constraints) {
                  final displayEvents = _getFilteredAndSortedEvents(eventProvider.events);
                  final isWide = constraints.maxWidth > 850;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                eventProvider.selectedCategoryId != null
                                    ? 'Filtrelenen Etkinlikler'
                                    : 'Tüm Etkinlikler',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0066FF).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '${displayEvents.length} Etkinlik',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0066FF),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              // MOBİL İÇİN PREMİUM FİLTRELE BUTONU (STUNNING GRADIENT & BADGE)
                              if (!isWide) ...[
                                Builder(
                                  builder: (context) {
                                    int filterCount = 0;
                                    if (_selectedDateFilter != 'Tüm Tarihler') filterCount++;
                                    if (_selectedVenues.isNotEmpty) filterCount += _selectedVenues.length;
                                    if (_priceRange.start > 0 || _priceRange.end < 5000) filterCount++;

                                    return Container(
                                      height: 42,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0066FF), Color(0xFF4F46E5)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.transparent,
                                              builder: (_) => Container(
                                                height: MediaQuery.of(context).size.height * 0.85,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                                ),
                                                padding: const EdgeInsets.all(16),
                                                child: SingleChildScrollView(
                                                  child: _buildFilterSidebar(context, eventProvider.events),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.tune_rounded, size: 18, color: Colors.white),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Filtrele',
                                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                                ),
                                                if (filterCount > 0) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.all(5),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.amber,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Text(
                                                      '$filterCount',
                                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                              ],

                              // --- üst sıralama dropdown menüsü ---
                              PopupMenuButton<String>(
                                color: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                offset: const Offset(0, 48),
                                onSelected: (String val) {
                                  setState(() => _sortBy = val);
                                },
                                itemBuilder: (BuildContext ctx) {
                                  return [
                                    'Öne Çıkanlar',
                                    'En Yeniler',
                                    'Tarihe Göre',
                                    'Fiyat (Artan)',
                                    'Fiyat (Azalan)',
                                    'Popülerlik',
                                  ].map((opt) {
                                    final isSelected = _sortBy == opt;
                                    return PopupMenuItem<String>(
                                      value: opt,
                                      child: Row(
                                        children: [
                                          Text(
                                            opt,
                                            style: TextStyle(
                                              color: isSelected ? const Color(0xFF0066FF) : Colors.black87,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const Spacer(),
                                            const Icon(Icons.check_rounded, color: Color(0xFF0066FF), size: 18),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.swap_vert_rounded, color: Color(0xFF00C853), size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        _sortBy,
                                        style: GoogleFonts.outfit(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- SPLIT LAYOUT: SOL FİLTRELEME PANELİ + SAĞ ETKİNLİK GRİDİ ---
                      if (eventProvider.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SOL FİLTRELEME PANELİ (MASAÜSTÜ / WEB İÇİN - HER ZAMAN GÖRÜNÜR)
                            if (isWide) ...[
                              _buildFilterSidebar(context, eventProvider.events),
                              const SizedBox(width: 24),
                            ],

                            // SAĞ İÇERİK: YA ETKİNLİK GRİDİ YA DA BOŞ DURUM MESAJI
                            Expanded(
                              child: displayEvents.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.search_off_rounded, size: 60, color: Colors.black26),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Aramanızla veya filtrelerinizle eşleşen etkinlik bulunamadı.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Farklı bir fiyat aralığı, mekan veya kategori seçmeyi deneyebilirsiniz.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                                          ),
                                          const SizedBox(height: 20),
                                          // filtreleri temizle sıfırlama butonu
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0066FF),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            ),
                                            icon: const Icon(Icons.refresh_rounded, size: 18),
                                            label: Text(
                                              'Filtreleri Temizle',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                                _selectedDateFilter = 'Tüm Tarihler';
                                                _selectedVenues.clear();
                                                _priceRange = const RangeValues(0, 5000);
                                              });
                                              eventProvider.selectCategory(null);
                                            },
                                          ),
                                        ],
                                      ),
                                    )
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isWide
                                            ? (constraints.maxWidth > 1200 ? 3 : 2)
                                            : (constraints.maxWidth > 600 ? 2 : 1),
                                        crossAxisSpacing: 18,
                                        mainAxisSpacing: 18,
                                        childAspectRatio: 0.85,
                                      ),
                                      itemCount: displayEvents.length,
                                      itemBuilder: (context, index) {
                                        final event = displayEvents[index];
                                        return _buildModernEventCard(context, event, authProvider, eventProvider);
                                      },
                                    ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ÖNE ÇIKAN HERO BANNER WİDGET ---
  Widget _buildHeroBanner(
    BuildContext context,
    EventModel event,
    AuthProvider authProvider,
    EventProvider eventProvider,
  ) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Arka Plan Görseli
            Positioned.fill(
              child: event.image != null
                  ? Image.network(
                      event.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFF0066FF)),
                    )
                  : Container(color: const Color(0xFF0066FF)),
            ),
            // Gradient Dark Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            // Rozet & İçerik
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          'EN YAKIN ETKİNLİK',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    event.title,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${event.locationName}, ${event.city}',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR').format(event.startDatetime),
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(eventId: event.id),
                            ),
                          );
                        },
                        child: Text(
                          event.isFree ? 'Ücretsiz Katıl' : 'Bilet Al',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: IconButton(
                          icon: Icon(
                            event.isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: event.isFavorited ? Colors.redAccent : Colors.white,
                          ),
                          onPressed: () async {
                            if (!authProvider.isAuthenticated) {
                              _showAuthRequiredDialog(context, 'Favorilere eklemek');
                            } else {
                              await eventProvider.toggleFavorite(event);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // --- MODERN BİLETİX ETKİNLİK KARTI ---
  Widget _buildModernEventCard(
    BuildContext context,
    EventModel event,
    AuthProvider authProvider,
    EventProvider eventProvider,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: event.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim Alanı & Rozetler
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: event.image != null
                          ? Image.network(
                              event.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Image.network(
                        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.network(
                      'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=800&q=80',
                      fit: BoxFit.cover,
                    ),
                    ),
                  ),

                  // Kategori Rozeti (Sol Üst)
                  if (event.category != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.category!.name,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Favori Butonu (Sağ Üst)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          event.isFavorited ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: event.isFavorited ? Colors.redAccent : Colors.black87,
                        ),
                        onPressed: () async {
                          if (!authProvider.isAuthenticated) {
                            _showAuthRequiredDialog(context, 'Favorilere eklemek');
                          } else {
                            await eventProvider.toggleFavorite(event);
                          }
                        },
                      ),
                    ),
                  ),

                  // Fiyat Rozeti (Sağ Alt)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: event.isFree ? Colors.green.shade600 : const Color(0xFF0066FF),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Text(
                        event.isFree ? 'ÜCRETSİZ' : '₺${event.price}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // İçerik Detay Alanı
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${event.locationName}, ${event.city}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF0066FF)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM - HH:mm', 'tr_TR').format(event.startDatetime),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0066FF),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${event.participantCount} Katılımcı',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- canlı filtreleme ve sıralama motoru ---
  List<EventModel> _getFilteredAndSortedEvents(List<EventModel> events) {
    var list = events.where((e) {
      if (e.price < _priceRange.start || e.price > _priceRange.end) {
        return false;
      }

      if (_selectedVenues.isNotEmpty && !_selectedVenues.contains(e.locationName)) {
        return false;
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final tomorrowEnd = todayStart.add(const Duration(days: 2));
      final weekEnd = todayStart.add(const Duration(days: 7));

      if (_selectedDateFilter == 'Bugün') {
        if (e.startDatetime.isBefore(todayStart) || e.startDatetime.isAfter(todayEnd)) return false;
      } else if (_selectedDateFilter == 'Yarın') {
        if (e.startDatetime.isBefore(todayEnd) || e.startDatetime.isAfter(tomorrowEnd)) return false;
      } else if (_selectedDateFilter == 'Bu Hafta') {
        if (e.startDatetime.isBefore(todayStart) || e.startDatetime.isAfter(weekEnd)) return false;
      }

      return true;
    }).toList();

    if (_sortBy == 'En Yeniler') {
      list.sort((a, b) => b.id.compareTo(a.id));
    } else if (_sortBy == 'Tarihe Göre') {
      list.sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
    } else if (_sortBy == 'Fiyat (Artan)') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Fiyat (Azalan)') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Popülerlik') {
      list.sort((a, b) => b.participantCount.compareTo(a.participantCount));
    }

    return list;
  }

  // --- sol filtreleme paneli (bubilet stil) ---
  Widget _buildFilterSidebar(BuildContext context, List<EventModel> allEvents) {
    final venueCounts = <String, int>{};
    for (var e in allEvents) {
      if (e.locationName.isNotEmpty) {
        venueCounts[e.locationName] = (venueCounts[e.locationName] ?? 0) + 1;
      }
    }

    final filteredVenueList = venueCounts.keys.where((v) {
      if (_venueSearchQuery.isEmpty) return true;
      return v.toLowerCase().contains(_venueSearchQuery.toLowerCase());
    }).toList();

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrele',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (_selectedDateFilter != 'Tüm Tarihler' || _priceRange != const RangeValues(0, 5000) || _selectedVenues.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateFilter = 'Tüm Tarihler';
                      _priceRange = const RangeValues(0, 5000);
                      _selectedVenues.clear();
                    });
                  },
                  child: Text(
                    'Temizle',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // 1. TARİH FİLTRESİ
          Text('Tarih', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Tüm Tarihler', 'Bugün', 'Yarın', 'Bu Hafta'].map((d) {
              final isSel = _selectedDateFilter == d;
              return ChoiceChip(
                label: Text(d, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                selected: isSel,
                selectedColor: const Color(0xFF0066FF).withValues(alpha: 0.15),
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(color: isSel ? const Color(0xFF0066FF) : Colors.black87),
                onSelected: (val) {
                  if (val) setState(() => _selectedDateFilter = d);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // 2. FİYAT ARALIĞI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fiyat Aralığı', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              Text(
                '₺${_priceRange.start.toInt()} - ₺${_priceRange.end.toInt()}',
                style: GoogleFonts.inter(color: const Color(0xFF0066FF), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: const Color(0xFF00C853), // Bubilet Yeşil Accent
            inactiveColor: Colors.grey.shade200,
            labels: RangeLabels('₺${_priceRange.start.toInt()}', '₺${_priceRange.end.toInt()}'),
            onChanged: (RangeValues vals) {
              setState(() => _priceRange = vals);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 ₺', style: GoogleFonts.inter(color: Colors.black38, fontSize: 11)),
              Text('5.000 ₺', style: GoogleFonts.inter(color: Colors.black38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // 3. MEKAN FİLTRESİ
          Text('Mekan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            onChanged: (val) => setState(() => _venueSearchQuery = val),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Mekan ara...',
              hintStyle: GoogleFonts.inter(color: Colors.black38, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredVenueList.length,
              itemBuilder: (ctx, idx) {
                final venue = filteredVenueList[idx];
                final isChecked = _selectedVenues.contains(venue);
                final count = venueCounts[venue] ?? 0;
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    venue,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Text('$count', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ),
                  value: isChecked,
                  activeColor: const Color(0xFF0066FF),
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        _selectedVenues.add(venue);
                      } else {
                        _selectedVenues.remove(venue);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
