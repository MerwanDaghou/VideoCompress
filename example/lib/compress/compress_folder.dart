import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress_example/compress/compress_page.dart';
import 'package:video_compress_example/compress/media_manager.dart';

class CompressFolder extends StatefulWidget {
  const CompressFolder({super.key});

  @override
  State<CompressFolder> createState() => _CompressFolderState();
}

class _CompressFolderState extends State<CompressFolder> {
  List<String> urls = [
    "https://cdn.universe-codm.com/posts%2F3AwE5JDWWXXd5TcthqzhY0fKv8O2%2F0ae2cc1c-d97b-4321-8abf-8c6fb1689538?alt=media&token=213052eb-5e9d-4772-b877-393ae50c8736",
    "https://cdn.universe-codm.com/posts%2Fr1bm00hh2uOIF9NkVPysFcifTUz1%2Fc1a4fff7-b815-43e7-a745-d663e407603b?alt=media&token=2b7642e4-e51a-486e-9be9-a177deafe6ab",
    "https://cdn.universe-codm.com/posts%2Fr1bm00hh2uOIF9NkVPysFcifTUz1%2F1fc2ea33-24a4-4114-a160-9bf5a65e1a68?alt=media&token=4bcfc1a7-647c-441b-ae70-53e0edb707be",
    "https://cdn.universe-codm.com/posts%2Fr1bm00hh2uOIF9NkVPysFcifTUz1%2Fc99f35ca-f560-4a95-b569-18d0ad774d84?alt=media&token=df0ae320-8343-4dbf-8232-7ebd13997bdd",
    "https://cdn.universe-codm.com/posts%2Fr1bm00hh2uOIF9NkVPysFcifTUz1%2Fe4abece3-e977-4080-a26b-b0815f73924a?alt=media&token=4ec449ac-aae9-4986-a52f-fce6c8c4f5f5",
    "https://cdn.universe-codm.com/posts%2Fr1bm00hh2uOIF9NkVPysFcifTUz1%2F1d972fe5-12c5-4eda-9ed0-e194a40e29b6?alt=media&token=b28befd4-cc4e-4010-8965-c5b25b099be1",
    "https://cdn.universe-codm.com/posts%2F8vYhdfkzeQesuFR1WzkjuWjid6x1%2F666b2a9a-ff7d-4bcf-b67a-0aea8516800f?alt=media&token=e6521baa-fc22-4fc9-b688-ce9fac7d8481",
    "https://cdn.universe-codm.com/posts%2FVcNK1DQXGnO8aXBd7cL4BfHTDW93%2F813640f0-7eaf-45c3-9b63-3d0411bd20a4?alt=media&token=4da02029-8a6a-41fc-a1ef-5539f76cc785",
    "https://cdn.universe-codm.com/posts%2FjHOITLj9r3aOUarsInd43nku4IJ3%2Fa60734a0-7bc3-4888-a275-42454acc1eff?alt=media&token=4936e2da-87fe-46fe-ba93-3a9f05245c1f",
    "https://cdn.universe-codm.com/posts%2FjHOITLj9r3aOUarsInd43nku4IJ3%2Fae2ad2a8-7f8d-4c5c-8fbb-7cb778fe853e?alt=media&token=3a7be4f6-9257-4de8-91a5-229e278e2194",
    "https://cdn.universe-codm.com/posts%2FVsB1h8RqdzNVHu1f8eEXrDjsVUu2%2Fbe1df104-3607-4c28-b5cf-bcdb40d4111a?alt=media&token=f9ac03dd-ad5b-4ec0-9bc9-f470ab4856ea",
    "https://cdn.universe-codm.com/posts%2Fofj23SzPfGdxgbdHiDIxbuOCw4A3%2Fd1fea900-4c12-488a-a656-0aeff35699dc?alt=media&token=b454d48c-7ca7-4c24-81ff-3336913b4929",
    "https://cdn.universe-codm.com/posts%2FX3EKB17AzTQziPgs7X5XQyObUXf2%2F73d0fa0d-7384-4032-84a7-85382738080c?alt=media&token=0896e4bf-40f7-46ad-8980-a09aa42782c7",
    "https://cdn.universe-codm.com/posts%2FX3EKB17AzTQziPgs7X5XQyObUXf2%2Fcef611b1-38ea-4f04-896a-b4d83a05df88?alt=media&token=622a5cb3-5ee3-4c00-af47-f690defca569",
    "https://cdn.universe-codm.com/posts%2FX3EKB17AzTQziPgs7X5XQyObUXf2%2F288ffa01-29b3-44cc-9825-addc85e0fa96?alt=media&token=9c0b89ad-92f2-42b2-8e45-fa45f0587991",
    "https://cdn.universe-codm.com/posts%2FX3EKB17AzTQziPgs7X5XQyObUXf2%2Fabad94c6-a5dd-4432-93cd-0fa4442bf516?alt=media&token=a72c2e40-41ba-4eeb-bd79-6562dad4c4bc",
    "https://cdn.universe-codm.com/posts%2FX3EKB17AzTQziPgs7X5XQyObUXf2%2F23a3b138-1d9c-43f0-a4bc-bf00ea0d637c?alt=media&token=61a7d914-ca1b-41e2-aed2-dc496b8250bb",
    "https://cdn.universe-codm.com/posts%2FX3EKB17AzTQziPgs7X5XQyObUXf2%2Fe4ccce06-c83f-4197-a152-d8a01ed27f37?alt=media&token=afe03287-90bf-4ca2-b068-7810a69f3620",
    "https://cdn.universe-codm.com/posts%2FYkfoJlCxG1Pcdv8vgceT1f7Og4o2%2Fee8532a2-af0f-4d22-b003-d4e47d827548?alt=media&token=58b13326-eab4-48f6-9c52-a10753320b98",
  ];
  List<String> videoDownloaded = [];
  List<VideoInfo> videoInfoList = [];
  MediaManager manager = MediaManager();

  Future<void> init() async {
    final Directory dir = await getApplicationDocumentsDirectory();

    List<String> videoExtensions = ['mp4', 'avi', 'mov', 'mkv'];

    if (dir.existsSync()) {
      // List all files in the directory
      dir.listSync().forEach((fileSystemEntity) async {
        if (fileSystemEntity is File) {
          // Check if the file extension matches video extensions
          String extension =
              fileSystemEntity.path.split('.').last.toLowerCase();
          if (videoExtensions.contains(extension)) {
            videoDownloaded.add(fileSystemEntity.path);
            VideoInfo info = await manager.getInfo(fileSystemEntity.path);
            videoInfoList.add(info);
          }
        }
      });
    }

    urls.forEach((url) async {
      String id = url.split("=").last;
      bool existing = videoDownloaded.where((path) => path.contains(id)).isEmpty;
      if (existing) {
        print("downloading new url ...");
        try {
          Uint8List bytes = (await NetworkAssetBundle(Uri.parse(url)).load(url))
              .buffer
              .asUint8List();
          String id = url.split("=").last;
          String newPath = "${dir.path}/video_${id}.mp4";
          final File file = File(newPath);
          await file.writeAsBytes(bytes);
          videoDownloaded.add(file.path);
          VideoInfo info = await manager.getInfo(file.path);
          videoInfoList.add(info);
          print("file downloaded : ${file.path}");
        } catch (e) {}
      } else {
        print("already existing file : $id");
      }
    });
    print("video list : $videoDownloaded");

    await Future.delayed(Duration(seconds: 5));
    setState(() {});
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Compress Video"),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton:
          FloatingActionButton(onPressed: onPressed, child: Icon(Icons.add)),
      body: ListView.builder(
          itemCount: videoDownloaded.length,
          itemBuilder: (ctx, index) {
            final video = videoDownloaded[index];
            VideoInfo? videoInfo =
                videoInfoList.isNotEmpty ? videoInfoList[index] : null;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => onOpen(video),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      color: Colors.grey,
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (videoInfo != null)
                      Expanded(
                        child: Text(
                          "Width : ${videoInfo!.width} | Height : ${videoInfo!.height} | Size : ${videoInfo!.size}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                  ],
                ),
              ),
            );
          }),
    );
  }

  void onPressed() {
    Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => CompressPage()));
  }

  void onOpen(String video) {
    Navigator.push(
        context, MaterialPageRoute(builder: (ctx) => CompressPage(file: video)));
  }

}
