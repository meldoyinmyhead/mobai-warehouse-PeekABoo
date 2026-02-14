import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// States
abstract class EmployeeSettingsState extends Equatable {
  const EmployeeSettingsState();
  @override
  List<Object> get props => [];
}

class EmployeeSettingsLoaded extends EmployeeSettingsState {
  final bool notificationsEnabled;
  final bool locationEnabled;
  final bool darkModeEnabled;
  final String language;

  const EmployeeSettingsLoaded({
    this.notificationsEnabled = true,
    this.locationEnabled = true,
    this.darkModeEnabled = false,
    this.language = 'English',
  });

  EmployeeSettingsLoaded copyWith({
    bool? notificationsEnabled,
    bool? locationEnabled,
    bool? darkModeEnabled,
    String? language,
  }) {
    return EmployeeSettingsLoaded(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
    );
  }

  @override
  List<Object> get props => [notificationsEnabled, locationEnabled, darkModeEnabled, language];
}

// Cubit
class EmployeeSettingsCubit extends Cubit<EmployeeSettingsState> {
  EmployeeSettingsCubit() : super(const EmployeeSettingsLoaded());

  void toggleNotifications(bool value) {
    if (state is EmployeeSettingsLoaded) {
      emit((state as EmployeeSettingsLoaded).copyWith(notificationsEnabled: value));
    }
  }

  void toggleLocation(bool value) {
    if (state is EmployeeSettingsLoaded) {
      emit((state as EmployeeSettingsLoaded).copyWith(locationEnabled: value));
    }
  }

  void toggleDarkMode(bool value) {
    if (state is EmployeeSettingsLoaded) {
      emit((state as EmployeeSettingsLoaded).copyWith(darkModeEnabled: value));
    }
  }
}
