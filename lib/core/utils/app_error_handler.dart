import 'package:firebase_auth/firebase_auth.dart';

/// Central error handler for converting raw exceptions into human-friendly messages.
class AppErrorHandler {
  AppErrorHandler._();

  /// Map any error or exception to a clear, user-friendly string.
  static String toFriendlyMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred.';

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid sign-in credentials. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'email-already-in-use':
          return 'This email address is already in use by another account.';
        case 'operation-not-allowed':
          return 'Sign-in method is currently disabled.';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        case 'popup-closed-by-user':
          return 'Sign-in was cancelled.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email address using a different sign-in method.';
        default:
          return error.message ?? 'Sign-in failed. Please check your details and try again.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unavailable':
          return 'Server is temporarily unavailable. Please check your connection.';
        case 'not-found':
          return 'The requested resource was not found.';
        case 'already-exists':
          return 'This item already exists.';
        default:
          return error.message ?? 'Database request failed. Please try again.';
      }
    }

    final str = error.toString();

    if (str.contains('Username taken')) {
      return 'That username is already taken. Please pick another one.';
    }
    if (str.contains('Not signed in')) {
      return 'You must be signed in to perform this action.';
    }
    if (str.contains('SocketException') || str.contains('NetworkException') || str.contains('Failed host lookup')) {
      return 'No internet connection. Please check your connection.';
    }

    // Clean up generic Exception: prefix if present
    var cleanMsg = str;
    if (cleanMsg.startsWith('Exception: ')) {
      cleanMsg = cleanMsg.substring(11);
    }

    if (cleanMsg.length > 100 || cleanMsg.contains('{')) {
      return 'Something went wrong. Please try again in a moment.';
    }

    return cleanMsg.isNotEmpty ? cleanMsg : 'An unexpected error occurred. Please try again.';
  }
}
