import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:maliza/core/data/account_cache.dart';
import 'package:maliza/core/routes/app_routes.dart';

class LogoutBtn extends StatelessWidget {
  const LogoutBtn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  FButton(
            style: FButtonStyle.outline(),
            onPress: () {
              // Action de déconnexion
              showFDialog(
                context: context,
                builder: (innerContext, style, animation) => FDialog(
                  direction: Axis.horizontal,
                  title: Row(
                    spacing: 15,
                    children: [
                      Icon(FIcons.triangleAlert, color: Colors.red),
                      Text("Déconnexion"),
                    ],
                  ),
                  body: Text("Voulez vous vraimment vous déconnecter ?"),
                  actions: [
                    FButton(
                      style: FButtonStyle.outline(),
                      onPress: () => Navigator.of(innerContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    FButton(
                      style: FButtonStyle.destructive(),
                      onPress: () async {
                        bool isCleared = await AccountCache.clearLoginedUser();
                        if (isCleared) {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.login);
                        }
                      },
                      child: const Text('Oui'),
                    ),
                  ],
                ),
              );
            },
            child: Icon(Icons.logout, color: Colors.red),
          );
  }
}
