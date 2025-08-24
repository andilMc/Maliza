import 'package:maliza/core/models/task_filter_type.dart';
import 'package:maliza/features/app/presentation/widget/task_list_widget.dart';
import 'package:maliza/features/app/provider/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    // S'assurer que les tâches sont chargées et que les statistiques sont à jour
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      taskProvider
          .getTodos(); // Charge les tâches et met à jour les listes filtrées
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Forcer le calcul des statistiques
        final stats = taskProvider.getStatistics();

        return FTabs(
          children: [
            FTabEntry(
              label: Text('Tout (${stats["total"]})'),
              child: TaskListWidget(filterType: TaskFilterType.all),
            ),
            FTabEntry(
              label: Text('Terminées (${stats["completed"]})'),
              child: TaskListWidget(filterType: TaskFilterType.completed),
            ),
            FTabEntry(
              label: Text('En Retard (${stats["overdue"]})'),
              child: TaskListWidget(filterType: TaskFilterType.overdue),
            ),
          ],
        );
      },
    );
  }
}
