class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Тексереді: Email бос болмауы керек және жарамды форматта болуы қажет
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Электрондық поштаны енгізіңіз';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Электрондық пошта пішімі қате (мысалы: user@aitu.kz)';
    }
    return null;
  }

  /// Тексереді: Тапсырма тақырыбы бос болмауы керек және тым қысқа болмауы қажет
  static String? validateTaskTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Тапсырма атауын енгізіңіз';
    }
    if (value.trim().length < 3) {
      return 'Атау кемінде 3 таңбадан тұруы керек';
    }
    return null;
  }
}

