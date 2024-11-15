import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_compress_example/video_player_app.dart';

class CompressPage extends StatefulWidget {
  const CompressPage({super.key});

  @override
  State<CompressPage> createState() => _CompressPageState();
}

class _CompressPageState extends State<CompressPage> {
  //final Uploader _uploader = Uploader();

  String originFile = "";
  String compressedFile = "";

  VideoInfo infoOrigin = VideoInfo();
  VideoInfo infoCompressed = VideoInfo();

  final MethodChannel compressChannel = const MethodChannel("VideoCompress");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: onNewPostTap,
        child: const Icon(CupertinoIcons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            originFile.isNotEmpty
                ? media(file: originFile, info: infoOrigin, width: 500)
                : const SizedBox(),
            const SizedBox(height: 30),
            compressedFile.isNotEmpty
                ? media(
                file: compressedFile,
                info: infoCompressed,
                mute: false,
                width: 500)
                : const SizedBox(),
            const SizedBox(height: 30),
            Center(
              child: CupertinoButton(
                color: Colors.blue,
                onPressed: onCompress,
                child: const Text("Compress"),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: CupertinoButton(
                color: Colors.redAccent,
                onPressed: onSave,
                child: const Text("Save"),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget media({
    required String file,
    required VideoInfo info,
    bool mute = true,
    required double width,
  }) {
    bool video = isVideo(file);
    print(
        "Origin info : ${"Width : ${info.width} |  Height : ${info.height} |  Size : ${info.size}"}");
    print("\n-----------------------------\n");
    return Column(
      children: [
        if (video)
          SizedBox(
            width: width,
            child: VideoPlayerApp(
              file: file,
              mute: mute,
              shouldLoop: true,
              onSizeChanged: (Size value) {
                info.width = value.width.floor();
                info.height = value.height.floor();
                setState(() {});
              },
            ),
          ),
        if (!video) Image.file(File(file)),
        const SizedBox(height: 10),
        Text(
          "Width : ${info.width} |  Height : ${info.height} |  Size : ${info.size}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        )
      ],
    );
  }

  Future<void> onNewPostTap() async {
    final xfile = await ImagePicker().pickMedia();
    if (xfile != null) {
      setState(() {
        originFile = "";
        compressedFile = "";
      });
      await Future.delayed(const Duration(seconds: 1));
      infoOrigin = await getInfo(xfile.path);
      setState(() {
        originFile = xfile.path;
      });
    }
  }

  Future<void> onCompress() async {
    if (originFile.isNotEmpty) {
      if (compressedFile.isNotEmpty) {
        print("delete file : $compressedFile");
        File(compressedFile).deleteSync();
      }
      setState(() {
        compressedFile = "";
      });

      bool video = isVideo(originFile);
      if (video) {
        /*MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          originFile,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );*/
        final dir = await getTemporaryDirectory();
        File file = File(
            "${dir.path}/compress_video${DateTime.now().millisecondsSinceEpoch}.mp4");
        double ratio = infoOrigin.height / infoOrigin.width;

        double newHeight = 0;
        double newWidth = 0;

        print("ratio : $ratio");
        if (ratio <= 1) {
          newWidth = min(960, infoOrigin.width.floorToDouble());
          newHeight = newWidth * ratio;
        } else {
          newHeight = min(960, infoOrigin.height.floorToDouble());
          newWidth = newHeight / ratio;
        }
        print("new width : $newWidth");
        print("new height : $newHeight");
        String? output = await VideoCompress.compressVideoIOS(
            input: originFile,
            output: file.path,
            width: newWidth,
            height: newHeight);

        /*await compressChannel.invokeMethod("compressVideo", {
          "inputFile": originFile,
          "outputFile": file.path,
          "width": newWidth,
          "height": newHeight,
          "bitrate": 2500000, // 1000000,
          "frameRate": 30,
          //"outputFile": file.path,
          "quality": 2,
          "usePreset": false,
        });*/
        print("compressed result : $output");
        if (output != null) {
          infoCompressed = await getInfo(output);
          //infoCompressed.height = mediaInfo!.height!;
          //infoCompressed.width = mediaInfo!.width!;
          //print("file compressed : ${temp.path}");
          setState(() {
            compressedFile = output; // mediaInfo!.path!;
          });
        }
      } /*else {
        Uint8List? data;
        try {
          data = await FlutterImageCompress.compressWithFile(originFile,
              minHeight: 1280, minWidth: 1280, quality: 95);
          if (data != null) {
            final tempDir = await getTemporaryDirectory();

            // Create a unique file path in the temporary directory
            final tempFile = File(
                '${tempDir.path}/temp_file_${DateTime.now().millisecondsSinceEpoch}.tmp');

            // Write the bytes to the file
            await tempFile.writeAsBytes(data);
            setState(() {
              compressedFile = tempFile.path;
            });
          }
        } catch (e) {}
      }*/
    }
  }

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
      //Map<String, dynamic> values = await _uploader.getMediaInfo(file);
      //width = values["width"] ?? 0;
      //height = values["height"] ?? 0;
      //duration = values["duration"] ?? 0;
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

  Future<void> onSave() async {
    if (compressedFile.isNotEmpty) {
      bool? success = false;// await GallerySaver.saveVideo(compressedFile);
      if (success != null && success) {
        print("save success");
      }
    }
  }
}

class VideoInfo {
  int width = 0;
  int height = 0;
  int durationInMs = 0;
  String size = "";

  VideoInfo(
      {this.width = 0, this.height = 0, this.durationInMs = 0, this.size = ""});
}
