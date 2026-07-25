import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'calendar/calendar_screen.dart';
import 'profile/profile_screen.dart';
import 'organizer/create_event_screen.dart';
import 'admin/admin_panel_screen.dart';
import 'auth/login_register_screen.dart';

//giriş yapan kişinin rolünü kontrol eder.

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;



  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOrganizer = authProvider.isOrganizer;
    final user = authProvider.currentUser;
    final isAdmin = user?.isAdmin ?? false;

    // --- EĞER ADMİN GİRİŞİ YAPILMIŞSA: ADMİNE ÖZEL TAM YÖNETİM DÜZENİ ---
    if (isAdmin) {
      final List<Widget> adminPages = [
        const AdminPanelScreen(),
        const CreateEventScreen(),
      ];

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: AppBar(
            backgroundColor: const Color(0xFF1E293B), // Admne Özel Koyu Slate Konsol Teması
            elevation: 4,
            automaticallyImplyLeading: false,
            title: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.amberAccent, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'etkinlik',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade400,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ADMİN KONSOLU',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),

                  // ADMİNE ÖZEL MENÜ BUTONLARI
                  _buildTopNavButton(
                    title: 'Etkinlik Yönetimi',
                    icon: Icons.dashboard_outlined,
                    index: 0,
                  ),
                  const SizedBox(width: 8),
                  _buildTopNavButton(
                    title: 'Yeni Etkinlik Ekle',
                    icon: Icons.add_circle_outline,
                    index: 1,
                  ),
                ],
              ),
            ),
            actions: [
              // SAĞ ÜST ADMİN ÇIKIŞ MENÜSÜ
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  offset: const Offset(0, 45),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      final messenger = ScaffoldMessenger.of(context);
                      await authProvider.logout();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Admin oturumu kapatıldı.')),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        'Yönetici: ${user?.username}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    const PopupMenuDivider(),
                    _buildMenuItem(
                      value: 'logout',
                      icon: Icons.logout_rounded,
                      text: 'Çıkış Yap',
                      color: Colors.redAccent,
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined, color: Colors.amberAccent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Admin (${user?.username})',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex < adminPages.length ? _selectedIndex : 0,
          children: adminPages,
        ),
      );
    }

    // --- KULLANICI / ORGANİZATÖR DÜZENİ ---
    final List<Widget> pages = [
      const HomeScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
      if (isOrganizer) const CreateEventScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF0066FF), 
          elevation: 3,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              // Logo
              InkWell(
                onTap: () => setState(() => _selectedIndex = 0),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 26),
                    const SizedBox(width: 8),
                    Text(
                      'etkinlik',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),

              // KULLANICI ÜST MENÜ BUTONLARI
              _buildTopNavButton(
                title: 'Keşfet',
                icon: Icons.explore_outlined,
                index: 0,
              ),
              const SizedBox(width: 6),
              _buildTopNavButton(
                title: 'Takvim',
                icon: Icons.calendar_month_outlined,
                index: 1,
              ),
              const SizedBox(width: 6),
              _buildTopNavButton(
                title: 'Profilim',
                icon: Icons.person_outline,
                index: 2,
              ),
              if (isOrganizer) ...[
                const SizedBox(width: 6),
                _buildTopNavButton(
                  title: 'Etkinlik Ekle',
                  icon: Icons.add_circle_outline,
                  index: 3,
                ),
              ],
            ],
          ),
          actions: [
            //HESABIM DROPDOWN MENÜSÜ
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PopupMenuButton<String>(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                offset: const Offset(0, 45),
                onSelected: (value) async { 
                  if (value == 'login') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginRegisterScreen(initialIsRegister: false)),
                    );
                  } else if (value == 'register') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginRegisterScreen(initialIsRegister: true)),
                    );
                  } else if (value == 'profile') {
                    setState(() => _selectedIndex = 2);
                  } else if (value == 'calendar') {
                    setState(() => _selectedIndex = 1);
                  } else if (value == 'create') {
                    setState(() => _selectedIndex = 3);
                  } else if (value == 'logout') {
                    final messenger = ScaffoldMessenger.of(context);
                    await authProvider.logout();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Çıkış yapıldı.')),
                      );
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  if (!authProvider.isAuthenticated) { //giriş yapıp yapmadığını kontrol eder
                    return [
                      _buildMenuItem( //yapılmamışsa
                        value: 'login',
                        icon: Icons.login_rounded,
                        text: 'Giriş Yap',
                        color: Colors.black87,
                      ),
                      _buildMenuItem(
                        value: 'register',
                        icon: Icons.person_add_alt_1_rounded,
                        text: 'Hesap Oluştur',
                        color: const Color(0xFF0066FF),
                      ),
                    ];
                  } else {
                    return [
                      _buildMenuItem(  //yapılmışsa
                        value: 'profile',
                        icon: Icons.person_rounded,
                        text: 'Profilim (${user?.username ?? ''})',
                        color: Colors.black87,
                      ),
                      _buildMenuItem(
                        value: 'calendar',
                        icon: Icons.calendar_month_rounded,
                        text: 'Takvimim',
                        color: Colors.black87,
                      ),
                      const PopupMenuDivider(),
                      _buildMenuItem(
                        value: 'logout',
                        icon: Icons.logout_rounded,
                        text: 'Çıkış Yap',
                        color: Colors.redAccent,
                      ),
                    ];
                  }
                },
                child: Container( 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text( //giriş yaptıysa adı yapmadıysa hesabım
                        authProvider.isAuthenticated ? (user?.username ?? 'Hesabım') : 'Hesabım',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex < pages.length ? _selectedIndex : 0,
        children: pages,
      ),
    );
  }

  Widget _buildTopNavButton({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white54) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
