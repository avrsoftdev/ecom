import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_location_usecase.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final GetCurrentLocationAddressUseCase getLocationUseCase;

  LocationCubit({required this.getLocationUseCase}) : super(LocationInitial());

  Future<void> fetchLocation() async {
    emit(LocationLoading());
    final result = await getLocationUseCase(NoParams());
    result.fold(
      (failure) => emit(LocationError(failure.message)),
      (address) => emit(LocationLoaded(address)),
    );
  }
}
