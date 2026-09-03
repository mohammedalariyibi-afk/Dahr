import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// Opens WhatsApp chat via wa.me deep link. Only Libyan numbers.
Future<bool> openWhatsApp(String rawNumber, {String? message}) async {
  if (!AppConstants.isValidLibyaPhone(rawNumber)) return false;
  final url = AppConstants.whatsappUrl(rawNumber, message: message);
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host != 'wa.me') {
    return false;
  }
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
