
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:mime/mime.dart';
import 'package:video_compress/video_compress.dart';

class VideoInfo {
  int width = 0;
  int height = 0;
  int durationInMs = 0;
  String size = "";

  VideoInfo(
      {this.width = 0, this.height = 0, this.durationInMs = 0, this.size = ""});
}


class MediaManager {
  bool isVideo(String path) {
    String? result = lookupMimeType(path);
    return result?.startsWith("video/") ?? false;
  }

  Future<VideoInfo> getInfo(String file) async {
    final video = isVideo(file);
    int width = 0;
    int height = 0;
    int duration = 0;
    if (video) {
      MediaInfo info = await VideoCompress.getMediaInfo(file);
      width = info.width ?? 0;
      height = info.height ?? 0;
      duration = (info.duration ?? 0).floor();
    } else {
      var decodedImage =
      await decodeImageFromList(File(file).readAsBytesSync());
      width = decodedImage.width;
      height = decodedImage.height;
    }
    String size = await getFileSize(File(file));
    return VideoInfo(
        width: width, height: height, durationInMs: duration, size: size);
  }

  /*Future<String> getFileSize(String filepath, int decimals) async {
    var file = File(filepath);
    int bytes = await file.length();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }*/

  Future<String> getFileSize(File file) async {
    try {
      // Get the size of the file in bytes
      int fileSizeInBytes = await file.length();

      // Convert the file size to a human-readable format (e.g., KB, MB, GB)
      String fileSize = _formatFileSize(fileSizeInBytes);

      // Get the file extension (e.g., .jpg, .png, etc.)
      //String fileExtension = path.extension(file.path);

      // Return the file details including the size and extension
      return fileSize;
    } catch (e) {
      return "0";
    }
  }

  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int index = 0;

    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[index]}';
  }

  Future<void> onSave(String path) async {
    if (path.isNotEmpty) {
      bool? success = await GallerySaver.saveVideo(path);
      if(success != null && success) {
        print("save success");
      }
    }
  }
}