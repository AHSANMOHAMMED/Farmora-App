import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/core/utils/carbon.dart';

void main() {
  test('vehicle classes from free text', () {
    expect(Carbon.vehicleClass('Three-wheeler'), 'threeWheeler');
    expect(Carbon.vehicleClass('Motor bike'), 'motorbike');
    expect(Carbon.vehicleClass('Dimo Batta pickup'), 'van');
    expect(Carbon.vehicleClass('Lorry'), 'lorry');
    expect(Carbon.vehicleClass(''), 'lorry');
  });

  test('road distance from districts, with a 10 km floor', () {
    final km = Carbon.roadKm(fromText: 'Nuwara Eliya farm', toText: '12 Galle Road, Colombo 03')!;
    expect(km, greaterThan(100));
    expect(km, lessThan(200));
    expect(Carbon.roadKm(fromText: 'Kandy', toText: 'Kandy town'), 10);
    expect(Carbon.roadKm(fromText: 'Somewhere', toText: 'Colombo'), isNull);
  });

  test('delivery emissions scale with distance and cold chain', () {
    final base = Carbon.deliveryKg(100, 'Lorry');
    expect(base, closeTo(60, 0.01));
    expect(Carbon.deliveryKg(100, 'Lorry', cold: true), closeTo(72, 0.01));
  });

  test('practice factors', () {
    expect(Carbon.practiceTonnes('agroforestry_trees', 100), closeTo(2, 1e-9));
    expect(Carbon.practiceTonnes('unknown', 5), 0);
  });
}
