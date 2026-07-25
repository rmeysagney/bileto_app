import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

class LoginRegisterScreen extends StatefulWidget {
  final bool initialIsRegister;

  const LoginRegisterScreen({
    super.key,
    this.initialIsRegister = false,
  });

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  //hesap oluştura tıklandıys true
  late bool _isRegisterMode; 
  bool _isAdminMode = false;

  // Login Form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Admin Login Form
  final _adminFormKey = GlobalKey<FormState>();
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  // Register Form
  final _registerFormKey = GlobalKey<FormState>();
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regPasswordConfirmController = TextEditingController();
  final _regFirstNameController = TextEditingController();
  final _regLastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regPasswordConfirmController.dispose();
    _regFirstNameController.dispose();
    _regLastNameController.dispose();
    super.dispose();
  }
//giriş yapma işlemi
  void _handleLogin({bool isAdminLogin = false}) async {
    final formKey = isAdminLogin ? _adminFormKey : _loginFormKey;
    final usernameController = isAdminLogin ? _adminUsernameController : _loginUsernameController;
    final passwordController = isAdminLogin ? _adminPasswordController : _loginPasswordController;

    if (formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAdminLogin ? 'Admin Girişi Başarılı! Konsola yönlendiriliyorsunuz.' : 'Giriş başarılı! Hoş geldiniz.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Giriş yapılamadı.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

//kayıt olma işlemi
  void _handleRegister() async {
    if (_registerFormKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.register(
        username: _regUsernameController.text.trim(),
        email: _regEmailController.text.trim(),
        password: _regPasswordController.text.trim(),
        passwordConfirm: _regPasswordConfirmController.text.trim(),
        role: 'participant',
        firstName: _regFirstNameController.text.trim(),
        lastName: _regLastNameController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isRegisterMode = false;
          _isAdminMode = false;
        });
        _loginUsernameController.text = _regUsernameController.text;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Kayıt başarısız.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: isDesktop ? (_isAdminMode ? const Color(0xFF1E293B) : Colors.black) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDesktop ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isDesktop ? _buildSplitScreenLayout() : _buildMobileLayout(),
    );
  }

  // --- MASAÜSTÜ / WEB SPLIT SCREEN LAYOUT ---
  Widget _buildSplitScreenLayout() {
    return Row(
      children: [
        // SOL TARAF: Görsel Afiş Banner
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      _isAdminMode
                          ? 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?q=80&w=1200'
                          : 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=1200',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (_isAdminMode ? const Color(0xFF0F172A) : Colors.black).withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isAdminMode ? Icons.admin_panel_settings_outlined : Icons.confirmation_number_rounded,
                          color: _isAdminMode ? Colors.amberAccent : Colors.blue,
                          size: 42,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'etkinlik',
                          style: GoogleFonts.outfit(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isAdminMode ? 'Yönetici Kontrol Paneli' : 'Binlerce Etkinlik Seni Bekliyor!',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAdminMode
                          ? 'Sistem yönetici hesabınız ile tüm etkinlikleri organize edin, yayınlayın ve veritabanını yönetin.'
                          : 'Konserlerden tiyatrolara, yazılım kampından atölyelere tüm etkinlikleri keşfet ve yerini hemen ayır.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // SAĞ TARAF: Temiz Minimalist Form
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
            child: Column(
              children: [
                // Sağ Üst Köşe Hesap Oluştur / Giriş Yap Switch Butonu
                if (!_isAdminMode)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _isRegisterMode ? 'Zaten hesabın var mı?' : 'Hesabın yok mu?',
                        style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0066FF),
                          side: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          setState(() => _isRegisterMode = !_isRegisterMode);
                        },
                        child: Text(
                          _isRegisterMode ? 'Giriş Yap' : 'Hesap Oluştur',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                const Spacer(),

                // Form İçeriği
                SizedBox(
                  width: 420,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isAdminMode
                        ? _buildAdminLoginForm()
                        : (_isRegisterMode ? _buildRegisterForm() : _buildLoginForm()),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- MOBİL LAYOUT ---
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'etkinlik',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0066FF),
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (!_isAdminMode)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0066FF),
                    side: const BorderSide(color: Color(0xFF0066FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    setState(() => _isRegisterMode = !_isRegisterMode);
                  },
                  child: Text(
                    _isRegisterMode ? 'Giriş Yap' : 'Kayıt Ol',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),

          _isAdminMode
              ? _buildAdminLoginForm()
              : (_isRegisterMode ? _buildRegisterForm() : _buildLoginForm()),
        ],
      ),
    );
  }

  //giriş yap
  Widget _buildLoginForm() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Giriş Yap',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),

          _buildBiletixTextField(
            controller: _loginUsernameController,
            label: 'Kullanıcı Adı*',
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
          ),
          const SizedBox(height: 16),

          _buildBiletixTextField(
            controller: _loginPasswordController,
            label: 'Şifre*',
            icon: Icons.lock_outline,
            isObscure: true,
            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Şifremi unuttum',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0066FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: authProvider.isLoading ? null : () => _handleLogin(isAdminLogin: false),
              child: authProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Giriş Yap',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // SADE VE GRİ "ADMİN OLARAK GİRİŞ YAP" YAZISI
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                setState(() => _isAdminMode = true);
              },
              icon: Icon(Icons.admin_panel_settings_outlined, size: 16, color: Colors.grey.shade600),
              label: Text(
                'Admin olarak giriş yap',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ÖZEL ADMİN GİRİŞ FORMU ---
  Widget _buildAdminLoginForm() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _adminFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings_outlined, size: 36, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          Text(
            'Admin Girişi',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sistem yönetici hesabınız ile giriş yapın.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 28),

          _buildBiletixTextField(
            controller: _adminUsernameController,
            label: 'Admin Kullanıcı Adı*',
            icon: Icons.admin_panel_settings_outlined,
            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
          ),
          const SizedBox(height: 16),

          _buildBiletixTextField(
            controller: _adminPasswordController,
            label: 'Admin Şifre*',
            icon: Icons.lock_outline,
            isObscure: true,
            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: authProvider.isLoading ? null : () => _handleLogin(isAdminLogin: true),
              child: authProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Admin Paneline Giriş Yap',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // KULLANICI GİRİŞİNE DÖNÜŞ LİNKİ
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
              ),
              onPressed: () {
                setState(() => _isAdminMode = false);
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(
                'Normal Kullanıcı Girişine Dön',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- KAYIT OL FORMU ---
  Widget _buildRegisterForm() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Hesap Oluştur',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          _buildBiletixTextField(
            controller: _regUsernameController,
            label: 'Kullanıcı Adı*',
            icon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
          ),
          const SizedBox(height: 14),

          _buildBiletixTextField(
            controller: _regEmailController,
            label: 'E-posta Adresi*',
            icon: Icons.email_outlined,
            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildBiletixTextField(
                  controller: _regFirstNameController,
                  label: 'Ad',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBiletixTextField(
                  controller: _regLastNameController,
                  label: 'Soyad',
                  icon: Icons.badge_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildBiletixTextField(
            controller: _regPasswordController,
            label: 'Şifre*',
            icon: Icons.lock_outline,
            isObscure: true,
            validator: (v) => v!.length < 6 ? 'En az 6 karakter' : null,
          ),
          const SizedBox(height: 14),

          _buildBiletixTextField(
            controller: _regPasswordConfirmController,
            label: 'Şifre Tekrar*',
            icon: Icons.lock_outline,
            isObscure: true,
            validator: (v) => v != _regPasswordController.text ? 'Şifreler eşleşmiyor' : null,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: authProvider.isLoading ? null : _handleRegister,
              child: authProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Hesap Oluştur',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BİLETİX STİLİ INPUT FIELD ---
  Widget _buildBiletixTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.black87),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black45, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
        ),
      ),
    );
  }
}
