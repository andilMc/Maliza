import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:maliza/core/routes/app_routes.dart';
import 'package:maliza/features/app/presentation/widget/logout_btn.dart';
import 'package:maliza/features/app/provider/profile_provider.dart';
import 'package:maliza/core/models/assets.dart';
import 'package:provider/provider.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileProvider = context.read<ProfileProvider>();
    profileProvider.getInfo();
    profileProvider.getProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return FHeader(
      title: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesLogo),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('Erreur chargement logo: $exception');
                },
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            "Maliza",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
        ],
      ),
      suffixes: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.profile);
          },
          child: Consumer<ProfileProvider>(
            builder: (innerContext, profileProvider, child) {
              return Hero(
                tag: 'profileHero',
                child: FAvatar(
                  semanticsLabel: "profile-mini",
                  image: FileImage(File(profileProvider.image)),
                  fallback: Text(
                    (profileProvider.email.isNotEmpty)
                        ? profileProvider.email.substring(0, 2).toUpperCase()
                        : "??",
                  ),
                ),
              );
            },
          ),
        ),

        LogoutBtn(),
      ],
    );
  }
}
