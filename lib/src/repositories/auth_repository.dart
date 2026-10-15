abstract class AuthRepository {

  // Devuelven "Success" o un mensaje de error listo para mostrar
  Future<String> login({
    required String email,
    required String password
});

  Future<String> register({
    required String name,
    required String email,
    required String password,
});

  // Recuperación de contraseña: lanzan una excepción con un mensaje legible si fallan
  Future<void> sendPasswordResetEmail(String email);

  Future<void> verifyResetCode({required String email, required String code});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> logout();

}
