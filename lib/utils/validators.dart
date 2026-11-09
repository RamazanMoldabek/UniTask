class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );
  static final RegExp _letterRegExp = RegExp(r'[a-zA-Zа-яА-ЯәіңғүұқөһӘІҢҒҮҰҚӨҺ]');
  static final RegExp _digitRegExp = RegExp(r'\d');

  /// Тексереді: Аты-жөні бос болмауы керек
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Аты-жөніңізді енгізіңіз';
    }
    if (value.trim().length < 2) {
      return 'Аты-жөні кемінде 2 таңбадан тұруы керек';
    }
    return null;
  }

  /// Тексереді: Оқу орны бос болмауы керек
  static String? validateUniversity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Оқу орнын енгізіңіз';
    }
    if (value.trim().length < 2) {
      return 'Оқу орны атауы кемінде 2 таңбадан тұруы керек';
    }
    return null;
  }

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

  /// Тексереді: Құпиясөз бос болмауы керек, кемінде 8 таңба, әріп пен цифр болуы қажет
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Құпиясөзді енгізіңіз';
    }
    if (value.length < 8) {
      return 'Құпиясөз кемінде 8 таңбадан тұруы керек';
    }
    if (!_letterRegExp.hasMatch(value) || !_digitRegExp.hasMatch(value)) {
      return 'Құпиясөзде кемінде 1 әріп және 1 цифр болуы керек';
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
