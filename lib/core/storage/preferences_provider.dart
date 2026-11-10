import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesProvider = FutureProvider(
  (ref) => SharedPreferences.getInstance(),
);
