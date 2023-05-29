import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<List<PlatformFile?>?> selectFile({allowMultiple = false}) async {
  final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf']);
  if (result == null) return null;

  List<PlatformFile?> pickedFiles = result.files;
  return pickedFiles;
}

uploadFile(var path, var files) async {
  for (var pickedFile in files) {
    final file = File(pickedFile!.path!);

    final ref =
        FirebaseStorage.instance.ref().child('$path/${pickedFile.name}');

    ref.putFile(file);
  }
}

deleteFiles(var folderPath, var accountType) async {
  List<Reference> fileRefs = [];
  List subfolders = [];

  if (accountType == "patient") {
    subfolders = ['Selfies', "Valid IDs"];
  } else {
    subfolders = ['business permit'];
  }

  for (var subfolder in subfolders) {
    final path = '$folderPath/$subfolder';

    final files = await FirebaseStorage.instance.ref(path).listAll();
    log(files.items.toString());

    fileRefs.addAll(files.items);
  }

  for (var ref in fileRefs) {
    FirebaseStorage.instance.ref(ref.fullPath).delete();
  }
}
