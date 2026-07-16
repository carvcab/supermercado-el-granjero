import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'theme.dart';
import 'services/firestore_service.dart';
import 'services/notifications.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Firebase.initializeApp(); } catch (_) {}
  await Fb.init();
  await Notif.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  static const green = Color(0xFF1b4d3e);
  static const darkBlue = Color(0xFF073155);
  static const bg = Color(0xFFeae5db);
  static final ValueNotifier<bool> darkMode = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkMode,
      builder: (_, isDark, __) {
        Tema.isDark = isDark;
        return MaterialApp(
          title: 'El Granjero',
          debugShowCheckedModeBanner: false,
          theme: Tema.theme,
          darkTheme: Tema.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const LoginScreen(),
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _user = TextEditingController(), _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _remember = false;
  String? _savedPhoto;
  String? _savedName;

  late final AnimationController _entranceController;
  late final AnimationController _particleController;
  late final AnimationController _logoScaleController;
  late final AnimationController _shakeController;
  late final AnimationController _eyeController;

  late final Animation<double> _logoFadeSlide;
  late final Animation<double> _titleFadeSlide;
  late final Animation<double> _cardFadeSlide;
  late final Animation<double> _logoScaleAnim;
  late final Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _logoScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _eyeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _logoScaleAnim = CurvedAnimation(parent: _logoScaleController, curve: Curves.elasticOut);

    _logoFadeSlide = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.35, curve: Curves.easeOut)));
    _titleFadeSlide = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.15, 0.55, curve: Curves.easeOut)));
    _cardFadeSlide = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.35, 0.85, curve: Curves.easeOut)));

    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.06, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.06, 0), end: const Offset(-0.06, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.06, 0), end: const Offset(0.04, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.04, 0), end: const Offset(-0.04, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.04, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceController.forward();
      _logoScaleController.forward();
    });
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember') ?? false;
    if (remember) {
      final savedUser = prefs.getString('username');
      final savedPass = prefs.getString('password');
      final savedPhoto = prefs.getString('photo');
      final savedName = prefs.getString('nombre');
      if (savedUser != null) _user.text = savedUser;
      if (savedPass != null) _pass.text = savedPass;
      _savedPhoto = savedPhoto;
      _savedName = savedName;
    }
    if (mounted) setState(() => _remember = remember);
  }

  void _clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.remove('photo');
    await prefs.remove('nombre');
    await prefs.setBool('remember', false);
    _user.clear();
    _pass.clear();
    setState(() {
      _remember = false;
      _savedPhoto = null;
      _savedName = null;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember', _remember);
    if (_remember) {
      final username = _user.text.trim();
      await prefs.setString('username', username);
      await prefs.setString('password', _pass.text.trim());
      try {
        final usuarios = await Fb.getList('usuarios');
        final match = usuarios.cast<Map?>().firstWhere(
          (u) => (u?['username']?.toString() ?? '') == username,
          orElse: () => null,
        );
        if (match != null) {
          final foto = match['foto']?.toString() ?? '';
          final nombre = match['nombre_completo']?.toString() ?? match['nombre']?.toString() ?? '';
          if (foto.isNotEmpty) await prefs.setString('photo', foto);
          if (nombre.isNotEmpty) await prefs.setString('nombre', nombre);
          _savedPhoto = foto.isNotEmpty ? foto : null;
          _savedName = nombre.isNotEmpty ? nombre : null;
        }
      } catch (_) {}
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('photo');
      await prefs.remove('nombre');
    }
  }

  void _toggleObscure() {
    if (_obscure) { _eyeController.forward(); } else { _eyeController.reverse(); }
    setState(() => _obscure = !_obscure);
  }

  void _triggerShake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
  }

  void _login() async {
    final rawUser = _user.text.trim();
    final password = _pass.text.trim();
    if (rawUser.isEmpty || password.isEmpty) return;
    setState(() => _loading = true);
    String step = 'inicio';
    try {
      // ---- PASO 1: Asegurar que Firebase esté inicializado ----
      step = 'firebase_init';
      try {
        await Firebase.initializeApp();
      } catch (_) {
        // Ya estaba inicializado, está bien
      }

      // ---- PASO 2: Autenticarse en Firebase (necesario para leer Firestore) ----
      step = 'firebase_auth';
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // No hay usuario logueado, intentar autenticarse
        bool authOk = false;

        // Intento 1: Login anónimo
        if (!authOk) {
          try {
            await FirebaseAuth.instance.signInAnonymously();
            authOk = true;
          } catch (_) {}
        }

        // Intento 2: Login con cuenta fija del POS
        if (!authOk) {
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: 'pos-client@elgranjero.com',
              password: 'granjeroclient123!',
            );
            authOk = true;
          } catch (_) {}
        }

        // Intento 3: Crear la cuenta fija del POS
        if (!authOk) {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: 'pos-client@elgranjero.com',
              password: 'granjeroclient123!',
            );
            authOk = true;
          } catch (_) {}
        }

        // Si ninguno funcionó, seguir de todas formas (las reglas de Firestore 
        // permiten lectura pública de usuarios)
      }

      // ---- PASO 3: Limpiar caché local y leer lista de usuarios de Firestore ----
      step = 'firestore_fetch';
      try {
        await Fb.clearCache('usuarios');
        await Fb.clearCache('roles');
      } catch (_) {}
      final usuarios = await Fb.getList('usuarios');

      if (usuarios.isEmpty) {
        throw Exception(
          'No se pudo obtener la lista de usuarios. '
          'Verifica tu conexión a internet e intenta de nuevo.'
        );
      }

      // ---- PASO 4: Buscar el usuario ingresado ----
      step = 'user_match';
      final input = rawUser.toLowerCase();
      Map? match;
      for (final u in usuarios) {
        final uname = (u['username']?.toString() ?? '').toLowerCase();
        final uemail = (u['email']?.toString() ?? '').toLowerCase();
        if (uname == input || uemail == input) {
          match = u;
          break;
        }
      }

      if (match == null) {
        // Construir lista de usuarios disponibles para debug
        final available = usuarios
            .whereType<Map>()
            .map((u) => u['username']?.toString() ?? '?')
            .join(', ');
        throw Exception(
          'Usuario "$rawUser" no encontrado. '
          'Usuarios disponibles: $available'
        );
      }

      // ---- PASO 5: Validar contraseña ----
      step = 'password_check';
      final storedPass = (match['password']?.toString() ?? '').trim();
      if (storedPass.isEmpty) {
        throw Exception(
          'El usuario "${match['username']}" no tiene contraseña configurada en el sistema.'
        );
      }
      if (storedPass != password) {
        throw Exception('Contraseña incorrecta para "${match['username']}"');
      }

      // ---- PASO 6: Cargar permisos y guardar sesion ----
      step = 'permisos';
      Session.loadPermisos();
      // Also load roles to resolve permissions from user's role as fallback
      List<Map<dynamic, dynamic>> roles = [];
      try { roles = await Fb.getList('roles'); } catch (_) {}
      Session.setUser(match, roles);
      final debugPermIds = match['permiso_ids'];
      final debugPermKeys = Session.permKeys;
      debugPrint('[Login] user=${match['username']}, rol=${match['rol']}, permiso_ids=$debugPermIds, resolved=${debugPermKeys.length} keys: $debugPermKeys');

      // ---- PASO 7: Guardar credenciales y navegar ----
      step = 'navigate';
      await _saveCredentials();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _triggerShake();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('[$step] $e', maxLines: 5),
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _entranceController.dispose();
    _particleController.dispose();
    _logoScaleController.dispose();
    _shakeController.dispose();
    _eyeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _particleController,
        builder: (_, __) {
          final t = _particleController.value * 2 * pi;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0a2a1a), Color(0xFF0d3b28), Color(0xFF0a2a1a), Color(0xFF062018)],
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(size: Size.infinite, painter: ParticlePainter(t)),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogo(),
                          SizedBox(height: 16),
                          _buildTitle(),
                          if (_hasSavedUser) ...[
                            SizedBox(height: 24),
                            _buildSavedUserCard(),
                          ],
                          SizedBox(height: 32),
                          _buildCard(),
                          SizedBox(height: 20),
                          Text('v1.1.2',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(80),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    final hasPhoto = _savedPhoto != null && _savedPhoto!.isNotEmpty;
    final initial = (_savedName != null && _savedName!.isNotEmpty)
        ? _savedName![0].toUpperCase()
        : (_user.text.isNotEmpty ? _user.text[0].toUpperCase() : 'G');
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _logoScaleController]),
      builder: (_, __) {
        final fade = _logoFadeSlide.value;
        final scale = _logoScaleAnim.value;
        Widget avatar;
        if (hasPhoto && _savedPhoto!.startsWith('data:')) {
          avatar = CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withAlpha(25),
            backgroundImage: MemoryImage(base64Decode(_savedPhoto!.split(',')[1])),
          );
        } else if (hasPhoto && (_savedPhoto!.startsWith('http'))) {
          avatar = CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withAlpha(25),
            backgroundImage: NetworkImage(_savedPhoto!),
          );
        } else {
          avatar = Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
              boxShadow: [BoxShadow(color: App.green.withAlpha(70), blurRadius: 24, spreadRadius: 3)],
            ),
            child: Center(
              child: hasPhoto
                  ? Text(initial, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))
                  : const Icon(Icons.store, size: 42, color: Colors.white),
            ),
          );
        }
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - fade)),
            child: Transform.scale(scale: scale, child: avatar),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, __) {
        final fade = _titleFadeSlide.value;
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - fade)),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFF8DC), Color(0xFFFFC000), Color(0xFFFFD700)],
                stops: [0.0, 0.35, 0.65, 1.0],
              ).createShader(bounds),
              child: const Column(
                children: [
                  Text('El Granjero',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                  SizedBox(height: 4),
                  Text('Sistema POS v1.1.2',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70, letterSpacing: 3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool get _hasSavedUser => _user.text.isNotEmpty && _remember;

  Widget _buildSavedUserCard() {
    final initial = (_savedName != null && _savedName!.isNotEmpty)
        ? _savedName![0].toUpperCase()
        : _user.text[0].toUpperCase();
    final displayName = _savedName ?? _user.text;
    ImageProvider? photoProvider;
    if (_savedPhoto != null && _savedPhoto!.startsWith('data:')) {
      photoProvider = MemoryImage(base64Decode(_savedPhoto!.split(',')[1]));
    } else if (_savedPhoto != null && (_savedPhoto!.startsWith('http'))) {
      photoProvider = NetworkImage(_savedPhoto!);
    }

    return AnimatedBuilder(
      animation: _cardFadeSlide,
      builder: (_, __) {
        final fade = _cardFadeSlide.value;
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - fade)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(30), width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withAlpha(30),
                        backgroundImage: photoProvider,
                        child: photoProvider == null
                            ? Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
                            : null,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            SizedBox(height: 2),
                            Text('@${_user.text}', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(150))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearSavedCredentials,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withAlpha(40)),
                          ),
                          child: Text('No eres tu?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withAlpha(200))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, __) {
        final fade = _cardFadeSlide.value;
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - fade)),
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (_, __) {
                final offset = _shakeAnim.value * MediaQuery.of(context).size.width;
                return Transform.translate(
                  offset: offset,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withAlpha(40), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 30, offset: const Offset(0, 12)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTextField(
                              controller: _user,
                              hint: 'Usuario',
                              icon: Icons.person_outline,
                              onSubmitted: (_) => _login(),
                            ),
                            SizedBox(height: 14),
                            _buildTextField(
                              controller: _pass,
                              hint: 'Contraseña',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              suffix: _buildEyeToggle(),
                              onSubmitted: (_) => _login(),
                            ),
                            SizedBox(height: 12),
                            _buildRememberToggle(),
                            SizedBox(height: 26),
                            _buildLoginButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: App.green,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withAlpha(110)),
        filled: true,
        fillColor: Colors.white.withAlpha(12),
        prefixIcon: Icon(icon, color: Colors.white.withAlpha(160)),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withAlpha(30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: App.green.withAlpha(200), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildEyeToggle() {
    return GestureDetector(
      onTap: _toggleObscure,
      child: AnimatedBuilder(
        animation: _eyeController,
        builder: (_, __) {
          final t = _eyeController.value;
          return Transform.scale(
            scale: 0.8 + 0.2 * t,
            child: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white.withAlpha(160),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRememberToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Recordar contraseña',
          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14)),
        GestureDetector(
          onTap: () => setState(() => _remember = !_remember),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 48,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: _remember ? App.green : Colors.white.withAlpha(40),
              border: Border.all(color: _remember ? App.green : Colors.white.withAlpha(80)),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: _remember ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : () { HapticFeedback.lightImpact(); _login(); },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(20)),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _loading
                  ? [Colors.grey.shade600, Colors.grey.shade700, Colors.grey.shade800]
                  : const [Color(0xFF2d7a5f), App.green, Color(0xFF144d38)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _loading
                ? []
                : [BoxShadow(color: App.green.withAlpha(100), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: _loading
                ? SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Iniciar Sesión',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double time;
  ParticlePainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha(6);
    const count = 40;

    for (int i = 0; i < count; i++) {
      final baseX = (i * 0.137 + 0.05) % 1.0;
      final baseY = (i * 0.287 + 0.03) % 1.0;
      final x = (baseX * size.width + sin(time * 1.3 + i * 0.8) * 18) % size.width;
      final y = (baseY * size.height + cos(time * 1.7 + i * 0.6) * 14) % size.height;
      final radius = 1.0 + sin(time * 2.5 + i) * 0.6;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => oldDelegate.time != time;
}

