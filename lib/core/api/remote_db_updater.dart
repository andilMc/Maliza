import 'package:maliza/core/api/remote_database_helper.dart';
import 'package:maliza/core/data/database_helper.dart';
import 'package:maliza/core/models/api_result.dart';
import 'package:maliza/core/models/sync_result.dart';
import 'package:maliza/core/models/todo.dart';
import 'package:flutter/material.dart';

class RemoteDbUpdater {
  final int currentId;
  final Databasehelper _db = Databasehelper();

  RemoteDbUpdater({required this.currentId});

  Future<SyncResult> syncAll() async {
    try {
      debugPrint("🔄 Début de la synchronisation...");
      
      // Récupération des données
      final (localTodos, remoteTodos, actions) = await _fetchBothDataSources();
      
      // ÉTAPE PRÉLIMINAIRE : Nettoyer tous les doublons existants
      debugPrint("🧹 Vérification et nettoyage des doublons existants...");
      await _cleanAllExistingDuplicates(remoteTodos);

      debugPrint("===============================");
      debugPrint("📊 Actions à traiter: ${actions.length}");
      debugPrint("📱 Todos locaux: ${localTodos.length}");
      debugPrint("☁️ Todos distants: ${remoteTodos.length}");
      debugPrint("===============================");

      // Créer un mapping des todos distants pour éviter les doublons
      // IMPORTANT: Re-récupérer les todos distants après le nettoyage
      debugPrint("🔄 Re-récupération des todos distants après nettoyage...");
      final cleanRemoteResult = await RemoteDatabaseHelper.getAllTodos(currentId);
      final cleanRemoteTodos = cleanRemoteResult.data ?? [];
      
      final remoteMapping = _createRemoteMapping(cleanRemoteTodos);
      debugPrint("🗺️ Mapping distant créé avec ${remoteMapping.length} entrées");

      // Groupement des actions par type avec validation
      final actionsByType = _groupActionsByType(actions);
      
      // 1. INSERTION : Traiter d'abord les nouveaux todos (avec vérification anti-doublon)
      if (actionsByType['insert']!.isNotEmpty) {
        await _handleInsertionsWithDuplicateCheck(localTodos, actionsByType['insert']!, remoteMapping);
        debugPrint("✅ Insertions terminées");
      }

      // 2. MISE À JOUR : Mettre à jour les todos existants
      if (actionsByType['update']!.isNotEmpty) {
        await _handleUpdatesWithDuplicateCheck(localTodos, actionsByType['update']!, remoteMapping);
        debugPrint("✅ Mises à jour terminées");
      }

      // 3. SUPPRESSION : Supprimer les todos
      if (actionsByType['delete']!.isNotEmpty) {
        await _handleDeletionsWithDuplicateCheck(actionsByType['delete']!, remoteMapping);
        debugPrint("✅ Suppressions terminées");
      }

      // 4. SYNCHRONISATION DESCENDANTE : Récupérer les nouveaux todos distants
      await _handleDownSync(cleanRemoteTodos, localTodos, actionsByType['delete']!);
      debugPrint("✅ Synchronisation descendante terminée");

      debugPrint("🎉 Synchronisation terminée avec succès");
      return SyncResult.success(
        message: 'Synchronisation terminée avec succès',
      );
    } catch (e) {
      debugPrint('❌ Erreur de synchronisation: $e');
      return SyncResult.error('Erreur de synchronisation: ${e.toString()}');
    }
  }

  /// Nettoie TOUS les doublons existants dans la base distante
  Future<void> _cleanAllExistingDuplicates(List<Todo> remoteTodos) async {
    final Map<int, List<Todo>> duplicateGroups = {};
    
    // 1. Identifier tous les doublons
    for (final todo in remoteTodos) {
      if (todo.todo.contains('@')) {
        final parts = todo.todo.split('@');
        if (parts.isNotEmpty) {
          final localId = int.tryParse(parts[0]);
          if (localId != null) {
            duplicateGroups.putIfAbsent(localId, () => []).add(todo);
          }
        }
      }
    }

    // 2. Filtrer pour ne garder que les groupes avec doublons
    final actualDuplicates = <int, List<Todo>>{};
    duplicateGroups.forEach((localId, todos) {
      if (todos.length > 1) {
        actualDuplicates[localId] = todos;
      }
    });

    if (actualDuplicates.isEmpty) {
      debugPrint("✅ Aucun doublon existant trouvé");
      return;
    }

    debugPrint("🔍 Doublons détectés dans ${actualDuplicates.length} groupes:");
    int totalDuplicatesToDelete = 0;
    actualDuplicates.forEach((localId, todos) {
      totalDuplicatesToDelete += todos.length - 1;
      debugPrint("   LocalId $localId: ${todos.length} copies (IDs: ${todos.map((t) => t.id).join(', ')})");
    });
    
    debugPrint("🗑️ Total de doublons à supprimer: $totalDuplicatesToDelete");

    // 3. Supprimer tous les doublons
    int deletedCount = 0;
    for (final entry in actualDuplicates.entries) {
      final localId = entry.key;
      final todos = entry.value;

      try {
        // Trier par ID distant décroissant (garder le plus récent)
        todos.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        
        final todoToKeep = todos.first;
        final todosToDelete = todos.skip(1).toList();

        debugPrint("🧹 LocalId $localId: garde ${todoToKeep.id}, supprime ${todosToDelete.length} doublons");

        // Supprimer tous les doublons
        for (final todoToDelete in todosToDelete) {
          if (todoToDelete.id != null) {
            try {
              final result = await RemoteDatabaseHelper.deleteTodo(todoToDelete.id!);
              if (result.isSuccess) {
                deletedCount++;
                debugPrint("   ✅ Doublon ${todoToDelete.id} supprimé");
              } else {
                debugPrint("   ❌ Erreur suppression ${todoToDelete.id}: ${result.errorMessage}");
              }
              
              // Petite pause pour éviter de surcharger l'API
              await Future.delayed(const Duration(milliseconds: 100));
            } catch (e) {
              debugPrint("   ❌ Exception suppression ${todoToDelete.id}: $e");
            }
          }
        }
      } catch (e) {
        debugPrint("❌ Erreur traitement doublons pour localId $localId: $e");
      }
    }

    debugPrint("🎯 Nettoyage terminé: $deletedCount doublons supprimés sur $totalDuplicatesToDelete");
    
    // Attendre un peu que la base distante se stabilise
    if (deletedCount > 0) {
      debugPrint("⏳ Attente de stabilisation de la base distante...");
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Méthode publique pour nettoyer uniquement les doublons (sans synchronisation)
  Future<bool> cleanDuplicatesOnly() async {
    try {
      debugPrint("🧹 === NETTOYAGE DES DOUBLONS UNIQUEMENT ===");
      
      // Récupérer les todos distants
      final ApiResult<List<Todo>> remoteResult = await RemoteDatabaseHelper.getAllTodos(currentId);
      if (!remoteResult.isSuccess || remoteResult.data == null) {
        debugPrint("❌ Impossible de récupérer les todos distants");
        return false;
      }

      final remoteTodos = remoteResult.data!;
      debugPrint("📊 Total todos distants: ${remoteTodos.length}");

      // Nettoyer les doublons
      await _cleanAllExistingDuplicates(remoteTodos);
      
      debugPrint("✅ === NETTOYAGE TERMINÉ ===");
      return true;
    } catch (e) {
      debugPrint("❌ Erreur lors du nettoyage: $e");
      return false;
    }
  }

  /// Analyse les doublons sans les supprimer (pour diagnostic)
  Future<Map<String, dynamic>> analyzeDuplicates() async {
    try {
      final ApiResult<List<Todo>> remoteResult = await RemoteDatabaseHelper.getAllTodos(currentId);
      if (!remoteResult.isSuccess || remoteResult.data == null) {
        return {'error': 'Impossible de récupérer les todos distants'};
      }

      final remoteTodos = remoteResult.data!;
      final Map<int, List<Todo>> duplicateGroups = {};
      
      // Identifier tous les groupes
      for (final todo in remoteTodos) {
        if (todo.todo.contains('@')) {
          final parts = todo.todo.split('@');
          if (parts.isNotEmpty) {
            final localId = int.tryParse(parts[0]);
            if (localId != null) {
              duplicateGroups.putIfAbsent(localId, () => []).add(todo);
            }
          }
        }
      }

      // Compter les doublons
      final actualDuplicates = <int, List<Todo>>{};
      duplicateGroups.forEach((localId, todos) {
        if (todos.length > 1) {
          actualDuplicates[localId] = todos;
        }
      });

      int totalDuplicates = 0;
      actualDuplicates.forEach((localId, todos) {
        totalDuplicates += todos.length - 1;
      });

      final analysis = {
        'total_todos': remoteTodos.length,
        'duplicate_groups': actualDuplicates.length,
        'total_duplicates_to_delete': totalDuplicates,
        'unique_todos_after_cleanup': remoteTodos.length - totalDuplicates,
        'details': actualDuplicates.map((localId, todos) => MapEntry(
          localId.toString(),
          {
            'count': todos.length,
            'remote_ids': todos.map((t) => t.id).toList(),
            'titles': todos.map((t) => t.todo.split('@').length > 1 ? t.todo.split('@')[1] : t.todo).toList(),
          }
        )),
      };

      debugPrint("📊 === ANALYSE DES DOUBLONS ===");
      debugPrint("📱 Total todos: ${analysis['total_todos']}");
      debugPrint("🔍 Groupes de doublons: ${analysis['duplicate_groups']}");
      debugPrint("🗑️ Doublons à supprimer: ${analysis['total_duplicates_to_delete']}");
      debugPrint("✅ Todos uniques après nettoyage: ${analysis['unique_todos_after_cleanup']}");

      return analysis;
    } catch (e) {
      return {'error': 'Erreur analyse: $e'};
    }
  }

  /// Crée un mapping des todos distants par local_id pour éviter les doublons
  Map<int, List<Todo>> _createRemoteMapping(List<Todo> remoteTodos) {
    final Map<int, List<Todo>> mapping = {};
    
    for (final todo in remoteTodos) {
      if (todo.todo.contains('@')) {
        final parts = todo.todo.split('@');
        if (parts.isNotEmpty) {
          final localId = int.tryParse(parts[0]);
          if (localId != null) {
            mapping.putIfAbsent(localId, () => []).add(todo);
          }
        }
      }
    }
    
    // Log des doublons détectés
    mapping.forEach((localId, todos) {
      if (todos.length > 1) {
        debugPrint("⚠️ DOUBLON détecté pour localId $localId: ${todos.length} copies");
        debugPrint("   IDs distants: ${todos.map((t) => t.id).join(', ')}");
      }
    });
    
    return mapping;
  }

  Map<String, List<int>> _groupActionsByType(List<Map<String, dynamic>> actions) {
    final Map<String, List<int>> result = {
      'insert': <int>[],
      'update': <int>[],
      'delete': <int>[],
    };

    for (final action in actions) {
      if (action['syncrone'] == 0 && action['local_id'] != null) {
        final localId = action['local_id'] as int;
        switch (action['act']) {
          case 'i':
            result['insert']!.add(localId);
            break;
          case 'u':
            result['update']!.add(localId);
            break;
          case 'd':
            result['delete']!.add(localId);
            break;
        }
      }
    }

    return result;
  }

  Future<void> _handleInsertionsWithDuplicateCheck(
    List<Todo> localTodos,
    List<int> toInsertIds,
    Map<int, List<Todo>> remoteMapping,
  ) async {
    for (int localId in toInsertIds) {
      try {
        final localTodo = localTodos.where((todo) => todo.id == localId).firstOrNull;
        
        if (localTodo == null) {
          debugPrint("⚠️ Todo local avec ID $localId introuvable pour insertion");
          await _db.updateActionSyncStatus(localId, 1);
          continue;
        }

        // VÉRIFICATION ANTI-DOUBLON : Vérifier si ce todo existe déjà à distance
        if (remoteMapping.containsKey(localId)) {
          final existingRemoteTodos = remoteMapping[localId]!;
          debugPrint("🔍 Todo localId $localId existe déjà à distance (${existingRemoteTodos.length} copies)");
          
          if (existingRemoteTodos.length == 1) {
            // Une seule copie existe, pas besoin d'insérer
            debugPrint("✅ Todo localId $localId déjà présent, insertion ignorée");
            await _db.updateActionSyncStatus(localId, 1);
            continue;
          } else if (existingRemoteTodos.length > 1) {
            // Plusieurs copies existent, nettoyer d'abord
            debugPrint("🧹 Nettoyage des doublons pour localId $localId...");
            await _cleanDuplicatesForLocalId(localId, existingRemoteTodos);
            // Marquer comme synchronisé car le todo existe déjà
            await _db.updateActionSyncStatus(localId, 1);
            continue;
          }
        }

        // Procéder à l'insertion uniquement si le todo n'existe pas
        final insertData = {
          'todo_id': localTodo.id,
          'todo': localTodo.todo,
          'done': localTodo.isCompleted ? 1 : 0,
          'date': localTodo.date,
          'account_id': currentId,
        };

        debugPrint('📤 Insertion du todo local ID: ${localTodo.id}');
        final result = await RemoteDatabaseHelper.insertTodo(insertData);

        if (result.isSuccess) {
          await _db.updateActionSyncStatus(localId, 1);
          // Mettre à jour le mapping pour éviter des insertions futures
          remoteMapping[localId] = [Todo(
            id: null, // On ne connaît pas l'ID distant généré
            todo: "${localTodo.id}@${localTodo.todo}",
            isCompleted: localTodo.isCompleted,
            date: localTodo.date,
            userId: localTodo.userId,
          )];
          debugPrint('✅ Insertion réussie pour ID: $localId');
        } else {
          debugPrint('❌ Erreur insertion ID $localId: ${result.errorMessage}');
        }
      } catch (e) {
        debugPrint('❌ Exception lors de l\'insertion ID $localId: $e');
      }
    }
  }

  Future<void> _handleUpdatesWithDuplicateCheck(
    List<Todo> localTodos,
    List<int> toUpdateIds,
    Map<int, List<Todo>> remoteMapping,
  ) async {
    for (int localId in toUpdateIds) {
      try {
        final localTodo = localTodos.where((todo) => todo.id == localId).firstOrNull;
        
        if (localTodo == null) {
          debugPrint("⚠️ Todo local avec ID $localId introuvable pour mise à jour");
          await _db.updateActionSyncStatus(localId, 1);
          continue;
        }

        // Vérifier l'existence dans le mapping
        if (remoteMapping.containsKey(localId)) {
          final existingRemoteTodos = remoteMapping[localId]!;
          
          if (existingRemoteTodos.length > 1) {
            // Nettoyer les doublons d'abord
            debugPrint("🧹 Nettoyage des doublons avant mise à jour pour localId $localId");
            await _cleanDuplicatesForLocalId(localId, existingRemoteTodos);
            // Récupérer le todo restant après nettoyage
            final remainingTodo = existingRemoteTodos.first;
            existingRemoteTodos.clear();
            existingRemoteTodos.add(remainingTodo);
          }

          final remoteTodo = existingRemoteTodos.first;
          if (remoteTodo.id != null) {
            // Mise à jour du todo existant
            final updateData = {
              'todo_id': remoteTodo.id,
              'todo': "${localTodo.id}@${localTodo.todo}",
              'done': localTodo.isCompleted ? 1 : 0,
              'date': localTodo.date,
              'user_id': localTodo.userId,
            };

            debugPrint('🔄 Mise à jour du todo distant ID: ${remoteTodo.id}');
            final result = await RemoteDatabaseHelper.updateTodo(updateData);

            if (result.isSuccess) {
              await _db.updateActionSyncStatus(localId, 1);
              debugPrint('✅ Mise à jour réussie pour ID: $localId');
            } else {
              debugPrint('❌ Erreur mise à jour ID $localId: ${result.errorMessage}');
            }
          }
        } else {
          // Le todo n'existe pas à distance, on l'insère
          debugPrint('ℹ️ Todo ID $localId non trouvé à distance, insertion...');
          final insertData = {
            'todo_id': localTodo.id,
            'todo': localTodo.todo,
            'done': localTodo.isCompleted ? 1 : 0,
            'date': localTodo.date,
            'account_id': currentId,
          };

          final result = await RemoteDatabaseHelper.insertTodo(insertData);
          
          if (result.isSuccess) {
            await _db.updateActionSyncStatus(localId, 1);
            // Ajouter au mapping
            remoteMapping[localId] = [Todo(
              id: null,
              todo: "${localTodo.id}@${localTodo.todo}",
              isCompleted: localTodo.isCompleted,
              date: localTodo.date,
              userId: localTodo.userId,
            )];
            debugPrint('✅ Insertion (via update) réussie pour ID: $localId');
          } else {
            debugPrint('❌ Erreur insertion (via update) ID $localId: ${result.errorMessage}');
          }
        }
      } catch (e) {
        debugPrint('❌ Exception lors de la mise à jour ID $localId: $e');
      }
    }
  }

  Future<void> _handleDeletionsWithDuplicateCheck(
    List<int> toDeleteIds,
    Map<int, List<Todo>> remoteMapping,
  ) async {
    for (int localId in toDeleteIds) {
      try {
        if (remoteMapping.containsKey(localId)) {
          final remoteTodos = remoteMapping[localId]!;
          
          // Supprimer TOUS les doublons pour ce localId
          for (final remoteTodo in remoteTodos) {
            if (remoteTodo.id != null) {
              debugPrint('🗑️ Suppression du todo distant ID: ${remoteTodo.id}');
              final result = await RemoteDatabaseHelper.deleteTodo(remoteTodo.id!);
              
              if (result.isSuccess) {
                debugPrint('✅ Suppression réussie pour distant ID: ${remoteTodo.id}');
              } else {
                debugPrint('❌ Erreur suppression distant ID ${remoteTodo.id}: ${result.errorMessage}');
              }
            }
          }
          
          // Retirer du mapping
          remoteMapping.remove(localId);
        } else {
          debugPrint('ℹ️ Todo localId $localId non trouvé à distance pour suppression');
        }
        
        await _db.updateActionSyncStatus(localId, 1);
      } catch (e) {
        debugPrint('❌ Exception lors de la suppression localId $localId: $e');
      }
    }
  }

  /// Nettoie les doublons pour un localId spécifique, garde le plus récent
  Future<void> _cleanDuplicatesForLocalId(int localId, List<Todo> duplicates) async {
    if (duplicates.length <= 1) return;

    try {
      // Trier par ID distant décroissant (le plus récent en premier)
      duplicates.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      
      final todoToKeep = duplicates.first;
      final todosToDelete = duplicates.skip(1).toList();
      
      debugPrint("🧹 Nettoyage localId $localId: garde ${todoToKeep.id}, supprime ${todosToDelete.length} doublons");
      
      for (final todoToDelete in todosToDelete) {
        if (todoToDelete.id != null) {
          final result = await RemoteDatabaseHelper.deleteTodo(todoToDelete.id!);
          if (result.isSuccess) {
            debugPrint("✅ Doublon supprimé: ${todoToDelete.id}");
          } else {
            debugPrint("❌ Erreur suppression doublon ${todoToDelete.id}");
          }
        }
      }
      
      // Mettre à jour la liste pour ne garder que le todo conservé
      duplicates.clear();
      duplicates.add(todoToKeep);
      
    } catch (e) {
      debugPrint("❌ Erreur nettoyage doublons pour localId $localId: $e");
    }
  }

  Future<void> _handleDownSync(
    List<Todo> remoteTodos,
    List<Todo> localTodos,
    List<int> deletedIds,
  ) async {
    final localIds = localTodos.map((todo) => todo.id!).toSet();
    int insertedCount = 0;

    for (Todo remoteTodo in remoteTodos) {
      try {
        if (!remoteTodo.todo.contains('@')) continue;

        final parts = remoteTodo.todo.split('@');
        if (parts.length < 2) continue;

        final localId = int.tryParse(parts[0]);
        if (localId == null) continue;

        // Ne pas réinsérer si l'ID existe localement ou a été supprimé
        if (localIds.contains(localId) || deletedIds.contains(localId)) {
          continue;
        }

        final todoToInsert = Todo(
          id: localId,
          todo: parts.sublist(1).join('@'), // Gère les cas avec @ multiples dans le titre
          isCompleted: remoteTodo.isCompleted,
          date: remoteTodo.date,
          userId: remoteTodo.userId,
        );

        debugPrint('📥 Ajout local du todo distant: ${todoToInsert.todo}');
        final db = await _db.database;
        await db.insert('todo', todoToInsert.toMap());
        insertedCount++;
      } catch (e) {
        debugPrint('❌ Erreur lors de l\'insertion locale: $e');
      }
    }

    debugPrint('📊 Todos insérés depuis la base distante: $insertedCount');
  }

  Future<(List<Todo>, List<Todo>, List<Map<String, dynamic>>)>
      _fetchBothDataSources() async {
    try {
      // Exécution en parallèle pour optimiser les performances
      final futures = await Future.wait([
        RemoteDatabaseHelper.getAllTodos(currentId),
        _db.getAlltodo(),
        _db.getUnsyncedActions(),
      ]);

      final remoteApiResult = futures[0] as ApiResult<List<Todo>>;
      final localTodos = futures[1] as List<Todo>;
      final actions = futures[2] as List<Map<String, dynamic>>;

      final remoteTodos = remoteApiResult.data ?? [];

      if (!remoteApiResult.isSuccess) {
        debugPrint('⚠️ Erreur récupération todos distants: ${remoteApiResult.errorMessage}');
      }

      return (localTodos, remoteTodos, actions);
    } catch (e) {
      debugPrint('❌ Erreur récupération données: $e');
      rethrow;
    }
  }
}