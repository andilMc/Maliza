# Maliza
![hero](assets/docs/image.png)
## 1)Screenshots

- **Login, Register**

![login](assets/docs/Screenshot_20250824-142745.png)

![register](assets/docs/Screenshot_20250824-142755.png)

- **Accueil (météo + liste + profil + logout)**

![Home](assets/docs/Screenshot_20250824-181831.png)

- **Ajout/édition/complétion/suppression d’une tâche (avec Slidable)**

![ajout_check](assets/docs/Screenshot_20250824-174022.png)

![edit_delete](attachment:96b6b325-a75e-4d6d-a798-4375f4400566:Screenshot_20250824-192021.png)

- **Recherche**
    
    ![recherce](assets/docs/Screenshot_20250824-174056.png)
    
- **Profil (sélection photo)**

![profile](assets/docs/Screenshot_20250824-174239.png)

- Historique

![historique-1](assets/docs/Screenshot_20250824-193256.png)

![historique-2](assets/docs/Screenshot_20250824-174041.png)

![historique-3](assets/docs/Screenshot_20250824-193303.png)

- Meteo

![day](assets/docs/Screenshot_20250824-181840.png)

![nuit](assets/docs/Screenshot_20250824-193059.png)

---
## 2)Structure du projet

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
```
