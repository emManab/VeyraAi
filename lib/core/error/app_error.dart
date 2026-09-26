sealed class AppError {
  final String message;
  const AppError(this.message);
}

final class NetworkError extends AppError {
  const NetworkError([super.message = 'No internet connection.']);
}

final class TimeoutError extends AppError {
  const TimeoutError([super.message = 'Request timed out. Please try again.']);
}

final class AuthError extends AppError {
  const AuthError([super.message = 'Invalid API key. Check your settings.']);
}

final class RateLimitError extends AppError {
  const RateLimitError(
      [super.message = 'Rate limit reached. Please wait and retry.']);
}

final class InvalidResponseError extends AppError {
  const InvalidResponseError(
      [super.message = 'Unexpected response from AI provider.']);
}

final class StorageError extends AppError {
  const StorageError([super.message = 'Local storage error.']);
}

final class UnknownError extends AppError {
  const UnknownError([super.message = 'An unexpected error occurred.']);
}
