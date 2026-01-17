import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

/// Login Ekranı - Premium Dark Theme + Glassmorphism
/// Supabase Native Auth ile Google OAuth ve E-posta giriş
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showEmailLogin = false;
  bool _obscurePassword = true;

  // Animasyon
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.signInWithGoogle();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Mor Glow Efektleri (Arka Plan)
          _buildGlowEffects(),

          // Ana İçerik
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        _buildLogo(),
                        const SizedBox(height: 48),

                        // Auth İçeriği
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.isLoading) {
                              return _buildLoadingState();
                            }

                            return Column(
                              children: [
                                // Hata mesajı
                                if (auth.error != null)
                                  _buildErrorCard(auth.error!),

                                // Google ile Giriş veya E-posta Giriş
                                if (!_showEmailLogin) ...[
                                  _buildGoogleButton(auth),
                                  const SizedBox(height: 20),
                                  _buildDivider(),
                                  const SizedBox(height: 20),
                                  _buildEmailToggleButton(),
                                ],

                                // E-posta Giriş Formu
                                if (_showEmailLogin) _buildEmailForm(),

                                const SizedBox(height: 32),

                                // Kayıt ol linki
                                _buildRegisterLink(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mor Glow Efektleri
  Widget _buildGlowEffects() {
    return Stack(
      children: [
        // Üst mor glow
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Alt sağ turuncu glow
        Positioned(
          bottom: -50,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF97316).withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Orta mor glow
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: -120,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Logo ve Başlık
  Widget _buildLogo() {
    return Column(
      children: [
        // Logo Container with Glassmorphism
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
            ).createShader(bounds),
            child: const Icon(
              Icons.people_alt_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // App Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
          ).createShader(bounds),
          child: const Text(
            'Vibe',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yeni arkadaşlar edin',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Loading durumu
  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
          child: const CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Bağlanılıyor...',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  /// Hata kartı
  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Google ile Giriş Butonu
  Widget _buildGoogleButton(AuthProvider auth) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              height: 24,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Google ile Giriş Yap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// Ayraç
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.white.withOpacity(0.2)],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// E-posta Toggle Butonu
  Widget _buildEmailToggleButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _showEmailLogin = true),
        icon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.8)),
        label: Text(
          'E-posta ile Giriş',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  /// E-posta Giriş Formu
  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Geri butonu
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showEmailLogin = false),
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white.withOpacity(0.7),
                size: 18,
              ),
              label: Text(
                'Geri',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // E-posta alanı - Glassmorphism
          _buildGlassTextField(
            controller: _emailController,
            label: 'E-posta',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'E-posta gerekli';
              if (!value.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Şifre alanı - Glassmorphism
          _buildGlassTextField(
            controller: _passwordController,
            label: 'Şifre',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white.withOpacity(0.5),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Şifre gerekli';
              if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Giriş butonu - Gradient
          _buildGradientButton(text: 'Giriş Yap', onPressed: _signInWithEmail),
        ],
      ),
    );
  }

  /// Glassmorphism TextField
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
          suffixIcon: suffixIcon,
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
          ),
          errorStyle: TextStyle(color: Colors.red.shade300),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: validator,
      ),
    );
  }

  /// Gradient Buton
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Kayıt ol linki
  Widget _buildRegisterLink() {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/register'),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          children: [
            const TextSpan(text: 'Hesabınız yok mu? '),
            TextSpan(
              text: 'Kayıt olun',
              style: TextStyle(
                color: const Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF8B5CF6).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
