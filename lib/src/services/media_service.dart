import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:path/path.dart' as path;

import '../models/statics.dart';

///Media Service
class MediaService {
  ///Singleton Constructor
  factory MediaService() => _instance;

  MediaService._internal();

  static final MediaService _instance = MediaService._internal();

  ///Don't use
  @deprecated
  Future<void> setImage() async {
    var separator = path.separator;
    var directory = Directory("${path.current}$separator"
        "lib${separator}src$separator");

    var files = directory.listSync();

    for (var _f in files) {
      if (_f.isAbsolute) {
        // print("TRUE");

        if (_f.path.split(".").last == "png") {
          var file = File(_f.path);
          var image = decodeImage(file.readAsBytesSync())!;

          var thumb = copyResize(image, height: 200);

          var newFile2 = await File(
                  '${path.current}${separator}lib${separator}src$separator'
                  '${file.path.split(separator).last.split(".").first}'
                  '${separator}profile_thumb.png')
              .create(recursive: true);
          newFile2.writeAsBytesSync(encodePng(thumb));

          var newFile = await File('${path.current}$separator'
                  'lib${separator}src$separator'
                  '${file.path.split(separator).last.split(".").first}'
                  '${separator}profile.png')
              .create(recursive: true);
          newFile.writeAsBytesSync(file.readAsBytesSync());
        }
      }
    }
  }

  ///
  final String ima = "jpg";

  ///
  List<int> stages = [700, 1200, 2000];

  ///
  List<int> encodeF(Image image) {
    return encodeJpg(image, quality: 60);
  }

  ///add image from bytes
  ///images saved (if higher than) 200 , 700 , original size and story size
  ///return image id
  Future<String?> addImage(Uint8List bytes, String? id) async {

    var separator = path.separator;

    var image = decodeImage(bytes)!;

    // print(image.iccProfile.toString());
    //
    // print(image.width);


    var normalizedImage = normalizeImageForStory(image);

    // print("Took Normalize ${end2.difference(start2).inMilliseconds}ms");

    Image thumb;
    Image mid;
    Image full;

    if (image.width > stages[0]) {
      thumb = copyResize(image, width: stages[0]);
    } else {
      thumb = image;
    }

    if (image.width > stages[1]) {
      mid = copyResize(image, width: stages[1]);
    } else {
      mid = image;
    }

    if (image.width > stages[2]) {
      full = copyResize(image, width: stages[2]);
    } else {
      full = image;
    }

    var newFile2 = await File('${path.current}'
            '$separator'
            'var$separator'
            'images$separator'
            '$id${separator}profile_thumb.$ima')
        .create(recursive: true);
    await newFile2.writeAsBytes(encodeF(thumb));

    var newFile = await File('${path.current}$separator'
            'var$separator'
            'images$separator'
            '$id${separator}mid.$ima')
        .create(recursive: true);
    await newFile.writeAsBytes(encodeF(
      mid,
    ));

    var newFile3 = await File('${path.current}'
            '$separator'
            'var$separator'
            'images$separator'
            '$id${separator}profile.$ima')
        .create(recursive: true);
    await newFile3.writeAsBytes(encodeF(
      full,
    ));

    var newFile4 = await File('${path.current}$separator'
            'var$separator'
            'images$separator'
            '$id'
            '${separator}story.$ima')
        .create(recursive: true);
    await newFile4.writeAsBytes(normalizedImage);


    //
    // print("Took ${end.difference(start).inMilliseconds}ms");

    return id;
  }

  ///Add Video and return id
  Future<String?> addVideo(Uint8List bytes) async {
    var separator = path.separator;
    var id = Statics.getRandomId(20);
    File('${path.current}$separator'
            'var$separator'
            'images$separator'
            '$id.mp4')
        .writeAsBytesSync(bytes);

    return id;
  }

  ///Normalized image for story
  Uint8List normalizeImageForStory(Image raw) {
    raw = copyResize(raw, width: 450);
    var aspect = raw.width / raw.height;

    if (aspect < 9 / 16) {
      var h = raw.height;
      var w = h * 9 / 16;
      var newImage = Image.rgb(w.floor(), h).fill(0xFFFFFF);
      var newImageAddedRaw = drawImage(newImage, raw,
          dstX: ((w / 2) - raw.width / 2).floor(), dstY: 0);

      raw = newImage;

      // print("INIT : Cropped RAW BYTES: ${raw.length}");
      return encodeF(newImageAddedRaw) as Uint8List;
    } else {
      var w = raw.width;
      var h = w * 16 / 9;

      var newImage = Image.rgb(w.floor(), h.floor()).fill(0xFFFFFF);

      var newImageAddedRaw = drawImage(newImage, raw,
          dstX: 0, dstY: ((h / 2) - raw.height / 2).floor());

      raw = newImage;

      // print("INIT : cropped RAW BYTES: ${raw.length}");
      return encodeJpg(newImageAddedRaw, quality: 80) as Uint8List;
    }
  }
}
