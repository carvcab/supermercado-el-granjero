import 'package:flutter/material.dart';

class Tema {
  static const _bg = Color(0xFFeae5db);
  static bool isDark = false;
  static const _cardBg = Colors.white;
  static const _cardBorder = Color(0xFFe3e0da);
  static const primary = Color(0xFF1b4d3e);
  static const primaryHover = Color(0xFF2c5e43);
  static const _textDark = Color(0xFF232d29);
  static const _textSoft = Color(0xFF5c6660);
  static const _textMuted = Color(0xFF8fa096);
  static const danger = Color(0xFFb2533e);
  static const darkBlue = Color(0xFF073155);
  static const headerGradient = LinearGradient(colors: [primary, primaryHover, primary]);

  static const darkBg = Color(0xFF0f1410);
  static const darkSurface = Color(0xFF1a211a);
  static const darkCardBg = Color(0xFF1e2a1e);
  static const darkCardBorder = Color(0xFF2a3a2a);
  static const darkTextPrimary = Color(0xFFe8e8e0);
  static const darkTextSecondary = Color(0xFFa0a898);
  static const darkTextMuted = Color(0xFF6a7268);
  static const darkAccent = Color(0xFF2c5e43);

  static const radius = 20.0;
  static const radiusSm = 12.0;
  static const radiusLg = 24.0;

  static final shadowSm = BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4));
  static final shadowMd = BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8));
  static final shadowLg = BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 40, offset: const Offset(0, 16));

  static final darkShadowSm = BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 12, offset: const Offset(0, 4));
  static final darkShadowMd = BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 24, offset: const Offset(0, 8));

  static Color get bg => isDark ? darkBg : _bg;
  static Color get cardBg => isDark ? darkCardBg : _cardBg;
  static Color get cardBorder => isDark ? darkCardBorder : _cardBorder;
  static Color get textDark => isDark ? darkTextPrimary : _textDark;
  static Color get textSoft => isDark ? darkTextSecondary : _textSoft;
  static Color get textMuted => isDark ? darkTextMuted : _textMuted;

  static BoxDecoration get cardDeco => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cardBorder, width: 1),
    boxShadow: [isDark ? darkShadowSm : shadowSm],
  );

  static BoxDecoration cardDecoFor(bool dark) => BoxDecoration(
    color: dark ? darkCardBg : _cardBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: dark ? darkCardBorder : _cardBorder, width: 1),
    boxShadow: [dark ? darkShadowSm : shadowSm],
  );

  static const kpiBgs = [Color(0xFFf5eedc), Color(0xFFe8efe9), Color(0xFFfaf0d7), Color(0xFFe9eff5)];
  static const darkKpiBgs = [Color(0xFF2a2515), Color(0xFF1a2a1e), Color(0xFF2a2510), Color(0xFF1a222a)];
  static const kpiAccents = [Color(0xFFb8860b), Color(0xFF1b4d3e), Color(0xFFd4a017), Color(0xFF3b5998)];

  static Widget kpiCard(String title, String value, IconData icon, {required Color accent, Color? bgTint}) {
    return Container(
      decoration: BoxDecoration(
        color: bgTint ?? cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [isDark ? darkShadowSm : shadowSm],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSoft, letterSpacing: 0.3)),
          Icon(icon, color: accent.withValues(alpha: 0.7), size: 16),
        ]),
        SizedBox(height: 4),
        Flexible(child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  static Widget sectionTitle(String text) => Padding(
    padding: EdgeInsets.fromLTRB(14, 20, 14, 8),
    child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
  );

  static ThemeData theme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: _bg,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, surface: _cardBg, brightness: Brightness.light),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.2),
    ),
    cardTheme: CardThemeData(
      color: _cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: const BorderSide(color: _cardBorder, width: 1)),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: _cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: const BorderSide(color: primary, width: 1.5)),
      hintStyle: TextStyle(color: _textMuted, fontSize: 14),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: _cardBg),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: primary, foregroundColor: Colors.white, elevation: 2),
    dialogTheme: DialogThemeData(
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      insetPadding: EdgeInsets.fromLTRB(12, 16, 12, 24),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm))),
    dividerTheme: const DividerThemeData(color: _cardBorder, thickness: 1),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: _cardBg, selectedItemColor: primary, unselectedItemColor: _textMuted, elevation: 0),
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: darkAccent,
    scaffoldBackgroundColor: darkBg,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: darkAccent, surface: darkSurface, brightness: Brightness.dark),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.2, color: darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: darkCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: const BorderSide(color: darkCardBorder, width: 1)),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkTextPrimary,
        side: const BorderSide(color: darkCardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardBg,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusSm), borderSide: const BorderSide(color: darkAccent, width: 1.5)),
      hintStyle: const TextStyle(color: darkTextMuted, fontSize: 14),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: darkSurface),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: darkAccent, foregroundColor: Colors.white, elevation: 2),
    dialogTheme: DialogThemeData(
      backgroundColor: darkCardBg,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg), side: const BorderSide(color: darkCardBorder)),
      insetPadding: EdgeInsets.fromLTRB(12, 16, 12, 24),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      backgroundColor: darkCardBg,
      contentTextStyle: const TextStyle(color: darkTextPrimary, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(color: darkCardBorder, thickness: 1),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2), tileColor: darkCardBg),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: darkAccent)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: darkSurface, selectedItemColor: darkAccent, unselectedItemColor: darkTextMuted, elevation: 0, selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700), unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600)),
  );
}

class SearchInput extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final Color? fillColor;
  final double iconSize;

  const SearchInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.fillColor,
    this.iconSize = 24,
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Tema.textMuted),
        prefixIcon: _focused
            ? null
            : Icon(Icons.search, color: Tema.textMuted, size: widget.iconSize),
        filled: true,
        fillColor: widget.fillColor ?? Tema.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tema.radiusSm),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onChanged: widget.onChanged,
    );
  }
}
