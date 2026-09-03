import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Opens WhatsApp chat via wa.me deep link.
Future<bool> openWhatsApp(String rawNumber, {String? message}) async {
  final url = AppConstants.whatsappUrl(rawNumber, message: message);
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
