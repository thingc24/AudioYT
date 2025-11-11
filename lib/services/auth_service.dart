import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      // Đảm bảo trạng thái sạch sẽ nếu trước đó còn giữ phiên
      // Không bắt buộc nhưng giúp giảm khả năng tự đăng nhập lại tài khoản cũ trên một số thiết bị
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In error: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      // Sign out Firebase first
      await FirebaseAuth.instance.signOut();
      // Sign out Google to buộc xuất hiện account picker lần tiếp theo
      final GoogleSignIn googleSignIn = GoogleSignIn();
      // signOut() xóa phiên hiện tại; disconnect() thu hồi liên kết để chắc chắn không auto-sign-in
      await googleSignIn.signOut();
      try {
        await googleSignIn.disconnect();
      } catch (_) {
        // Một số nền tảng có thể ném lỗi nếu chưa có kết nối để revoke; bỏ qua an toàn
      }
    } catch (e) {
      print("Sign out error: $e");
    }
  }
}
