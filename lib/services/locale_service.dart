import 'package:flutter/material.dart';

enum AppLanguage {
  kk('kk', 'Қазақша'),
  ru('ru', 'Русский'),
  en('en', 'English');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);
}

class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._internal();
  factory LocaleService() => instance;
  LocaleService._internal();

  AppLanguage _currentLanguage = AppLanguage.kk;
  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  String t(String key, [Map<String, dynamic>? params]) {
    String text = _translations[_currentLanguage]?[key] ??
        _translations[AppLanguage.kk]?[key] ??
        key;
    if (params != null && params.isNotEmpty) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v.toString());
      });
    }
    return text;
  }

  String getFormattedDate(DateTime date) {
    switch (_currentLanguage) {
      case AppLanguage.ru:
        const weekdays = [
          'Понедельник',
          'Вторник',
          'Среда',
          'Четверг',
          'Пятница',
          'Суббота',
          'Воскресенье'
        ];
        const months = [
          'января',
          'февраля',
          'марта',
          'апреля',
          'мая',
          'июня',
          'июля',
          'августа',
          'сентября',
          'октября',
          'ноября',
          'декабря'
        ];
        return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
      case AppLanguage.en:
        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
      case AppLanguage.kk:
        const weekdays = [
          'Дүйсенбі',
          'Сейсенбі',
          'Сәрсенбі',
          'Бейсенбі',
          'Жұма',
          'Сенбі',
          'Жексенбі'
        ];
        const months = [
          'қаңтар',
          'ақпан',
          'наурыз',
          'сәуір',
          'мамыр',
          'маусым',
          'шілде',
          'тамыз',
          'қыркүйек',
          'қазан',
          'қараша',
          'желтоқсан'
        ];
        return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }

  String getMonthName(int month) {
    switch (_currentLanguage) {
      case AppLanguage.ru:
        const months = [
          'Январь',
          'Февраль',
          'Март',
          'Апрель',
          'Май',
          'Июнь',
          'Июль',
          'Август',
          'Сентябрь',
          'Октябрь',
          'Ноябрь',
          'Декабрь'
        ];
        return months[month - 1];
      case AppLanguage.en:
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return months[month - 1];
      case AppLanguage.kk:
        const months = [
          'Қаңтар',
          'Ақпан',
          'Наурыз',
          'Сәуір',
          'Мамыр',
          'Маусым',
          'Шілде',
          'Тамыз',
          'Қыркүйек',
          'Қазан',
          'Қараша',
          'Желтоқсан'
        ];
        return months[month - 1];
    }
  }

  String getWeekdayShort(int weekday) {
    switch (_currentLanguage) {
      case AppLanguage.ru:
        const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
        return days[weekday - 1];
      case AppLanguage.en:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[weekday - 1];
      case AppLanguage.kk:
        const days = ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сн', 'Жк'];
        return days[weekday - 1];
    }
  }

  static final Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.kk: {
      // Navigation
      'nav_home': 'Басты',
      'nav_tasks': 'Тапсырмалар',
      'nav_calendar': 'Күнтізбе',
      'nav_search': 'Іздеу',
      'nav_profile': 'Профиль',

      // Profile Screen
      'profile_title': 'Профиль',
      'major_course': 'Ақпараттық жүйелер · 2-курс',
      'student': 'Студент',
      'settings': 'Баптаулар',
      'tasks_completed_stat': 'тапсырма орындалды',
      'on_time_stat': 'уақытында тапсырылды',
      'dark_mode': 'Қараңғы режим',
      'reminders': 'Еске салғыштар',
      'language': 'Тіл',
      'select_language': 'Тілді таңдаңыз',
      'reminders_desc':
          'Дедлайнға 1 күн және 2 сағат қалғанда хабарламалар жіберіледі.',
      'ok': 'Жақсы',
      'enabled': 'Қосулы',
      'logout': 'Шығу',
      'logout_title': 'Жүйеден шығу',
      'logout_confirm': 'Шынымен аккаунтыңыздан шыққыңыз келе ме?',
      'cancel': 'Болдырмау',
      'app_version': 'UniTask · Нұсқа 1.0.0',

      // Home Screen
      'greeting': 'Сәлем, {name}!',
      'weekly_progress': 'Осы аптадағы жетістік',
      'tasks_completed_count': '{completed}/{total} орындалды',
      'add_first_task': 'Алғашқы тапсырманы қосыңыз!',
      'tasks_remaining': 'Керемет! Тағы {count} тапсырма қалды.',
      'all_tasks_completed': 'Тамаша! Барлық тапсырма орындалды! 🎉',
      'filter_all': 'Барлығы',
      'filter_urgent': 'Шұғыл',
      'filter_completed': 'Орындалған',
      'create_task': 'Тапсырма жасау',

      // Tasks Screen
      'tasks_title': 'Тапсырмалар',
      'search_tasks_hint': 'Тапсырманы іздеу',
      'no_tasks': 'Тапсырмалар жоқ',
      'filter_by_subject': 'Пән бойынша сүзу',
      'all_subjects': 'Барлық пәндер',
      'sort_method': 'Сұрыптау тәсілі',
      'sort_default': 'Әдепкі (күйі мен мерзімі бойынша)',
      'sort_deadline': 'Дедлайн мерзімі бойынша',
      'sort_priority': 'Басымдық бойынша (Жоғарыдан төменге)',
      'task_deleted_success': 'Тапсырма сәтті жойылды',

      // Calendar Screen
      'calendar_title': 'Күнтізбе',
      'today': 'Бүгін',
      'no_tasks_for_day': 'Бұл күнге тапсырма жоқ',
      'tasks_for_day': 'Күннің тапсырмалары',

      // Search Screen
      'search_title': 'Іздеу',
      'search_input_hint': 'Тапсырма немесе пәнді іздеу',
      'recent_searches': 'Соңғы іздеулер',
      'clear': 'Тазалау',
      'found_tasks': 'Табылған тапсырмалар',
      'results_count': '{count} нәтиже',
      'no_tasks_found': 'Ешқандай тапсырма табылмады',
      'subjects': 'Пәндер',

      // Connection Banner
      'banner_connected': 'Байланыс орнатылды (Realtime қосулы)',
      'banner_reconnecting': 'Желі жоқ / Қайта қосылуда...',
      'banner_offline': 'Офлайн режимі / Желі жоқ',
      'retry': 'Қайталау',

      // Errors
      'page_not_found': 'Бет табылмады (404)',
      'no_internet': 'Интернет желісі жоқ',
      'server_error': 'Сервер қатесі (500)',
      'go_home': 'Басты бетке оралу',
    },
    AppLanguage.ru: {
      // Navigation
      'nav_home': 'Главная',
      'nav_tasks': 'Задачи',
      'nav_calendar': 'Календарь',
      'nav_search': 'Поиск',
      'nav_profile': 'Профиль',

      // Profile Screen
      'profile_title': 'Профиль',
      'major_course': 'Информационные системы · 2 курс',
      'student': 'Студент',
      'settings': 'Настройки',
      'tasks_completed_stat': 'задач выполнено',
      'on_time_stat': 'сдано вовремя',
      'dark_mode': 'Темный режим',
      'reminders': 'Напоминания',
      'language': 'Язык',
      'select_language': 'Выберите язык',
      'reminders_desc':
          'Уведомления приходят за 1 день и за 2 часа до дедлайна.',
      'ok': 'Понятно',
      'enabled': 'Включено',
      'logout': 'Выйти',
      'logout_title': 'Выход из аккаунта',
      'logout_confirm': 'Вы действительно хотите выйти из аккаунта?',
      'cancel': 'Отмена',
      'app_version': 'UniTask · Версия 1.0.0',

      // Home Screen
      'greeting': 'Привет, {name}!',
      'weekly_progress': 'Прогресс за неделю',
      'tasks_completed_count': '{completed}/{total} выполнено',
      'add_first_task': 'Добавьте первую задачу!',
      'tasks_remaining': 'Отлично! Осталось ещё {count} задач.',
      'all_tasks_completed': 'Отлично! Все задачи выполнены! 🎉',
      'filter_all': 'Все',
      'filter_urgent': 'Срочные',
      'filter_completed': 'Выполненные',
      'create_task': 'Создать задачу',

      // Tasks Screen
      'tasks_title': 'Задачи',
      'search_tasks_hint': 'Поиск задач',
      'no_tasks': 'Задач пока нет',
      'filter_by_subject': 'Фильтр по предметам',
      'all_subjects': 'Все предметы',
      'sort_method': 'Способ сортировки',
      'sort_default': 'По умолчанию (по статусу и сроку)',
      'sort_deadline': 'По дедлайну',
      'sort_priority': 'По приоритету (от высоких)',
      'task_deleted_success': 'Задача успешно удалена',

      // Calendar Screen
      'calendar_title': 'Календарь',
      'today': 'Сегодня',
      'no_tasks_for_day': 'На этот день задач нет',
      'tasks_for_day': 'Задачи на день',

      // Search Screen
      'search_title': 'Поиск',
      'search_input_hint': 'Поиск задач или предметов',
      'recent_searches': 'Недавние поиски',
      'clear': 'Очистить',
      'found_tasks': 'Найденные задачи',
      'results_count': '{count} результатов',
      'no_tasks_found': 'Ничего не найдено',
      'subjects': 'Предметы',

      // Connection Banner
      'banner_connected': 'Связь установлена (Realtime активен)',
      'banner_reconnecting': 'Нет связи / Переподключение...',
      'banner_offline': 'Офлайн режим / Нет сети',
      'retry': 'Повторить',

      // Errors
      'page_not_found': 'Страница не найдена (404)',
      'no_internet': 'Нет интернет-соединения',
      'server_error': 'Ошибка сервера (500)',
      'go_home': 'На главную',
    },
    AppLanguage.en: {
      // Navigation
      'nav_home': 'Home',
      'nav_tasks': 'Tasks',
      'nav_calendar': 'Calendar',
      'nav_search': 'Search',
      'nav_profile': 'Profile',

      // Profile Screen
      'profile_title': 'Profile',
      'major_course': 'Information Systems · 2nd Year',
      'student': 'Student',
      'settings': 'Settings',
      'tasks_completed_stat': 'tasks completed',
      'on_time_stat': 'submitted on time',
      'dark_mode': 'Dark Mode',
      'reminders': 'Reminders',
      'language': 'Language',
      'select_language': 'Select Language',
      'reminders_desc':
          'Reminders are sent 1 day and 2 hours before the deadline.',
      'ok': 'Got it',
      'enabled': 'Enabled',
      'logout': 'Log Out',
      'logout_title': 'Sign Out',
      'logout_confirm': 'Are you sure you want to sign out?',
      'cancel': 'Cancel',
      'app_version': 'UniTask · Version 1.0.0',

      // Home Screen
      'greeting': 'Hello, {name}!',
      'weekly_progress': 'Weekly Progress',
      'tasks_completed_count': '{completed}/{total} completed',
      'add_first_task': 'Add your first task!',
      'tasks_remaining': 'Great! {count} tasks remaining.',
      'all_tasks_completed': 'Awesome! All tasks completed! 🎉',
      'filter_all': 'All',
      'filter_urgent': 'Urgent',
      'filter_completed': 'Completed',
      'create_task': 'Create Task',

      // Tasks Screen
      'tasks_title': 'Tasks',
      'search_tasks_hint': 'Search tasks',
      'no_tasks': 'No tasks yet',
      'filter_by_subject': 'Filter by subject',
      'all_subjects': 'All subjects',
      'sort_method': 'Sort method',
      'sort_default': 'Default (by status and deadline)',
      'sort_deadline': 'By deadline',
      'sort_priority': 'By priority (highest first)',
      'task_deleted_success': 'Task deleted successfully',

      // Calendar Screen
      'calendar_title': 'Calendar',
      'today': 'Today',
      'no_tasks_for_day': 'No tasks for this day',
      'tasks_for_day': 'Tasks for the day',

      // Search Screen
      'search_title': 'Search',
      'search_input_hint': 'Search tasks or subjects',
      'recent_searches': 'Recent searches',
      'clear': 'Clear',
      'found_tasks': 'Found tasks',
      'results_count': '{count} results',
      'no_tasks_found': 'No tasks found',
      'subjects': 'Subjects',

      // Connection Banner
      'banner_connected': 'Connected (Realtime active)',
      'banner_reconnecting': 'No connection / Reconnecting...',
      'banner_offline': 'Offline Mode / Disconnected',
      'retry': 'Retry',

      // Errors
      'page_not_found': 'Page Not Found (404)',
      'no_internet': 'No Internet Connection',
      'server_error': 'Server Error (500)',
      'go_home': 'Go to Home',
    },
  };
}
