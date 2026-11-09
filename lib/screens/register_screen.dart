import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegister;

  const RegisterScreen({super.key, required this.onRegister});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = true;
  bool _submitted = false;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasLetterAndDigit =>
      RegExp(r'[a-zA-Zа-яА-ЯәіңғүұқөһӘІҢҒҮҰҚӨҺ]')
          .hasMatch(_passwordController.text) &&
      RegExp(r'\d').hasMatch(_passwordController.text);

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required Widget suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFFEF4444),
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      final firstError = Validators.validateFullName(_nameController.text) ??
          Validators.validateUniversity(_universityController.text) ??
          Validators.validateEmail(_emailController.text) ??
          Validators.validatePassword(_passwordController.text);
      if (firstError != null) {
        _showErrorSnackBar(firstError);
      }
      return;
    }

    if (!_agreeToTerms) {
      _showErrorSnackBar('Пайдалану шарттарымен келісуіңіз керек');
      return;
    }

    await UserService.instance.register(
      fullName: _nameController.text,
      university: _universityController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    widget.onRegister();
    Navigator.of(context).pop();
  }

  Widget _buildPasswordRuleRow(bool isMet, String label) {
    final color = isMet
        ? const Color(0xFF10B981)
        : (_submitted && _passwordController.text.isNotEmpty
            ? const Color(0xFFEF4444)
            : const Color(0xFF64748B));
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Жаңа аккаунт',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'UniTask-пен оқу күніңді тиімді жоспарлауды баста.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 28),

                // Full Name Field
                const Text(
                  'Аты-жөні',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateFullName,
                  decoration: _buildInputDecoration(
                    hintText: 'Аты-жөніңізді енгізіңіз',
                    suffixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // University Field
                const Text(
                  'Оқу орны',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _universityController,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateUniversity,
                  decoration: _buildInputDecoration(
                    hintText: 'Университет атауы',
                    suffixIcon: const Icon(
                      Icons.account_balance_outlined,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Field
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                  decoration: _buildInputDecoration(
                    hintText: 'Email енгізіңіз',
                    suffixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                const Text(
                  'Құпиясөз',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.validatePassword,
                  decoration: _buildInputDecoration(
                    hintText: 'Кемінде 8 таңба (әріп пен цифр)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildPasswordRuleRow(
                  _hasMinLength,
                  'Кемінде 8 таңба',
                ),
                const SizedBox(height: 4),
                _buildPasswordRuleRow(
                  _hasLetterAndDigit,
                  'Кемінде 1 әріп және 1 цифр',
                ),
                const SizedBox(height: 18),

                // Terms Agreement Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreeToTerms = !_agreeToTerms;
                        });
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: _agreeToTerms
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _agreeToTerms
                                ? const Color(0xFF10B981)
                                : (_submitted
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFCBD5E1)),
                            width: 1.8,
                          ),
                        ),
                        child: _agreeToTerms
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Пайдалану шарттары мен құпиялық саясатына келісемін.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Тіркелуді аяқтау',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to Login Link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Аккаунтыңыз бар ма? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        children: [
                          TextSpan(
                            text: 'Кіру',
                            style: TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
