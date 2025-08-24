# Maliza
<img src="assets/docs/image.png" alt="hero" width="250"/>

## 1) Screenshots

- **Login, Register**

<p align="center">
    <img src="assets/docs/Screenshot_20250824-142745.png" alt="Login" width="150"/>
    <img src="assets/docs/Screenshot_20250824-142755.png" alt="Register" width="150"/>
</p>

- **Accueil (météo + liste + profil + logout)**

<p align="center">
    <img src="assets/docs/Screenshot_20250824-181831.png" alt="Accueil" width="150"/>
</p>

- **Ajout/édition/complétion/suppression d’une tâche (avec Slidable)**

<p align="center">
    <img src="assets/docs/Screenshot_20250824-174022.png" alt="Ajout" width="150"/>
    <img src="assets/docs/Screenshot_20250824-192021.png" alt="Edit/Delete" width="150"/>
</p>

- **Recherche**

<p align="center">
    <img src="assets/docs/Screenshot_20250824-174056.png" alt="Recherche" width="150"/>
</p>

- **Profil (sélection photo)**

<p align="center">
    <img src="assets/docs/Screenshot_20250824-174239.png" alt="Profil" width="150"/>
</p>

- **Historique**

<p align="center">
    <img src="assets/docs/Screenshot_20250824-193256.png" alt="Historique 1" width="150"/>
    <img src="assets/docs/Screenshot_20250824-174041.png" alt="Historique 2" width="150"/>
    <img src="assets/docs/Screenshot_20250824-193303.png" alt="Historique 3" width="150"/>
</p>

- **Météo**

<p align="center">
    <img src="assets/docs/Screenshot_20250824-181840.png" alt="Météo jour" width="150"/>
    <img src="assets/docs/Screenshot_20250824-193059.png" alt="Météo nuit" width="150"/>
</p>

---

## 2) Structure du projet

Organisation logique en trois grands blocs :

- **`lib/core/`** : fondations techniques partagées (API, configuration, erreurs, modèles, réseau, thème, routes, widgets génériques).
- **`lib/features/`** : fonctionnalités applicatives (authentification, cœur de l’app).
- **`assets/`** : ressources statiques (images, icônes).

Aperçu des dossiers clés :

```yaml
lib/
  core/
    api/
      api_endpoints.dart        # URLs de l’API
      remote_database_helper.dart
      remote_db_updater.dart    # Logique de synchronisation
      weather_service.dart      # Intégration WeatherAPI
    config/
      config_global.dart        # Nom app, version, IP serveur API
    data/
      account_cache.dart        # Session & préférences (SharedPreferences)
      database_helper.dart      # SQLite (tables todo, todo_action, profile)
    error/                      # Exceptions API/Réseau/Météo
    models/                     # Todo, User, ApiResult, SyncResult, etc.
    network/
      network_client.dart       # Client HTTP + gestion d’erreurs
    routes/
      app_routes.dart           # Noms des routes
      app_router.dart           # Générateur de routes
    theme/
      theme_config.dart         # Thème ForUI

  features/
    auth/
      provider/auth_provider.dart
      presentation/pages/login_page.dart
      presentation/pages/registration_page.dart
    app/
      provider/                 # TaskProvider, WeatherProvider, ProfileProvider, ...
      presentation/
        pages/                  # HomePage, TodoPage, ProfilePage, RecherchePage, App
        widget/                 # Weather, TaskListWidget, TopBar, dialogs, LogoutBtn
        bloc/                   # AddTaskBloc, ListTodos (UI blocs)

  main.dart                     # Point d’entrée
