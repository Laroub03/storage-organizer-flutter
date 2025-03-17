// Base category class with common properties
abstract class BaseCategoryModel {
  final int id;
  final String name;
  final String description;

  BaseCategoryModel({
    required this.id,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson();
}

// Child category
class CategoryModel extends BaseCategoryModel {
  final String parentName;

  CategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required this.parentName,
  });

  // Factory constructor to create a CategoryModel from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json, {String? parentName}) {
    return CategoryModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      parentName: parentName ?? '',
    );
  }

  // Convert CategoryModel to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

// Parent category
class ParentCategoryModel extends BaseCategoryModel {
  final List<CategoryModel> children;

  ParentCategoryModel({
    required super.id,
    required super.name,
    required super.description,
    this.children = const [],
  });

  // Factory constructor to create a ParentCategoryModel from JSON
  factory ParentCategoryModel.fromJson(Map<String, dynamic> json) {
    return ParentCategoryModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      children: const [], // Will be populated separately
    );
  }

  // Factory to create from json with children
  factory ParentCategoryModel.fromJsonWithChildren(
      Map<String, dynamic> json, List<dynamic> childrenJson) {
    final parent = ParentCategoryModel.fromJson(json);
    final children = childrenJson
        .map((childJson) => CategoryModel.fromJson(childJson, parentName: json['name']))
        .toList();

    return ParentCategoryModel(
      id: parent.id,
      name: parent.name,
      description: parent.description,
      children: children,
    );
  }

  // Convert ParentCategoryModel to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  // Helper to add a child category
  void addChild(CategoryModel child) {
    (children).add(child);
  }
}

// Category hierarchy from API
class CategoryHierarchy {
  final Map<String, List<CategoryModel>> hierarchy;

  CategoryHierarchy({required this.hierarchy});

  // Factory constructor to create a CategoryHierarchy from JSON
  factory CategoryHierarchy.fromJson(Map<String, dynamic> json) {
    final hierarchy = <String, List<CategoryModel>>{};

    json.forEach((parentName, childrenList) {
      hierarchy[parentName] = (childrenList as List)
          .map((child) => CategoryModel.fromJson(child, parentName: parentName))
          .toList();
    });

    return CategoryHierarchy(hierarchy: hierarchy);
  }

  // Get all parent category names
  List<String> get parentCategories => hierarchy.keys.toList();

  // Get children of a specific parent
  List<CategoryModel> getChildrenOf(String parentName) {
    return hierarchy[parentName] ?? [];
  }

  // Check if a parent category exists
  bool hasParent(String parentName) {
    return hierarchy.containsKey(parentName);
  }

  // Check if a child category exists under a parent
  bool hasChild(String parentName, String childName) {
    if (!hasParent(parentName)) return false;
    return hierarchy[parentName]!.any((child) => child.name == childName);
  }
}