String? validateNewPassword(String password, String confirm) {
  if (password.length < 4) return 'Mật khẩu cần ít nhất 4 ký tự.';
  if (password != confirm) return 'Hai mật khẩu không giống nhau.';
  return null;
}
