import 'dart:io';
import '../models/location_model.dart';

abstract class AttendanceEvent {}

class FetchNearbyLocations extends AttendanceEvent {}

class SelectLocation extends AttendanceEvent {
  final LocationModel location;
  SelectLocation(this.location);
}

class PhotoCaptured extends AttendanceEvent {
  final File photo;
  PhotoCaptured(this.photo);
}

class GoToCamera extends AttendanceEvent {}

class SubmitCheckIn extends AttendanceEvent {}

class PreviousStep extends AttendanceEvent {}

class ResetAttendance extends AttendanceEvent {}
