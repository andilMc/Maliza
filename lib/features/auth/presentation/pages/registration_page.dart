import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:maliza/core/models/assets.dart';
import 'package:maliza/core/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:maliza/features/auth/provider/auth_provider.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return FScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(bottom: 20),
                child: Image.asset(Assets.imagesLogo, width: 80, height: 80),
              ),
              const Text(
                'Inscription',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              FTextField(
                controller: emailController,
                label: const Text('Email'),
                hint: 'votre.email@exemple.com',
              ),
              const SizedBox(height: 15),
              FTextField(
                controller: passwordController,
                label: const Text('Mot de passe'),
                hint: '•••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 15),
              FTextField(
                controller: confirmPasswordController,
                label: const Text('Confirmer le mot de passe'),
                hint: '•••••••••',
                obscureText: true,
              ),

              SizedBox(height: 30),
              Consumer<AuthProvider>(
                builder: (context, authViewModel, _) {
                  return authViewModel.isLoading
                      ? Center(child: FProgress.circularIcon())
                      : FButton(
                          onPress: () async {
                            if (passwordController.text !=
                                confirmPasswordController.text) {
                              showFToast(
                                alignment: FToastAlignment.topRight,
                                icon: Icon(
                                  FIcons.circleAlert,
                                  color: Colors.red,
                                ),
                                context: context,
                                title: Text("Mots de passe non identiques"),
                                description: Text(
                                  "Les mots de passe ne correspondent pas. Veuillez vérifier les mots de passe.",
                                ),
                              );
                              return;
                            }

                            if (emailController.text.isEmpty ||
                                passwordController.text.isEmpty) {
                              showFToast(
                                alignment: FToastAlignment.topRight,

                                icon: Icon(
                                  FIcons.circleAlert,
                                  color: Colors.red,
                                ),
                                context: context,
                                title: Text("Champs manquants"),
                                description: Text(
                                  "Veuillez remplir tous les champs avant de vous inscrire.",
                                ),
                              );
                              return;
                            }
                            final feu = await authViewModel.register(
                              emailController.text,
                              passwordController.text,
                            );
                            if (feu) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (route) => false,
                                arguments: {
                                  'successMessage': authViewModel.success,
                                },
                              );
                            } else {
                              showFToast(
                                alignment: FToastAlignment.topRight,
                                icon: Icon(
                                  FIcons.circleAlert,
                                  color: Colors.red,
                                ),
                                // ignore: use_build_context_synchronously
                                context: context,
                                title: Text("Erreur d'inscription"),
                                description: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: Text(
                                    authViewModel.error ??
                                        "Une erreur est survenue.",
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('S\'inscrire'),
                        );
                },
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Déjà un compte ?'),
                  const SizedBox(width: 5),
                  FButton(
                    onPress: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.login);
                    },
                    style: FButtonStyle.secondary(),
                    child: const Text('Connectez-vous'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
