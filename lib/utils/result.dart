// Result wrapper for handling success/failure responses
sealed class Result<T> {
  const Result();

  /// Maps the result to another type
  Result<U> map<U>(U Function(T) transform) => switch (this) {
    Success(:final value) => Success(transform(value)),
    Error(:final error) => Error(error),
    Loading() => Loading(),
  };

  /// Get value or null
  T? getOrNull() => switch (this) {
    Success(:final value) => value,
    _ => null,
  };

  /// Check if result is success
  bool get isSuccess => this is Success;

  /// Check if result is error
  bool get isError => this is Error;

  /// Check if result is loading
  bool get isLoading => this is Loading;
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

class Error<T> extends Result<T> {
  final String error;
  const Error(this.error);

  @override
  String toString() => 'Error($error)';
}

class Loading<T> extends Result<T> {
  const Loading();

  @override
  String toString() => 'Loading()';
}
