// services/preferences_service.dart — shared SharedPreferences layer
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PreferencesService {
  static PreferencesService? _instance;
  SharedPreferences? _prefs;

  PreferencesService._();
  factory PreferencesService() => _instance ??= PreferencesService._();

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ─── Orang 1: nama user ──────────────────────────────────────────────────
  Future<String> getUserName() async =>
      (await _p).getString(kPrefUserName) ?? '';

  Future<void> setUserName(String name) async =>
      (await _p).setString(kPrefUserName, name);

  // ─── Orang 1: mata uang default ──────────────────────────────────────────
  Future<String> getDefaultCurrency() async =>
      (await _p).getString(kPrefDefaultCurrency) ?? kDefaultCurrency;

  Future<void> setDefaultCurrency(String currency) async =>
      (await _p).setString(kPrefDefaultCurrency, currency);

  // ─── Orang 2: tema warna ─────────────────────────────────────────────────
  Future<String> getColorTheme() async =>
      (await _p).getString(kPrefColorTheme) ?? kDefaultColorTheme;

  Future<void> setColorTheme(String theme) async =>
      (await _p).setString(kPrefColorTheme, theme);

  // ─── Orang 2: format tanggal ─────────────────────────────────────────────
  Future<String> getDateFormat() async =>
      (await _p).getString(kPrefDateFormat) ?? kDefaultDateFormat;

  Future<void> setDateFormat(String format) async =>
      (await _p).setString(kPrefDateFormat, format);

  // ─── Helper: clear all (for testing) ─────────────────────────────────────
  Future<void> clearAll() async => (await _p).clear();
}
