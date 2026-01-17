import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_provider.dart';

/// Kayıt Ekranı - Premium Dark Theme + Glassmorphism
/// Supabase Native Auth ile E-posta kayıt
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _profilePhoto;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Animasyon
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _profilePhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);

    print('🚀 Kayıt formu gönderiliyor...');

    final success = await auth.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      print('✅ Kayıt başarılı, ana sayfaya yönlendiriliyor...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Kayıt başarılı! Hoşgeldiniz.'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print('❌ Kayıt başarısız: ${auth.error}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(auth.error ?? 'Kayıt başarısız')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Mor Glow Efektleri
          _buildGlowEffects(),

          // Ana İçerik
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Geri butonu
                        _buildBackButton(),
                        const SizedBox(height: 20),

                        // Başlık
                        _buildHeader(),
                        const SizedBox(height: 32),

                        // Profil Fotoğrafı
                        _buildProfilePhoto(),
                        const SizedBox(height: 32),

                        // Form Alanları
                        _buildFormFields(),
                        const SizedBox(height: 24),

                        // Hata Mesajı
                        if (auth.error != null) _buildErrorMessage(auth.error!),

                        // Kayıt Butonu
                        _buildRegisterButton(auth.isLoading),
                        const SizedBox(height: 24),

                        // Giriş Yap Linki
                        _buildLoginLink(),
                        const SizedBox(height: 20),
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

  /// Mor/Turuncu Glow Efektleri
  Widget _buildGlowEffects() {
    return Stack(
      children: [
        // Üst sol mor glow
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Alt sağ turuncu glow
        Positioned(
          bottom: 100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF97316).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Orta mor glow
        Positioned(
          top: MediaQuery.of(context).size.height * 0.5,
          left: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Geri butonu
  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          iconSize: 20,
        ),
      ),
    );
  }

  /// Başlık
  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
          ).createShader(bounds),
          child: const Text(
            'Hesap Oluştur',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yeni arkadaşlar edinmeye başla',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// Profil Fotoğrafı
  Widget _buildProfilePhoto() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 120,
          height: 120,
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
              color: _profilePhoto != null
                  ? const Color(0xFF8B5CF6)
                  : Colors.white.withOpacity(0.2),
              width: 2,
            ),
            image: _profilePhoto != null
                ? DecorationImage(
                    image: FileImage(_profilePhoto!),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _profilePhoto == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFF97316)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fotoğraf Ekle',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  /// Form Alanları
  Widget _buildFormFields() {
    return Column(
      children: [
        // Ad ve Soyad yan yana
        Row(
          children: [
            Expanded(
              child: _buildGlassTextField(
                controller: _firstNameController,
                label: 'Ad',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ad gerekli';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassTextField(
                controller: _lastNameController,
                label: 'Soyad',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Soyad gerekli';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // E-posta
        _buildGlassTextField(
          controller: _emailController,
          label: 'E-posta',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'E-posta gerekli';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Şifre
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
        const SizedBox(height: 16),

        // Şifre Tekrarı
        _buildGlassTextField(
          controller: _confirmPasswordController,
          label: 'Şifre Tekrarı',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.white.withOpacity(0.5),
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Şifreler eşleşmiyor';
            }
            return null;
          },
        ),
      ],
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
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.4),
            size: 22,
          ),
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
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          errorStyle: TextStyle(color: Colors.red.shade300, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  /// Hata Mesajı
  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Kayıt Butonu - Gradient
  Widget _buildRegisterButton(bool isLoading) {
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
        onPressed: isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Kayıt Ol',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  /// Giriş Yap Linki
  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: 'Zaten hesabınız var mı? '),
              TextSpan(
                text: 'Giriş yapın',
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
      ),
    );
  }
}
