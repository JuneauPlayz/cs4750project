import 'package:flutter_dotenv/flutter_dotenv.dart';

String get rawgApiKey => dotenv.env['RAWG_API_KEY'] ?? '';
const String rawgBaseUrl = 'https://api.rawg.io/api';
