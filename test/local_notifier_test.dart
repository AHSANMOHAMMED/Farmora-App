import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/services/local_notifier.dart';

void main() {
  test('categories follow the notification type', () {
    expect(LocalNotifier.categoryOf('message'), 'messages');
    expect(LocalNotifier.categoryOf('general'), 'promos');
    expect(LocalNotifier.categoryOf('input_order'), 'orderUpdates');
  });

  test('preferences and quiet hours (overnight window)', () {
    final at23 = DateTime(2026, 9, 27, 23);
    final at9 = DateTime(2026, 9, 27, 9);
    const quiet = {'quietHoursStart': 22, 'quietHoursEnd': 6};
    expect(LocalNotifier.allowed('order', const {}, at23), isTrue);
    expect(LocalNotifier.allowed('order', quiet, at23), isFalse);
    expect(LocalNotifier.allowed('order', quiet, at9), isTrue);
    expect(LocalNotifier.allowed('message', const {'messages': false}, at9),
        isFalse);
  });
}
