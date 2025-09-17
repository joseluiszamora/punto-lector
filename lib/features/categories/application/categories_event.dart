import 'package:equatable/equatable.dart';
import '../../../data/models/category.dart';

// Events
abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategoriesTree extends CategoriesEvent {}

class LoadCategoriesByLevel extends CategoriesEvent {
  final int level;
  final String? parentId;

  const LoadCategoriesByLevel({this.level = 0, this.parentId});

  @override
  List<Object?> get props => [level, parentId];
}

class SearchCategories extends CategoriesEvent {
  final String searchTerm;

  const SearchCategories(this.searchTerm);

  @override
  List<Object?> get props => [searchTerm];
}

class LoadCategoryPath extends CategoriesEvent {
  final String categoryId;

  const LoadCategoryPath(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class SelectCategory extends CategoriesEvent {
  final Category? category;

  const SelectCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class ToggleExpandCategory extends CategoriesEvent {
  final String categoryId;

  const ToggleExpandCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

// States
abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<Category> categories;
  final Category? selectedCategory;
  final List<Category> categoryPath;
  final Set<String> expandedCategories;
  final bool isSearchMode;
  final String? searchTerm;

  const CategoriesLoaded({
    required this.categories,
    this.selectedCategory,
    this.categoryPath = const [],
    this.expandedCategories = const {},
    this.isSearchMode = false,
    this.searchTerm,
  });

  @override
  List<Object?> get props => [
    categories,
    selectedCategory,
    categoryPath,
    expandedCategories,
    isSearchMode,
    searchTerm,
  ];

  CategoriesLoaded copyWith({
    List<Category>? categories,
    Category? selectedCategory,
    List<Category>? categoryPath,
    Set<String>? expandedCategories,
    bool? isSearchMode,
    String? searchTerm,
    bool clearSelectedCategory = false,
  }) {
    return CategoriesLoaded(
      categories: categories ?? this.categories,
      selectedCategory:
          clearSelectedCategory
              ? null
              : (selectedCategory ?? this.selectedCategory),
      categoryPath: categoryPath ?? this.categoryPath,
      expandedCategories: expandedCategories ?? this.expandedCategories,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

class CategoriesError extends CategoriesState {
  final String message;

  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
