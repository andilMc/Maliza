import 'package:flutter/rendering.dart';
import 'package:maliza/features/app/presentation/widget/task_list_widget.dart';
import 'package:maliza/features/app/presentation/widget/weather.dart';
import 'package:maliza/features/app/provider/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isInitialized = false;

  // Conserve l'état même si l'onglet change
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTasks();
      _isInitialized = true;
    });
  }

  Future<void> _initializeTasks() async {
    try {
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.getTodos();
    } catch (e) {
      debugPrint('Erreur lors du chargement des tâches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important pour AutomaticKeepAliveClientMixin

    return  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Weather(),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Liste des Tâches",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // Statistiques rapides
                Consumer<TaskProvider>(
                  builder: (context, taskProvider, _) {
                    final stats = taskProvider.getStatistics();
                    return Text(
                      '${stats['completed']}/${stats['total']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          TaskListWidget(),
        ],
    );
  }
}
