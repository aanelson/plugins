// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show visibleForTesting;

/// Plugin for summoning a platform share sheet.
class Share {
  /// [MethodChannel] used to communicate with the platform side.
  @visibleForTesting
  static const MethodChannel channel = MethodChannel('plugins.flutter.io/share');

  /// Updates the origin location for the shareSheet
  ///
  /// The [sharePosition] parameter can be used to specify a global
  /// origin rect for the share sheet popover on iPads. It has no effect
  /// on non-iPads.
  ///
  static Future<void> sharePosition(Rect sharePosition) {
    if (sharePosition == null) {
      return Future<void>.sync(() {});
    }
    final Map<String, dynamic> params = <String, dynamic>{};

    params['originX'] = sharePosition.left;
    params['originY'] = sharePosition.top;
    params['originWidth'] = sharePosition.width;
    params['originHeight'] = sharePosition.height;
    return channel.invokeMethod('updateOrigin', params);
  }

  /// Summons the platform's share sheet to share text.
  ///
  /// Wraps the platform's native share dialog. Can share a text and/or a URL.
  /// It uses the `ACTION_SEND` Intent on Android and `UIActivityViewController`
  /// on iOS.
  ///
  /// The optional [subject] parameter can be used to populate a subject if the
  /// user chooses to send an email.
  ///
  /// The optional [sharePositionOrigin] parameter can be used to specify a global
  /// origin rect for the share sheet to popover from on iPads. It has no effect
  /// on non-iPads.
  ///
  /// May throw [PlatformException] or [FormatException]
  /// from [MethodChannel].
  static Future<void> share(
    String text, {
    String subject,
    Rect sharePositionOrigin,
  }) {
    assert(text != null);
    assert(text.isNotEmpty);
    final Map<String, dynamic> params = <String, dynamic>{
      'text': text,
      'subject': subject,
    };

    if (sharePositionOrigin != null) {
      params['originX'] = sharePositionOrigin.left;
      params['originY'] = sharePositionOrigin.top;
      params['originWidth'] = sharePositionOrigin.width;
      params['originHeight'] = sharePositionOrigin.height;
    }
    return channel.invokeMethod<void>('share', params);
  }
}

typedef SharingBuilder = Widget Function(BuildContext context, Sharing sharing);

class Sharing {
  const Sharing._(this._context);
  final BuildContext _context;

  Future<void> share(String text, {String subject}) {
    final RenderBox box = _context.findRenderObject();
    return Share.share(text, subject: subject, sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }
}

///Widget to encapsilate the getting of the share sheet origin for ipad.
class ShareBuilder extends StatelessWidget {
  ShareBuilder({@required this.builder, Key key}) : super(key: key);
  final SharingBuilder builder;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          Future<void>.microtask(() {
            final RenderBox box = context.findRenderObject();
            if (box != null) {
              Share.sharePosition(box.localToGlobal(Offset.zero) & box.size);
            }
          });
          return builder(context, Sharing._(context));
        },
      );
}
