import 'package:maliza/core/data/account_cache.dart';
import 'package:maliza/core/models/todo.dart';
import 'package:maliza/core/models/todo_actions.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Databasehelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDb("todo.db");
      debugPrint("✅ Database created");
      return _database!;
    }
  }

  Future<Database> _initDb(String databaseName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE todo (
            todo_id INTEGER PRIMARY KEY AUTOINCREMENT,
            todo TEXT NOT NULL,
            date TEXT NOT NULL,
            done INTEGER NOT NULL,
            account_id INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE todo_action (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            local_id INTEGER NOT NULL,
            act TEXT NOT NULL,
            syncrone INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER NOT NULL,
            img TEXT
          )
        ''');

        // Index pour améliorer les performances
        await db.execute('CREATE INDEX idx_todo_account ON todo(account_id)');
        await db.execute(
          'CREATE INDEX idx_action_sync ON todo_action(local_id, syncrone)',
        );
      },
      onUpgrade: null,
      onDowngrade: null,
    );
  }

  Future<int> insertTodo(Todo todo) async {
    final db = await database;

    return await db.transaction((txn) async {
      final id = await txn.insert('todo', todo.toMap());

      await txn.insert('todo_action', {
        "local_id": id,
        "act": TodoActions.insert.action,
        "syncrone": 0,
      });

      debugPrint('📝 Todo inséré avec ID: $id');
      return id;
    });
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await database;

    return await db.transaction((txn) async {
      final result = await txn.update(
        'todo',
        todo.toMap(),
        where: 'todo_id = ?',
        whereArgs: [todo.id],
      );

      if (result > 0) {
        // Vérifier s'il existe déjà une action non synchronisée pour cette tâche
        final existingActions = await txn.query(
          'todo_action',
          where: 'local_id = ? AND syncrone = 0',
          whereArgs: [todo.id],
        );

        // Ne créer une nouvelle action que s'il n'y en a pas déjà une non synchronisée
        if (existingActions.isEmpty) {
          await txn.insert('todo_action', {
            'local_id': todo.id,
            'act': TodoActions.update.action,
            'syncrone': 0,
          });
        }
      }

      debugPrint('🔄 Todo mis à jour ID: ${todo.id}');
      return result;
    });
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;

    return await db.transaction((txn) async {
      final result = await txn.delete(
        'todo',
        where: 'todo_id = ?',
        whereArgs: [id],
      );

      if (result > 0) {
        // Supprimer les actions précédentes non synchronisées pour cette tâche
        await txn.delete(
          'todo_action',
          where: 'local_id = ? AND syncrone = 0',
          whereArgs: [id],
        );

        // Ajouter l'action de suppression
        await txn.insert('todo_action', {
          'local_id': id,
          'act': TodoActions.delete.action,
          'syncrone': 0,
        });
      }

      debugPrint('🗑️ Todo supprimé ID: $id');
      return result;
    });
  }

  Future<List<Todo>> getAlltodo() async {
    final db = await database;
    final currentId = (await AccountCache.getCurrentAccountId())!;

    final result = await db.query(
      'todo',
      where: "account_id = ?",
      whereArgs: [currentId],
      orderBy: 'todo_id DESC', // Tri pour une meilleure UX
    );

    return result.map((todo) => Todo.fromMap(todo)).toList();
  }

  Future<List<Map<String, dynamic>>> getUnsyncedActions() async {
    final db = await database;
    final result = await db.query(
      'todo_action',
      where: 'syncrone = ?',
      whereArgs: [0],
      orderBy:
          'created_at ASC', // Traiter les actions dans l'ordre chronologique
    );

    debugPrint('📋 Actions non synchronisées trouvées: ${result.length}');
    return result;
  }

  /// Met à jour le statut de synchronisation pour toutes les actions d'un ID local donné
  Future<void> updateActionSyncStatus(int localId, int syncStatus) async {
    final db = await database;
    final result = await db.update(
      'todo_action',
      {'syncrone': syncStatus},
      where: 'local_id = ? AND syncrone = ?',
      whereArgs: [localId, 0],
    );

    debugPrint('🔄 Actions synchronisées pour ID $localId: $result');
  }

  /// Nettoie les actions synchronisées (optionnel, pour éviter l'accumulation)
  Future<int> cleanSynchronizedActions() async {
    final db = await database;
    final result = await db.delete(
      'todo_action',
      where: 'syncrone = ? AND created_at < datetime("now", "-7 days")',
      whereArgs: [1],
    );

    debugPrint('🧹 Actions synchronisées nettoyées: $result');
    return result;
  }

  /// Compte les actions en attente de synchronisation
  Future<int> countPendingActions() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todo_action WHERE syncrone = 0',
    );

    final count = result.first['count'] as int;
    debugPrint('⏳ Actions en attente: $count');
    return count;
  }

  Future<int> insertProfile(int userId, String profileImagePath) async {
    final db = await database;
    final profiles = await db.query(
      'profile',
      where: 'account_id = ?',
      whereArgs: [userId],
    );

    if (profiles.isEmpty) {
      return await db.insert('profile', {
        'account_id': userId,
        'img': profileImagePath,
      });
    } else {
      return await db.update(
        'profile',
        {'img': profileImagePath},
        where: 'account_id = ?',
        whereArgs: [userId],
      );
    }
  }

  Future<String> getProfileImage(int currentAccount) async {
    final db = await database;
    final profiles = await db.query(
      'profile',
      where: 'account_id = ?',
      whereArgs: [currentAccount],
    );

    if (profiles.isEmpty) {
      return '';
    }

    return profiles.first['img']?.toString() ?? '';
  }

  /// Diagnostique pour déboguer les problèmes de synchronisation
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final db = await database;
    final currentId = (await AccountCache.getCurrentAccountId())!;

    final todoCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todo WHERE account_id = ?',
      [currentId],
    );

    final actionCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todo_action WHERE syncrone = 0',
    );

    final actionsByType = await db.rawQuery('''
      SELECT act, COUNT(*) as count 
      FROM todo_action 
      WHERE syncrone = 0 
      GROUP BY act
    ''');

    return {
      'todos_count': todoCount.first['count'],
      'pending_actions': actionCount.first['count'],
      'actions_by_type': actionsByType,
    };
  }
}
