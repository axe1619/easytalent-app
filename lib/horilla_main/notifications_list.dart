import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../res/consts/app_colors.dart';
import '../domain/models/notification_model.dart';
import '../domain/usecases/fetch_notifications_usecase.dart';
import '../domain/usecases/get_unread_count_usecase.dart';
import '../domain/usecases/delete_notification_usecase.dart';
import '../domain/usecases/delete_notifications_usecase.dart';

class NotificationsModal extends StatefulWidget {
  final FetchNotificationsUseCase fetchNotificationsUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final BulkDeleteNotificationsUseCase bulkDeleteNotificationsUseCase;
  final String? employeeName;

  const NotificationsModal({
    super.key,
    required this.fetchNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.deleteNotificationUseCase,
    required this.bulkDeleteNotificationsUseCase,
    this.employeeName,
  });

  @override
  _NotificationsModalState createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal> {
  List<NotificationModel> notifications = [];
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        hasMore &&
        !isLoading) {
      currentPage++;
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    if (!hasMore || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await widget.fetchNotificationsUseCase.execute(currentPage);
      
      setState(() {
        if (currentPage == 1) {
          notifications = response.results.where((n) => !n.deleted).toList();
        } else {
          final newNotifications = response.results.where((n) => !n.deleted).toList();
          final existingIds = notifications.map((n) => n.id).toSet();
          notifications.addAll(
            newNotifications.where((n) => !existingIds.contains(n.id))
          );
        }
        
        hasMore = response.next != null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await widget.bulkDeleteNotificationsUseCase.execute();
      setState(() {
        notifications.clear();
        currentPage = 1;
        hasMore = true;
        isLoading = false;
      });
      await fetchNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar notificaciones: $e'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  Future<void> deleteIndividualNotification(int notificationId) async {
    try {
      await widget.deleteNotificationUseCase.execute(notificationId);
      setState(() {
        notifications.removeWhere((item) => item.id == notificationId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar notificación: $e'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            // AppBar del modal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notificaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmar'),
                                content: const Text('¿Estás seguro de que deseas eliminar todas las notificaciones?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      clearAllNotifications();
                                    },
                                    child: Text(
                                      'Eliminar',
                                      style: TextStyle(color: primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text(
                            'Limpiar todo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Lista de notificaciones
            Expanded(
              child: isLoading && notifications.isEmpty
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300]!,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 12.0,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 8.0),
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.4,
                                        height: 12.0,
                                        color: Colors.grey[300],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                color: blackColor,
                                size: 92,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "No hay notificaciones para mostrar",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                  color: blackColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return buildListItem(context, notification);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildListItem(BuildContext context, NotificationModel notification) {
    final timestamp = DateTime.parse(notification.timestamp);
    final timeAgo = timeago.format(timestamp, locale: 'es');
    final user = widget.employeeName ?? 'Usuario';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: whiteColor,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: 4.0,
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (notification.unread)
                  Icon(
                    Icons.circle,
                    color: secondaryColor,
                    size: 12,
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
            title: Text(
              notification.verb,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035,
                fontWeight: FontWeight.bold,
                color: blackColor,
              ),
            ),
            subtitle: Text(
              '$timeAgo por $user',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.032,
                fontWeight: FontWeight.normal,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.close,
                size: MediaQuery.of(context).size.width * 0.04,
                color: Colors.grey,
              ),
              onPressed: () {
                deleteIndividualNotification(notification.id);
              },
            ),
          ),
          Divider(
            height: 1.0,
            color: Colors.grey[400]?.withAlpha(51),
          ),
        ],
      ),
    );
  }
}
