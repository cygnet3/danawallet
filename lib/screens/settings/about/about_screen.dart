import 'package:danawallet/screens/settings/widgets/info_text_container.dart';
import 'package:danawallet/services/app_info_service.dart';
import 'package:danawallet/widgets/skeletons/screen_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const String pageTitle = "About Dana";
const String danaDescription =
    "Dana is a flutter app used for accepting bitcoin donations. It uses silent payments, a new static payments protocol, to receive donations while preserving on-chain privacy.";
const String versionInfoPrefix = "App version: ";
const String buildNumberPrefix = "Build number: ";
const String commitInfoPrefix = "Build commit hash: ";
const String licenceInfo =
    "Dana is Free and Open Source Software licensed under the MIT license.";

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppInfoService appInfo =
        Provider.of<AppInfoService>(context, listen: false);

    final body = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoTextContainer(infoText: danaDescription),
            const InfoTextContainer(infoText: licenceInfo),
            InfoTextContainer(
                infoText: "$versionInfoPrefix ${appInfo.appVersion}"),
            InfoTextContainer(
                infoText: "$buildNumberPrefix ${appInfo.buildNumber}"),
          ],
        ));

    return ScreenSkeleton(title: pageTitle, body: body, showBackButton: true);
  }
}
