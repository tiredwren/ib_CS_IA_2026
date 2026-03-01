import 'user_model.dart';

class RequirementItem {
  final String id;
  final String text;
  const RequirementItem({required this.id, required this.text});
}

class RequirementCategory {
  final String name;
  final List<RequirementItem> items;
  const RequirementCategory({required this.name, required this.items});
}

class RankRequirements {
  final String rank;
  final List<RequirementCategory> categories;
  const RankRequirements({required this.rank, required this.categories});
}

class ClassRoster {
  final EventModel event;
  final List<UserModel> students;
  ClassRoster({required this.event, required this.students});
}