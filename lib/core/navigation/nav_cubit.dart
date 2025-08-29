import 'package:flutter_bloc/flutter_bloc.dart';

class NavCubit extends Cubit<int> {
  NavCubit({int initialIndex = 0}) : super(initialIndex);
  void setTab(int index) => emit(index);
}
