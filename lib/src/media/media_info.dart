
import 'package:flutter/foundation.dart';

class MediaInfo {
  String? path;
  String? title;
  String? author;
  int? width;
  int? height;

  /// [Android] API level 17
  int? orientation;

  /// bytes
  int? fileSize; // file size
  /// microsecond
  double? duration;
  bool? isCancel;

  bool? isLandscape;

  MediaInfo({
    required this.path,
    this.title,
    this.author,
    this.width,
    this.height,
    this.orientation,
    this.fileSize,
    this.duration,
    this.isCancel,
    this.isLandscape
  });

  MediaInfo.fromJson(Map<String, dynamic> json) {
    debugPrint("Json is : $json");
    path = json['path'];
    title = json['title'];
    author = json['author'];
    width = json['width'];
    height = json['height'];
    orientation = json['orientation'];
    fileSize = json['fileSize'];
    duration = double.tryParse('${json['duration']}');
    isCancel = json['isCancel'];
    isLandscape = json["isLandscape"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['path'] = this.path;
    data['title'] = this.title;
    data['author'] = this.author;
    data['width'] = this.width;
    data['height'] = this.height;
    if (this.orientation != null) {
      data['orientation'] = this.orientation;
    }
    data['fileSize'] = this.fileSize;
    data['duration'] = this.duration;
    if (this.isCancel != null) {
      data['isCancel'] = this.isCancel;
    }
    data["isLandscape"] = this.isLandscape;
    return data;
  }

  @override
  String toString() {
    return "MediaInfo - width: $width - height $height - orientation $orientation - landscape : $isLandscape";
  }

}
