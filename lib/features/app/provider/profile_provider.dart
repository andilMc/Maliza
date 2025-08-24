import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maliza/core/data/account_cache.dart';
import 'package:maliza/core/data/database_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileProvider extends ChangeNotifier {
  final Databasehelper _db = Databasehelper();
  String email = '';
  String isActif = '';
  final ImagePicker _picker = ImagePicker();
  String image = '';

  Future<void> getInfo() async {
    email = await AccountCache.getCurrentAccountEmail();

    final loggedIn =
        await AccountCache.isLogined(); // ici c’est un Future<bool?>
    isActif = (loggedIn ?? false) ? "Actif" : "Not Actif";

    notifyListeners();
  }

  Future<void> pickImage() async {
    var status = Permission.photos;
    bool isGarated = await status.isGranted;
    if (!isGarated) {
      status.request();
    }
    if (await status.isGranted) {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        int id = await AccountCache.getCurrentAccountId() ?? 0;
        int insrtedId = await _db.insertProfile(id, pickedFile.path);
        if (insrtedId > 0) {
          getProfileImage();
        }
        notifyListeners();
      } else {
        return;
      }
    }
  }

  Future<void> getProfileImage() async {
    int id = await AccountCache.getCurrentAccountId() ?? 0;
    String imgPath = await _db.getProfileImage(id);
    image = imgPath;
    notifyListeners();
  }
}
