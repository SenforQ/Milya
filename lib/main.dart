import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milya/pages/main_tab_page.dart';
import 'pages/agreement_page.dart';

void main() {
  runApp(const MilyaApp());
}

class MilyaApp extends StatelessWidget {
  const MilyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.grey,
        primaryColor: const Color(0xFFFFFFFF),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFFFFF),
          secondary: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
        // 设置iOS风格的系统UI
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
          ),
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      home: const AgreementPage(),
      // home: const MainTabPage(),
    );
  }
}
