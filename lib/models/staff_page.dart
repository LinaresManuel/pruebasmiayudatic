import 'user_model.dart';

class StaffPage {
  final List<User> data;
  final int total;
  final int page;
  final int perPage;

  StaffPage({required this.data, required this.total, required this.page, required this.perPage});
} 