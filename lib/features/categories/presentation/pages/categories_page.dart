import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_tracker/features/categories/presentation/bloc/category_bloc.dart';
import 'package:habit_tracker/features/habit/presentation/bloc/habit_bloc.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
    context.read<HabitBloc>().add(LoadHabits());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CategoryBloc, CategoryState>(
            listener: (context, state) {
              if (state is CategoryError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
          ),
        ],
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, categoryState) {
            return BlocBuilder<HabitBloc, HabitState>(
              builder: (context, habitState) {
                if (categoryState is CategoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (categoryState is CategoriesLoaded) {
                  final categories = categoryState.categories;
                  final habits = (habitState is HabitLoaded)
                      ? habitState.habits
                      : [];

                  if (categories.isEmpty) {
                    return const Center(child: Text('No categories yet'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final categoryHabits = habits
                          .where((h) => h.categoryId == category.id)
                          .toList();

                      Color categoryColor = Colors.grey;
                      try {
                        categoryColor = Color(
                          int.parse(category.colorHex, radix: 16),
                        );
                      } catch (_) {}

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: categoryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        color: categoryColor.withValues(alpha: 0.05),
                        child: InkWell(
                          onTap: () {
                            // Filter by category (will implement in HomePage)
                            context.push('/home', extra: category.id);
                          },
                          onLongPress: () {
                            context.push('/create-category', extra: category);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        category.icon,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                      ),
                                      onPressed: () => _showDeleteDialog(
                                        category.id,
                                        category.name,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${categoryHabits.length} habits',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildHabitStack(categoryHabits),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_category',
        onPressed: () => context.push('/create-category'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitStack(List habits) {
    if (habits.isEmpty) return const SizedBox(height: 24);

    return SizedBox(
      height: 24,
      child: Stack(
        children: List.generate(
          habits.length > 4 ? 4 : habits.length,
          (index) => Positioned(
            left: index * 16.0,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.grey.shade100,
                  child: Text(
                    habits[index].iconAsset,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "$name"? Habits in this category will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CategoryBloc>().add(DeleteCategoryEvent(id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
