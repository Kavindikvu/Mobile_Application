import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/domain/class_model.dart';
import '../../../../core/domain/class_filter.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/data/services/enrollment_service.dart';
import '../../../../core/data/services/subject_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../data/class_repository.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  ClassFilter _currentFilter = const ClassFilter();
  bool _showFilters = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentFilter = _currentFilter.copyWith(
          searchQuery: _searchController.text.trim().isEmpty 
              ? null 
              : _searchController.text.trim(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    final slivers = classesAsync.when<List<Widget>>(
      loading: () => const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _LoadingState(),
        ),
      ],
      error: (error, stackTrace) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(error: error.toString()),
        ),
      ],
      data: (classes) {
        final filteredClasses = _applyFilters(classes);
        if (filteredClasses.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                hasFilters: _currentFilter.hasActiveFilters || _searchController.text.isNotEmpty,
                onClearFilters: () {
                  setState(() {
                    _currentFilter = const ClassFilter();
                    _searchController.clear();
                  });
                },
              ),
            ),
          ];
        }

        return [
          _ClassList(classes: filteredClasses),
        ];
      },
    );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(classesProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    tooltip: 'Filters',
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SearchAndFilterSection(
                searchController: _searchController,
                showFilters: _showFilters,
                currentFilter: _currentFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _currentFilter = filter;
                  });
                },
              ),
            ),
            ...slivers,
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }

  List<ClassModel> _applyFilters(List<ClassModel> classes) {
    if (!_currentFilter.hasActiveFilters) {
      return classes;
    }

    return classes.where((classModel) {
      // Search query filter
      if (_currentFilter.searchQuery?.isNotEmpty == true) {
        final query = _currentFilter.searchQuery!.toLowerCase();
        if (!classModel.title.toLowerCase().contains(query) &&
            !classModel.description.toLowerCase().contains(query) &&
            !classModel.instructorName.toLowerCase().contains(query) &&
            !classModel.subjects.any((s) => s.toLowerCase().contains(query))) {
          return false;
        }
      }

      // Subject filter
      if (_currentFilter.subjects.isNotEmpty) {
        if (!_currentFilter.subjects.any((subject) => classModel.subjects.contains(subject))) {
          return false;
        }
      }

      // Type filter
      if (_currentFilter.types.isNotEmpty) {
        if (!_currentFilter.types.contains(classModel.type)) {
          return false;
        }
      }

      // Grade level filter
      if (_currentFilter.gradeLevel?.isNotEmpty == true) {
        if (!classModel.gradeLevel.toLowerCase().contains(_currentFilter.gradeLevel!.toLowerCase())) {
          return false;
        }
      }

      // Price filter
      if (_currentFilter.minPrice != null && classModel.price < _currentFilter.minPrice!) {
        return false;
      }
      if (_currentFilter.maxPrice != null && classModel.price > _currentFilter.maxPrice!) {
        return false;
      }

      // Rating filter
      if (_currentFilter.minRating != null && classModel.rating < _currentFilter.minRating!) {
        return false;
      }

      return true;
    }).toList();
  }
}

class _SearchAndFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final bool showFilters;
  final ClassFilter currentFilter;
  final ValueChanged<ClassFilter> onFilterChanged;

  const _SearchAndFilterSection({
    required this.searchController,
    required this.showFilters,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _SearchBar(controller: searchController),
          if (showFilters) ...[
            const SizedBox(height: AppSpacing.md),
            _FilterSection(
              currentFilter: currentFilter,
              onFilterChanged: onFilterChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: 'Search classes, instructors, subjects...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.controller.clear();
                  setState(() {});
                },
                tooltip: 'Clear search',
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final ClassFilter currentFilter;
  final ValueChanged<ClassFilter> onFilterChanged;

  const _FilterSection({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currentFilter.hasActiveFilters)
              TextButton(
                onPressed: () {
                  onFilterChanged(const ClassFilter());
                },
                child: const Text('Clear All'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickFilters(
          currentFilter: currentFilter,
          onFilterChanged: onFilterChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _TypeFilters(
          currentFilter: currentFilter,
          onFilterChanged: onFilterChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SubjectFilters(
          currentFilter: currentFilter,
          onFilterChanged: onFilterChanged,
        ),
      ],
    );
  }
}

class _QuickFilters extends ConsumerWidget {
  final ClassFilter currentFilter;
  final ValueChanged<ClassFilter> onFilterChanged;

  const _QuickFilters({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    
    return subjectsAsync.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (subjects) {
        if (subjects.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: subjects.map((subject) {
            final isSelected = currentFilter.subjects.contains(subject);
            return FilterChip(
              label: Text(subject),
              selected: isSelected,
              onSelected: (selected) {
                final newSubjects = List<String>.from(currentFilter.subjects);
                if (selected) {
                  newSubjects.add(subject);
                } else {
                  newSubjects.remove(subject);
                }
                onFilterChanged(currentFilter.copyWith(subjects: newSubjects));
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _TypeFilters extends StatelessWidget {
  final ClassFilter currentFilter;
  final ValueChanged<ClassFilter> onFilterChanged;

  const _TypeFilters({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            label: const Text('Online'),
            selected: currentFilter.types.contains(ClassType.online),
            onSelected: (selected) {
              final newTypes = List<ClassType>.from(currentFilter.types);
              if (selected) {
                newTypes.add(ClassType.online);
              } else {
                newTypes.remove(ClassType.online);
              }
              onFilterChanged(currentFilter.copyWith(types: newTypes));
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilterChip(
            label: const Text('In-Person'),
            selected: currentFilter.types.contains(ClassType.inPerson),
            onSelected: (selected) {
              final newTypes = List<ClassType>.from(currentFilter.types);
              if (selected) {
                newTypes.add(ClassType.inPerson);
              } else {
                newTypes.remove(ClassType.inPerson);
              }
              onFilterChanged(currentFilter.copyWith(types: newTypes));
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilterChip(
            label: const Text('Hybrid'),
            selected: currentFilter.types.contains(ClassType.hybrid),
            onSelected: (selected) {
              final newTypes = List<ClassType>.from(currentFilter.types);
              if (selected) {
                newTypes.add(ClassType.hybrid);
              } else {
                newTypes.remove(ClassType.hybrid);
              }
              onFilterChanged(currentFilter.copyWith(types: newTypes));
            },
          ),
        ),
      ],
    );
  }
}

class _SubjectFilters extends StatelessWidget {
  final ClassFilter currentFilter;
  final ValueChanged<ClassFilter> onFilterChanged;

  const _SubjectFilters({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grade Level',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          value: currentFilter.gradeLevel,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          hint: const Text('All Grades'),
          items: const [
            DropdownMenuItem(value: '8-12', child: Text('8-12')),
            DropdownMenuItem(value: '9-12', child: Text('9-12')),
            DropdownMenuItem(value: '10-12', child: Text('10-12')),
            DropdownMenuItem(value: '11-12', child: Text('11-12')),
          ],
          onChanged: (value) {
            onFilterChanged(currentFilter.copyWith(gradeLevel: value));
          },
        ),
      ],
    );
  }
}

class _ClassList extends StatelessWidget {
  final List<ClassModel> classes;

  const _ClassList({required this.classes});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final classModel = classes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ClassCard(classModel: classModel),
            );
          },
          childCount: classes.length,
        ),
      ),
    );
  }
}

class _ClassCard extends ConsumerWidget {
  final ClassModel classModel;

  const _ClassCard({required this.classModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () => _showClassDetails(context, classModel),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      classModel.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(context, classModel.type),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      _getTypeText(classModel.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '👨‍🏫 ${classModel.instructorName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (classModel.subjects.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Icon(
                      Icons.book,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    ...classModel.subjects.map((subject) => Chip(
                      label: Text(
                        subject,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )),
                  ],
                ),
              ],
              if (classModel.medium != null && classModel.medium!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Medium: ${classModel.medium}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    classModel.ratingText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      classModel.type == ClassType.online ? 'Online' : classModel.location ?? 'TBD',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      classModel.schedule.isNotEmpty 
                          ? classModel.schedule.first 
                          : 'Schedule TBD',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    classModel.priceText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                classModel.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '🎯 Grade Level: ${classModel.gradeLevel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '👥 ${classModel.currentEnrollment}/${classModel.maxStudents}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showClassDetails(context, classModel),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: classModel.isAvailable
                          ? () => _enrollStudentInClass(context, ref, classModel)
                          : null,
                      child: Text(classModel.isAvailable ? 'Enroll Now' : 'Full'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(BuildContext context, ClassType type) {
    switch (type) {
      case ClassType.online:
        return Theme.of(context).colorScheme.primary;
      case ClassType.inPerson:
        return Theme.of(context).colorScheme.secondary;
      case ClassType.hybrid:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  String _getTypeText(ClassType type) {
    switch (type) {
      case ClassType.online:
        return 'Online';
      case ClassType.inPerson:
        return 'In-Person';
      case ClassType.hybrid:
        return 'Hybrid';
    }
  }

  void _showClassDetails(BuildContext context, ClassModel classModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ClassDetailsScreen(classModel: classModel),
      ),
    );
  }
}

Future<void> _enrollStudentInClass(
  BuildContext context,
  WidgetRef ref,
  ClassModel classModel,
) async {
  final authState = ref.read(authProvider);
  final selectedChild = authState.selectedChild;
  final user = authState.user;

  String? studentId;
  if (selectedChild != null && selectedChild.id.isNotEmpty) {
    studentId = selectedChild.id;
  } else if (user != null && (!user.isParent || user.isStudent)) {
    studentId = user.id;
  }

  if (studentId == null || studentId.isEmpty) {
    final message = user?.isParent == true
        ? 'Please select a student profile to enroll in classes'
        : 'We couldn\'t determine which student to enroll. Please try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final rootNavigator = Navigator.of(context, rootNavigator: true);
  var isDialogOpen = true;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const Center(
      child: CircularProgressIndicator(),
    ),
  ).whenComplete(() {
    isDialogOpen = false;
  });

  try {
    final enrollmentService = ref.read(enrollmentServiceProvider);
    final subjectService = ref.read(subjectServiceProvider);

    List<String> subjectIds = [];
    if (classModel.subjects.isNotEmpty) {
      try {
        final allSubjects = await subjectService.getAllSubjects();
        final classSubjects = allSubjects.where((s) => s.classId == classModel.id).toList();

        for (final subjectName in classModel.subjects) {
          final matchingSubject = classSubjects.firstWhere(
            (s) => s.name.toLowerCase() == subjectName.toLowerCase(),
            orElse: () => classSubjects.isNotEmpty ? classSubjects.first : throw Exception(),
          );
          if (matchingSubject.subjectId.isNotEmpty) {
            subjectIds.add(matchingSubject.subjectId);
          }
        }
      } catch (e) {
        subjectIds = [];
      }
    }

    final enrollments = await enrollmentService.enrollInClass(
      classId: classModel.id,
      studentId: studentId,
      subjectIds: subjectIds,
    );

    if (context.mounted && isDialogOpen && rootNavigator.canPop()) {
      rootNavigator.pop();
      isDialogOpen = false;
    }

    if (context.mounted) {
      final subjectCount = enrollments.length;

      String message;
      if (enrollments.every((e) => e.isApproved)) {
        message = 'Successfully enrolled in ${classModel.title}';
        if (subjectCount > 1) {
          message += ' for $subjectCount subjects';
        }
      } else if (enrollments.any((e) => e.isPending)) {
        final pendingCount = enrollments.where((e) => e.isPending).length;
        message = 'Enrollment request submitted for ${classModel.title}';
        if (pendingCount > 1) {
          message += ' ($pendingCount subjects pending approval)';
        } else {
          message += ' (pending approval)';
        }
      } else {
        message = 'Enrollment processed for ${classModel.title}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (context.mounted && isDialogOpen && rootNavigator.canPop()) {
      rootNavigator.pop();
      isDialogOpen = false;
    }

    if (context.mounted) {
      String errorMessage = 'Failed to enroll in class';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('schedule conflict') || errorString.contains('conflict')) {
        errorMessage = 'Cannot enroll: Schedule conflict detected';
      } else if (errorString.contains('student not found') ||
          (errorString.contains('not found') && errorString.contains('student'))) {
        errorMessage =
            'Student profile not found in the system. Please ensure the student is registered.';
      } else if (errorString.contains('class not found') ||
          (errorString.contains('not found') && errorString.contains('class'))) {
        errorMessage = 'Class not found. The class may have been removed or is no longer available.';
      } else if (errorString.contains('404')) {
        errorMessage = 'Resource not found. Please verify the student and class information.';
      } else if (errorString.contains('400') || errorString.contains('bad request')) {
        errorMessage = 'Invalid enrollment request. Please check the class details.';
      } else if (errorString.contains('500') || errorString.contains('internal server error')) {
        errorMessage = 'Server error. Please try again later.';
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.length > 100) {
          errorMessage = 'Enrollment failed. Please check your connection and try again.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}

class _ClassDetailsScreen extends ConsumerWidget {
  final ClassModel classModel;

  const _ClassDetailsScreen({required this.classModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Add to wishlist
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ClassHeader(classModel: classModel),
            const SizedBox(height: AppSpacing.lg),
            _ClassDescription(classModel: classModel),
            const SizedBox(height: AppSpacing.lg),
            _ClassSchedule(classModel: classModel),
            const SizedBox(height: AppSpacing.lg),
            _ClassInformation(classModel: classModel),
            const SizedBox(height: AppSpacing.lg),
            _ClassPricing(classModel: classModel),
            const SizedBox(height: AppSpacing.lg),
            _EnrollmentSection(classModel: classModel),
          ],
        ),
      ),
    );
  }
}

class _ClassHeader extends StatelessWidget {
  final ClassModel classModel;

  const _ClassHeader({required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          classModel.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '👨‍🏫 ${classModel.instructorName}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (classModel.subjects.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Icon(
                Icons.book,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              ...classModel.subjects.map((subject) => Chip(
                label: Text(subject),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              )),
            ],
          ),
        ],
        if (classModel.medium != null && classModel.medium!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.language,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Medium: ${classModel.medium}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              classModel.ratingText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _ClassDescription extends StatelessWidget {
  final ClassModel classModel;

  const _ClassDescription({required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Class',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          classModel.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ClassSchedule extends StatelessWidget {
  final ClassModel classModel;

  const _ClassSchedule({required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...classModel.schedule.map((schedule) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(schedule),
            ],
          ),
        )),
      ],
    );
  }
}

class _ClassInformation extends StatelessWidget {
  final ClassModel classModel;

  const _ClassInformation({required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(
          icon: Icons.school,
          label: 'Grade Level',
          value: classModel.gradeLevel,
        ),
        _InfoRow(
          icon: Icons.people,
          label: 'Max Students',
          value: classModel.maxStudents.toString(),
        ),
        _InfoRow(
          icon: Icons.group,
          label: 'Current Enrollment',
          value: classModel.currentEnrollment.toString(),
        ),
        _InfoRow(
          icon: Icons.calendar_today,
          label: 'Start Date',
          value: _formatDate(classModel.startDate),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassPricing extends StatelessWidget {
  final ClassModel classModel;

  const _ClassPricing({required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PricingRow(
          label: 'Monthly Fee',
          value: classModel.priceText,
        ),
        _PricingRow(
          label: 'Materials',
          value: '\$${(classModel.price * 0.15).toStringAsFixed(0)}',
        ),
        const Divider(),
        _PricingRow(
          label: 'Total',
          value: '\$${(classModel.price * 1.15).toStringAsFixed(0)}/month',
          isTotal: true,
        ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PricingRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentSection extends ConsumerWidget {
  final ClassModel classModel;

  const _EnrollmentSection({required this.classModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Add to wishlist
            },
            icon: const Icon(Icons.favorite_border),
            label: const Text('Add to Wishlist'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: classModel.isAvailable
                ? () => _enrollStudentInClass(context, ref, classModel)
                : null,
            icon: const Icon(Icons.school),
            label: Text(classModel.isAvailable ? 'Enroll Now' : 'Class Full'),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Loading classes...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilters ? 'No classes match your filters' : 'No classes available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilters
                  ? 'Try adjusting your search criteria'
                  : 'Check back later for new classes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: onClearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
