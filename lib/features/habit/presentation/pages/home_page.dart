import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_tracker/features/habit/domain/entities/habit_entity.dart';
import 'package:habit_tracker/features/habit/presentation/bloc/habit_bloc.dart';
import 'package:habit_tracker/features/categories/presentation/bloc/category_bloc.dart';
import 'package:habit_tracker/features/categories/domain/entities/category_entity.dart';
import 'package:habit_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:habit_tracker/features/tracking/presentation/bloc/tracking_bloc.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/filter_bottom_sheet.dart';
import 'package:habit_tracker/features/habit/presentation/widgets/habit_card.dart';
import 'package:habit_tracker/core/widgets/shimmer/habit_skeleton.dart';

class HomePage extends StatefulWidget {
  final String? initialCategoryId;
  const HomePage({super.key, this.initialCategoryId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HabitBloc>().add(
      LoadHabits(categoryId: widget.initialCategoryId, updateCategory: true),
    );
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      context.read<HabitBloc>().add(
        LoadHabits(categoryId: widget.initialCategoryId, updateCategory: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, state) {
        String title = 'My Habits';
        if (state is HabitLoaded && state.filterCategoryId != null) {
          // We need category name. We can get it from CategoryBloc or lookup in state if available
          // But CategoryBloc might be loading.
          // However, HabitCard uses categories list passed around.
          // Let's rely on CategoryBloc state.
          final categoryState = context.watch<CategoryBloc>().state;
          if (categoryState is CategoriesLoaded) {
            final cat = categoryState.categories.firstWhere(
              (c) => c.id == state.filterCategoryId,
              orElse: () => const CategoryEntity(
                id: '',
                userId: '',
                name: 'Category',
                icon: '',
                colorHex: '000000',
              ),
            );
            if (cat.id.isNotEmpty) {
              title = '${cat.icon} ${cat.name}';
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.search_outlined),
                onPressed: () {
                  if (state is HabitLoaded) {
                    showSearch(
                      context: context,
                      delegate: HabitSearchDelegate(
                        context.read<HabitBloc>(),
                        state.habits,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list_outlined),
                onPressed: () {
                  _showFilterBottomSheet(context);
                },
              ),
              PopupMenuButton<HabitSortOption>(
                icon: const Icon(Icons.sort_outlined),
                onSelected: (option) {
                  context.read<HabitBloc>().add(SortHabits(option));
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: HabitSortOption.recentlyAdded,
                    child: Text('Recently Added'),
                  ),
                  const PopupMenuItem(
                    value: HabitSortOption.nameAZ,
                    child: Text('Name (A-Z)'),
                  ),
                  const PopupMenuItem(
                    value: HabitSortOption.currentStreak,
                    child: Text('Current Streak'),
                  ),
                  const PopupMenuItem(
                    value: HabitSortOption.completionRate,
                    child: Text('Most Consistent'),
                  ),
                  const PopupMenuItem(
                    value: HabitSortOption.category,
                    child: Text('Category'),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthSignOutRequested());
                },
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState is Unauthenticated) {
                  context.go('/login');
                }
              },
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, categoryState) {
                  if (state is HabitLoading ||
                      categoryState is CategoryLoading) {
                    return const HabitSkeleton();
                  } else if (state is HabitError) {
                    return _buildErrorState(state.message);
                  } else if (state is HabitLoaded) {
                    final List<CategoryEntity> categories =
                        (categoryState is CategoriesLoaded)
                        ? categoryState.categories
                        : [];

                    final filteredHabits = state.filteredHabits;

                    if (filteredHabits.isEmpty) {
                      return Column(
                        children: [
                          if (categories.isNotEmpty)
                            _buildCategoryFilter(categories, state),
                          Expanded(child: _buildEmptyState(state.searchQuery)),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        if (categories.isNotEmpty)
                          _buildCategoryFilter(categories, state),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              context.read<HabitBloc>().add(LoadHabits());
                              context.read<CategoryBloc>().add(
                                LoadCategories(),
                              );
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredHabits.length,
                              itemBuilder: (context, index) {
                                final habit = filteredHabits[index];
                                return BlocBuilder<TrackingBloc, TrackingState>(
                                  buildWhen: (previous, current) {
                                    return current is TrackingLoaded;
                                  },
                                  builder: (context, trackingState) {
                                    final isCompleted =
                                        trackingState is TrackingLoaded &&
                                        trackingState.completedHabitIds
                                            .contains(habit.id);

                                    return Dismissible(
                                      key: Key('habit_${habit.id}'),
                                      direction: DismissDirection.horizontal,
                                      background: _buildSwipeBackground(
                                        alignment: Alignment.centerLeft,
                                        color: Colors.blue.withValues(
                                          alpha: 0.1,
                                        ),
                                        icon: Icons.edit_outlined,
                                        iconColor: Colors.blue,
                                      ),
                                      secondaryBackground:
                                          _buildSwipeBackground(
                                            alignment: Alignment.centerRight,
                                            color: Colors.red.withValues(
                                              alpha: 0.1,
                                            ),
                                            icon: Icons.delete_outline,
                                            iconColor: Colors.red,
                                          ),
                                      confirmDismiss: (direction) async {
                                        if (direction ==
                                            DismissDirection.startToEnd) {
                                          context.push(
                                            '/edit-habit',
                                            extra: habit,
                                          );
                                          return false;
                                        } else {
                                          return _showDeleteConfirmation(
                                            context,
                                            habit,
                                          );
                                        }
                                      },
                                      onDismissed: (_) {
                                        context.read<HabitBloc>().add(
                                          DeleteHabitEvent(habit.id),
                                        );
                                      },
                                      child: HabitCard(
                                        habit: habit,
                                        categories: categories,
                                        isCompleted: isCompleted,
                                        weeklyProgress:
                                            trackingState is TrackingLoaded
                                            ? trackingState
                                                      .habitWeeklyProgress[habit
                                                      .id] ??
                                                  0
                                            : 0,
                                        onToggle: () {
                                          context.read<TrackingBloc>().add(
                                            ToggleHabitCompletion(habit.id),
                                          );
                                        },
                                        onTap: () {
                                          context.push(
                                            '/habit-details',
                                            extra: habit,
                                          );
                                        },
                                        onEdit: () => context.push(
                                          '/edit-habit',
                                          extra: habit,
                                        ),
                                        onArchive: () {
                                          // Implement archive if needed
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Archiving not implemented yet',
                                              ),
                                            ),
                                          );
                                        },
                                        onDelete: () async {
                                          final confirmed =
                                              await _showDeleteConfirmation(
                                                context,
                                                habit,
                                              );
                                          if (confirmed == true &&
                                              context.mounted) {
                                            context.read<HabitBloc>().add(
                                              DeleteHabitEvent(habit.id),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_home',
            onPressed: () => context.push('/add-habit'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Habit'),
          ),
        );
      },
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: iconColor),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    HabitEntity habit,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
          'Are you sure you want to delete "${habit.name}"? This will also remove its progress history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    List<CategoryEntity> categories,
    HabitLoaded state,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: state.filterCategoryId == null,
              onSelected: (selected) {
                context.read<HabitBloc>().add(
                  FilterHabits(
                    categoryId: null,
                    frequency: state.filterFrequency,
                    archived: state.filterArchived,
                    onlyActiveStreaks: state.filterOnlyActiveStreaks,
                  ),
                );
              },
            ),
          ),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${cat.icon} ${cat.name}'),
                selected: state.filterCategoryId == cat.id,
                onSelected: (selected) {
                  context.read<HabitBloc>().add(
                    FilterHabits(
                      categoryId: selected ? cat.id : null,
                      frequency: state.filterFrequency,
                      archived: state.filterArchived,
                      onlyActiveStreaks: state.filterOnlyActiveStreaks,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            query.isEmpty
                ? 'No habits found! 🐢'
                : 'No results for "$query" 🔍',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (query.isNotEmpty) {
                context.read<HabitBloc>().add(const SearchHabits(''));
              } else {
                context.push('/add-habit');
              }
            },
            icon: Icon(query.isEmpty ? Icons.add_rounded : Icons.clear_rounded),
            label: Text(query.isEmpty ? 'Add a Habit' : 'Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                context.read<HabitBloc>().add(LoadHabits());
                context.read<CategoryBloc>().add(LoadCategories());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class HabitSearchDelegate extends SearchDelegate {
  final HabitBloc habitBloc;
  final List<HabitEntity> allHabits;

  HabitSearchDelegate(this.habitBloc, this.allHabits);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () {
          query = '';
          habitBloc.add(const SearchHabits(''));
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        close(context, null);
        habitBloc.add(const SearchHabits(''));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredHabits = allHabits.where((habit) {
      return habit.name.toLowerCase().contains(query.toLowerCase()) ||
          habit.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filteredHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No habits found for "$query"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredHabits.length,
      itemBuilder: (context, index) {
        final habit = filteredHabits[index];
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(
                int.parse(habit.colorHex, radix: 16),
              ).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                habit.iconAsset,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(
            habit.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: habit.description.isNotEmpty
              ? Text(
                  habit.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            close(context, null);
            context.push('/habit-details', extra: habit);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Show the same results as buildResults
    return buildResults(context);
  }
}
