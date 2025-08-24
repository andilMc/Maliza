import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:maliza/features/app/presentation/bloc/list_todos.dart';
import 'package:maliza/features/app/provider/task_provider.dart';
import 'package:provider/provider.dart';

class RecherchePage extends StatelessWidget {
  RecherchePage({super.key});
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        Row(
          spacing: 10,
          children: [
            Icon(FIcons.search, color: Colors.black38),
            Expanded(
              child: Consumer<TaskProvider>(
                builder: (inneContext, taskProvider, _) => FTextField(
                  controller: searchController,
                  autofocus: true,
                  hint: 'Rechereche ...',
                  onChange: (keyword) {
                    taskProvider.search(keyword);
                  },
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Consumer<TaskProvider>(
            builder: (inneContext, taskProvider, _) => ListTodos(
              todos: taskProvider.todos,
              taskProvider: taskProvider,
              checked: taskProvider.todosChecked,
            ),
          ),
        ),
      ],
    );
  }
}
