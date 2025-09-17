import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/categories_repository.dart';
import '../../../data/models/category.dart';
import 'categories_event.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository _repository;

  CategoriesBloc(this._repository) : super(CategoriesInitial()) {
    on<LoadCategoriesTree>(_onLoadCategoriesTree);
    on<LoadCategoriesByLevel>(_onLoadCategoriesByLevel);
    on<SearchCategories>(_onSearchCategories);
    on<LoadCategoryPath>(_onLoadCategoryPath);
    on<SelectCategory>(_onSelectCategory);
    on<ToggleExpandCategory>(_onToggleExpandCategory);
  }

  Future<void> _onLoadCategoriesTree(
    LoadCategoriesTree event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());

    try {
      final categories = await _repository.getCategoriesTree();
      emit(CategoriesLoaded(categories: categories, isSearchMode: false));
    } catch (e) {
      emit(CategoriesError('Error al cargar categorías: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCategoriesByLevel(
    LoadCategoriesByLevel event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());

    try {
      final categories = await _repository.getCategoriesByLevel(
        level: event.level,
        parentId: event.parentId,
      );
      emit(CategoriesLoaded(categories: categories, isSearchMode: false));
    } catch (e) {
      emit(CategoriesError('Error al cargar categorías: ${e.toString()}'));
    }
  }

  Future<void> _onSearchCategories(
    SearchCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    if (event.searchTerm.trim().isEmpty) {
      add(LoadCategoriesTree());
      return;
    }

    emit(CategoriesLoading());

    try {
      final categories = await _repository.searchCategories(event.searchTerm);
      emit(
        CategoriesLoaded(
          categories: categories,
          isSearchMode: true,
          searchTerm: event.searchTerm,
        ),
      );
    } catch (e) {
      emit(CategoriesError('Error en búsqueda: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCategoryPath(
    LoadCategoryPath event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      final path = await _repository.getCategoryPath(event.categoryId);

      if (state is CategoriesLoaded) {
        final currentState = state as CategoriesLoaded;
        emit(currentState.copyWith(categoryPath: path));
      }
    } catch (e) {
      emit(CategoriesError('Error al cargar ruta: ${e.toString()}'));
    }
  }

  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<CategoriesState> emit,
  ) async {
    if (state is CategoriesLoaded) {
      final currentState = state as CategoriesLoaded;

      // Load category path if category is selected
      List<Category> categoryPath = [];
      if (event.category != null) {
        try {
          categoryPath = await _repository.getCategoryPath(event.category!.id);
        } catch (e) {
          // Ignore path loading errors
        }
      }

      emit(
        currentState.copyWith(
          selectedCategory: event.category,
          categoryPath: categoryPath,
          clearSelectedCategory: event.category == null,
        ),
      );
    }
  }

  void _onToggleExpandCategory(
    ToggleExpandCategory event,
    Emitter<CategoriesState> emit,
  ) {
    if (state is CategoriesLoaded) {
      final currentState = state as CategoriesLoaded;
      final expandedCategories = Set<String>.from(
        currentState.expandedCategories,
      );

      if (expandedCategories.contains(event.categoryId)) {
        expandedCategories.remove(event.categoryId);
      } else {
        expandedCategories.add(event.categoryId);
      }

      emit(currentState.copyWith(expandedCategories: expandedCategories));
    }
  }

  // Helper methods
  void loadMainCategories() => add(const LoadCategoriesByLevel(level: 0));

  void loadSubcategories(String parentId) =>
      add(LoadCategoriesByLevel(level: 1, parentId: parentId));

  void searchCategories(String term) => add(SearchCategories(term));

  void selectCategory(Category? category) => add(SelectCategory(category));

  void toggleExpand(String categoryId) => add(ToggleExpandCategory(categoryId));

  void clearSearch() => add(LoadCategoriesTree());
}
