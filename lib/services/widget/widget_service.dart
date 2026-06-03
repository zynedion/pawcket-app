import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _androidWidgetName = 'PawcketWidgetProvider';

  /// Updates the widget UI with dynamic data and Oyen expression
  static Future<void> updateWidget({
    required String status,
    required String display,
    required String oyenImageName,
  }) async {
    try {
      // Save widget data for the android widget to read
      await HomeWidget.saveWidgetData<String>('status_text', status);
      await HomeWidget.saveWidgetData<String>('display_text', display);
      await HomeWidget.saveWidgetData<String>('mr_oyen_image', oyenImageName);

      // Trigger update
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Helper to set Mr. Oyen to lazyass expression
  static Future<void> setLazyOyen({String? status, String? display}) async {
    await updateWidget(
      status: status ?? 'Pawcket - Idle',
      display: display ?? 'Tap to log: "Makan sate 25k"',
      oyenImageName: 'lazyass_oyen',
    );
  }

  /// Helper to set Mr. Oyen to thinking expression
  static Future<void> setThinkingOyen({String? status, String? display}) async {
    await updateWidget(
      status: status ?? 'Mr. Oyen is thinking...',
      display: display ?? 'Parsing your expense...',
      oyenImageName: 'thinking_oyen',
    );
  }

  /// Helper to set Mr. Oyen to smirk expression (success)
  static Future<void> setSuccessOyen({required String display}) async {
    await updateWidget(
      status: '✓ Expense Logged!',
      display: display,
      oyenImageName: 'smirk_oyen',
    );
    
    // Auto reset to lazy oyen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setLazyOyen();
    });
  }

  /// Helper to set Mr. Oyen to angry expression (failure)
  static Future<void> setErrorOyen({required String errorText}) async {
    await updateWidget(
      status: '❌ Error occurred',
      display: errorText,
      oyenImageName: 'angry_oyen',
    );
  }
}
