import 'failure.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = ResultFailure<T>;

  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class ResultFailure<T> extends Result<T> {
  final Failure failure;
  const ResultFailure(this.failure);
}
