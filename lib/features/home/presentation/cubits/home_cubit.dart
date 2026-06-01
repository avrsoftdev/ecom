import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/home_data_entity.dart';
import '../../domain/usecases/get_home_data_usecase.dart';
import '../../../../core/error/failures.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetHomeDataUseCase getHomeDataUseCase;

  HomeCubit({required this.getHomeDataUseCase}) : super(HomeInitial());

  Future<void> loadHomeData({
    double? userLatitude,
    double? userLongitude,
  }) async {
    emit(HomeLoading());
    
    final result = await getHomeDataUseCase(
      GetHomeDataParams(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      ),
    );
    
    if (isClosed) return;
    
    result.fold(
      (failure) {
        String errorMessage = 'Something went wrong';
        if (failure is ServerFailure) {
          errorMessage = 'Server error occurred';
        } else if (failure is NetworkFailure) {
          errorMessage = 'No internet connection';
        }
        if (!isClosed) {
          emit(HomeError(message: errorMessage));
        }
      },
      (homeData) {
        try {
          if (!isClosed) {
            emit(HomeLoaded(homeData: homeData));
          }
        } catch (e, stackTrace) {
          print('Error emitting HomeLoaded: $e');
          print(stackTrace);
          if (!isClosed) {
            emit(HomeError(message: 'Error loading home data: $e'));
          }
        }
      },
    );
  }

  Future<void> refreshHomeData({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      // Keep the current data while refreshing
      if (!isClosed) {
        emit(HomeLoading());
      }
      await loadHomeData(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
    } else {
      await loadHomeData(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
    }
  }
}
