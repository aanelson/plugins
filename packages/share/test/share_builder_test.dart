import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:share/share.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  MockMethodChannel mockChannel;
  const Size size = Size(2400, 1200);
  setUp(() {
    mockChannel = MockMethodChannel();
  });

  testWidgets('verify method channel is called and position is updated on rotate', (WidgetTester tester) async {
    final List<Map<String, dynamic>> updateOrigin = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> share = <Map<String, dynamic>>[];

    Share.channel.setMockMethodCallHandler((MethodCall call) async {
      if (call.method == 'updateOrigin') {
        updateOrigin.add(Map<String, dynamic>.from(call.arguments));
      } else if (call.method == 'share') {
        share.add(Map<String, dynamic>.from(call.arguments));
      } else {
        TestFailure('Unhandled method channel called');
      }
      mockChannel.invokeMethod<void>(call.method, call.arguments);
    });
    
    final Widget widgetWithShareInMiddle = Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ShareBuilder(
            builder: (BuildContext context, Sharing sharing) {
              return MaterialButton(
                child: const Text('Share'),
                onPressed: () => sharing.share('Share', subject: 'someSubject'),
              );
            },
          ),
        ));

    await tester.binding.setSurfaceSize(size);

    await tester.pumpWidget(widgetWithShareInMiddle);
    expect(updateOrigin.first, <String, dynamic>{
      'originX': 1149,
      'originY': 576,
      'originWidth': 102,
      'originHeight': 48,
    });

    await tester.tap(find.byType(MaterialButton));

    await tester.pump();
    expect(share.first, <String, dynamic>{
      'text': 'Share',
      'subject': 'someSubject',
      'originX': 1149,
      'originY': 576,
      'originWidth': 102,
      'originHeight': 48,
    });

    await tester.binding.setSurfaceSize(size.flipped);

    await tester.pump();
    await tester.pump();
    expect(updateOrigin.last, <String, dynamic>{
      'originX': 549,
      'originY': 1176,
      'originWidth': 102,
      'originHeight': 48,
    });
    expect(updateOrigin.length, 2);
  });
}

class MockMethodChannel extends Mock implements MethodChannel {}
