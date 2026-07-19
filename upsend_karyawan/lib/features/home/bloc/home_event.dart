import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Dipanggil saat homepage dibuka, dan juga saat balik dari CheckInPage
class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// Dipanggil saat tombol "Check Out" ditekan — tanpa selfie/lokasi.
class HomeCheckOutRequested extends HomeEvent {
  const HomeCheckOutRequested();
}