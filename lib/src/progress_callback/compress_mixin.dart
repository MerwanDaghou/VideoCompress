import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'subscription.dart';

class CompressMixin {
  final compressProgress$ = ObservableBuilder<double>();
  final _channel = const MethodChannel('video_compress');

  final _compressChannel = const MethodChannel('CompressVideo');

  @protected
  void initProcessCallback() {
    _channel.setMethodCallHandler(_progressCallback);
  }

  MethodChannel get channel => _channel;

  MethodChannel get compressChannel => _compressChannel;

  bool _isCompressing = false;

  bool get isCompressing => _isCompressing;

  String _pathCompressed = "";

  String get pathCompressed => _pathCompressed;

  void setProcessingStatus(bool status) {
    _isCompressing = status;
  }

  void setProcessingFile(String path) {
    _pathCompressed = path;
  }


  Future<void> _progressCallback(MethodCall call) async {
    switch (call.method) {
      case 'updateProgress':
        final progress = double.tryParse(call.arguments.toString());
        if (progress != null) compressProgress$.next(progress);
        break;
    }
  }
}
