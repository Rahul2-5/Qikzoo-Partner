import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  _registerFontLicenses();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: DeliveryPartnerApp()));
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Inter'],
      await rootBundle.loadString('assets/fonts/OFL-Inter.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      const ['Manrope'],
      await rootBundle.loadString('assets/fonts/OFL-Manrope.txt'),
    );
  });
}
