class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
    );
  }
}
