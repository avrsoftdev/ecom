part of 'home_cubit.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final HomeDataEntity homeData;

  const HomeLoaded({required this.homeData});

  @override
  List<Object?> get props => [homeData];

  HomeLoaded copyWith({
    HomeDataEntity? homeData,
  }) {
    return HomeLoaded(
      homeData: homeData ?? this.homeData,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}
