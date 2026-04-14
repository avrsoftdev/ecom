import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/usecases/get_home_data_usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHomeDataUseCase getHomeDataUseCase;

  HomeCubit({required this.getHomeDataUseCase}) : super(HomeInitial());

  Future<void> loadHomeData() async {
    emit(HomeLoading());
    
    final result = await getHomeDataUseCase(NoParams());
    
    result.fold(
      (failure) {
        String errorMessage = 'Something went wrong';
        if (failure is ServerFailure) {
          errorMessage = 'Server error occurred';
        } else if (failure is NetworkFailure) {
          errorMessage = 'No internet connection';
        }
        emit(HomeError(message: errorMessage));
      },
      (homeData) {
        emit(HomeLoaded(homeData: homeData));
      },
    );
  }

  Future<void> refreshHomeData() async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      // Keep the current data while refreshing
      emit(HomeLoading());
      await loadHomeData();
    } else {
      await loadHomeData();
    }
  }
}
