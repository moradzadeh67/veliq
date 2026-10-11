import '../../../services/settings_repository.dart';

/// Base class for settings states.
///
/// `sealed` so that UI can switch over states exhaustively without a default.
sealed class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);
}

class SettingsFailure extends SettingsState {
  final String message;

  const SettingsFailure(this.message);
}
