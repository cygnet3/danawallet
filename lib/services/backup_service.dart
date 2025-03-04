import 'dart:convert';
import 'dart:io';

import 'package:danawallet/generated/rust/api/backup.dart';
import 'package:danawallet/global_functions.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/repositories/wallet_repository.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  static Future<bool> backupToFile() async {
    WalletRepository walletRepository = WalletRepository.instance;
    SettingsRepository settingsRepository = SettingsRepository.instance;

    try {
      final walletBackup = await walletRepository.createWalletBackup();
      final settingsBackup = await settingsRepository.createSettingsBackup();

      final danaBackup = DanaBackup(
          wallet: walletBackup, settings: settingsBackup);

      if (Platform.isAndroid || Platform.isIOS) {
        await FilePicker.platform.saveFile(
            dialogTitle: 'Please select an output file:',
            fileName: 'dana.json',
            bytes: utf8.encode(danaBackup.encode()));

        return true;
      } else if (Platform.isLinux) {
        // on linux, we have to manually write to the file using the filename
        String? outputFilePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: 'dana.json',
        );
        if (outputFilePath != null) {
          final file = File(outputFilePath);
          await file.writeAsBytes(utf8.encode(danaBackup.encode()));

          return true;
        }
      }
    } catch (e) {
      displayNotification(exceptionToString(e));
    }

    return false;
  }

  static Future<bool> restoreFromFile() async {
    WalletRepository walletRepository = WalletRepository.instance;
    SettingsRepository settingsRepository = SettingsRepository.instance;

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      final backup = DanaBackup.decode(
          encodedBackup: utf8.decode(await file.readAsBytes()));

      await walletRepository.restoreWalletBackup(backup.wallet);
      await settingsRepository.restoreSettingsBackup(backup.settings);
      return true;
    } else {
      return false;
    }
  }
}
