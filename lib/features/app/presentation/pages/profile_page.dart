import 'dart:io';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:maliza/features/app/presentation/widget/logout_btn.dart';
import 'package:maliza/features/app/provider/profile_provider.dart';
import 'package:maliza/features/app/provider/task_provider.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileProvider = context.read<ProfileProvider>();
    profileProvider.getInfo();
    profileProvider.getProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: Row(
          spacing: 10,
          children: [
            FButton(
              style: FButtonStyle.outline(),
              onPress: () {
                Navigator.pop(context);
              },
              child: Icon(FIcons.arrowLeft, color: Color(0xFF6C757D)),
            ),
            Text("Profile", style: TextStyle(fontSize: 18)),
          ],
        ),
        suffixes: [LogoutBtn()],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Section supérieure avec avatar
          Consumer<ProfileProvider>(
            builder: (innerContext, profileProvider, _) => Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        blue: 0.8,
                        green: 0.8,
                        red: 0.8,
                      ),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    profileProvider.pickImage();
                  },
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'profileHero',
                        child: FAvatar(
                          size: 200,
                          semanticsLabel: "profile",
                          image: FileImage(File(profileProvider.image)),
                          fallback: Text(
                            (profileProvider.email.isNotEmpty)
                                ? profileProvider.email
                                      .substring(0, 2)
                                      .toUpperCase()
                                : "??",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 60,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          width: 50,
                          height: 50,
                          child: Icon(FIcons.pencil, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Section principale avec conteneur blanc
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        spacing: 16,
        children: [
          // Informations utilisateur
          Column(
            spacing: 16,
            children: [
              // Nom
              Consumer<ProfileProvider>(
                builder: (innerContext, profileProvider, _) => Text(
                  profileProvider.email,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212529),
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // Badge ou statut
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Actif',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Statistiques
          Consumer<TaskProvider>(
            builder: (innerContext, taskProvider, _) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF495057),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '${taskProvider.getStatistics()['total']}',
                        'Total',
                        Colors.blue,
                      ),
                      _buildStatItem(
                        '${taskProvider.getStatistics()['completed']}',
                        'Terminés',
                        Colors.green,
                      ),
                      _buildStatItem(
                        '${taskProvider.getStatistics()['pending']}',
                        'En attente',
                        Colors.orange,
                      ),
                      _buildStatItem(
                        '${taskProvider.getStatistics()['overdue']}',
                        'En retard',
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }
}
