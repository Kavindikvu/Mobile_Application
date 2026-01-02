import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/ui/components/app_section_header.dart';
import '../../../core/ui/components/app_list_tile.dart';
import '../../../core/ui/components/info_banner.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/tokens.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/domain/calendar_event.dart';

final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  return ref.read(calendarRepositoryProvider).getEvents();
});

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarEventsProvider);
    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => InfoBanner(
          type: InfoBannerType.error,
          title: AppStrings.calendarErrorTitle,
          message: e.toString(),
          action: TextButton(
            onPressed: () => ref.refresh(calendarEventsProvider),
            child: const Text(AppStrings.retry),
          ),
        ),
      data: (events) {
          final grouped = _groupByDate(events);
          final dates = grouped.keys.toList()..sort();
          if (dates.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(calendarEventsProvider),
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: InfoBanner(
                  type: InfoBannerType.info,
                  title: AppStrings.calendarEmptyTitle,
                  message: AppStrings.calendarEmptyMsg,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(calendarEventsProvider),
            child: ListView.builder(
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final dayEvents = grouped[date]!;
                return _CalendarDaySection(
                  date: date,
                  events: dayEvents,
                  onEventTap: (event) => _showEventDetails(context, event),
                );
              },
            ),
          );
      },
    );
  }

  Map<DateTime, List<CalendarEvent>> _groupByDate(List<CalendarEvent> events) {
    final Map<DateTime, List<CalendarEvent>> map = {};
    for (final e in events) {
      final key = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) => _EventDetailsSheet(event: event),
    );
  }
}

class _CalendarDaySection extends StatelessWidget {
  final DateTime date; 
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onEventTap;
  const _CalendarDaySection({
    required this.date,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE, MMM d');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: df.format(date)),
          ...events.map((e) => _EventTile(
            event: e,
            onTap: () => onEventTap(e),
          )).toList(),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  const _EventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('h:mm a');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${tf.format(event.startTime)} - ${tf.format(event.endTime)}${event.location != null ? ' • ${event.location}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailsSheet extends StatelessWidget {
  final CalendarEvent event;

  const _EventDetailsSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('h:mm a');
    final df = DateFormat('EEEE, MMM d, yyyy');
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      Icons.event,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (event.description != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            event.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: df.format(event.startTime),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.schedule,
                label: 'Time',
                value: '${tf.format(event.startTime)} - ${tf.format(event.endTime)}',
              ),
              if (event.location != null) ...[
                const SizedBox(height: AppSpacing.md),
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: event.location!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
