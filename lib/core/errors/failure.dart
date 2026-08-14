/// Base type for recoverable, user-facing failures surfaced by repositories
/// and services. Deliberately not an [Exception]/[Error] — callers convert
/// caught exceptions into a [Failure] at the repository boundary so the UI
/// layer never deals with raw platform/DB exceptions.
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
