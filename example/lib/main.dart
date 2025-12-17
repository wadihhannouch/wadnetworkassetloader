import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wadnetworkassetloader/wadnetworkassetloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('ar'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      assetLoader: EasyNetworkAssetLoader(
        // Replace with your actual server URL
        localeUrl: (localeName) => 'https://yourdomain.com/translations/',
        assetsPath: 'assets/translations',
        timeout: Duration(seconds: 30),
        localCacheDuration: Duration(days: 1),
      ),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyNetworkAssetLoader Example',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('app_title').tr(), elevation: 2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.language,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 32),
              Text(
                'welcome_message'.tr(),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'description'.tr(),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              Text(
                'select_language'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  _buildLanguageButton(
                    context,
                    'English',
                    Locale('en'),
                    '🇬🇧',
                  ),
                  _buildLanguageButton(
                    context,
                    'العربية',
                    Locale('ar'),
                    '🇸🇦',
                  ),
                  _buildLanguageButton(
                    context,
                    'Français',
                    Locale('fr'),
                    '🇫🇷',
                  ),
                ],
              ),
              SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(height: 8),
                      Text(
                        'info_message'.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String label,
    Locale locale,
    String flag,
  ) {
    final isSelected = context.locale == locale;
    return ElevatedButton.icon(
      onPressed: () async {
        await context.setLocale(locale);
      },
      icon: Text(flag, style: TextStyle(fontSize: 20)),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
        foregroundColor: isSelected ? Colors.white : null,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
