import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:maliza/core/data/account_cache.dart';
import 'package:maliza/core/models/assets.dart';
import 'package:maliza/core/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:maliza/features/auth/provider/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  // Prevent multiple snackbars

  @override
  void initState() {
    super.initState();
    _init();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  _init() async {
    final bool isLogined = await AccountCache.isLogined() ?? false;

    if (isLogined) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthProvider>(context);

    return FScaffold(
      child: Builder(
        builder: (innerContext) {
          final args = ModalRoute.of(innerContext)!.settings.arguments as Map?;
          final successMessage = args?['successMessage'] as String?;
          if (successMessage != null &&
              successMessage.isNotEmpty &&
              !authViewModel.isInitial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showFToast(
                alignment: FToastAlignment.topRight,
                context: innerContext,
                icon: Icon(FIcons.circleCheck, color: Colors.green),
                title: Text("Inscription réussie"),
                description: SizedBox(
                  width: MediaQuery.of(innerContext).size.width,
                  child: Text(successMessage),
                ),
              );
            });
            authViewModel.isInitial = true; // Prevent showing the toast again
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Image.asset(
                      Assets.imagesLogo,
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const Text(
                    'Connexion',
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

                  const SizedBox(height: 30),
                  authViewModel.isLoading
                      ? const Center(child: FProgress.circularIcon())
                      : FButton(
                          onPress: () async {
                            AuthResult authResult = await authViewModel.login(
                              emailController.text,
                              passwordController.text,
                            );
                            switch (authResult) {
                              case AuthResult.error:
                                showFToast(
                                  alignment: FToastAlignment.topCenter,
                                  // ignore: use_build_context_synchronously
                                  context: innerContext,
                                  icon: Icon(
                                    FIcons.circleAlert,
                                    color: Colors.red,
                                  ),
                                  title: Text("Erreur de connexion"),
                                  description: Text(
                                    authViewModel.error ??
                                        "Une erreur est survenue lors de la connexion.",
                                  ),
                                );
                                break;
                              case AuthResult.invalid:
                                showFToast(
                                  alignment: FToastAlignment.topCenter,
                                  context: innerContext,
                                  icon: Icon(
                                    FIcons.circleAlert,
                                    color: Colors.red,
                                  ),
                                  title: Text("Utilisateur invalide"),
                                  description: Text(
                                    authViewModel.error ??
                                        "L'email ou le mot de passe est incorrect.",
                                  ),
                                );
                                break;
                              case AuthResult.noConnexion:
                                showFDialog(
                                  context: innerContext,
                                  builder: (dialogContext, _, _) => FDialog(
                                    actions: [
                                      FButton(
                                        onPress: () {
                                          Navigator.pop(dialogContext);
                                        },
                                        child: Text("Ok"),
                                      ),
                                    ],
                                    body: Column(
                                      spacing: 10,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          FIcons.wifiOff,
                                          color: Colors.red,
                                          size: 70,
                                        ),
                                        Text(
                                          "Nous n’avons pas pu établir la connexion au serveur. Veuillez vérifier votre connexion Internet et réessayer de vous connecter",
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                break;
                              case AuthResult.success:
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.home);
                                break;
                              case AuthResult.cacheFailed:
                                debugPrint("Error saving session");
                                showFToast(
                                  alignment: FToastAlignment.topCenter,
                                  context: innerContext,
                                  icon: Icon(
                                    FIcons.circleAlert,
                                    color: Colors.red,
                                  ),
                                  title: Text("Erreur de session"),
                                  description: Text(
                                    authViewModel.error ??
                                        "Impossible de sauvegarder la session.",
                                  ),
                                );
                                break;
                            }
                          },
                          child: const Text('Se connecter'),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pas de compte ?'),
                      const SizedBox(width: 5),
                      FButton(
                        onPress: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.register);
                        },
                        style: FButtonStyle.secondary(),
                        child: const Text('Inscrivez-vous'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
