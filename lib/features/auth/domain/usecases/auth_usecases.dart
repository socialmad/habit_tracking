import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:habit_tracker/core/error/failures.dart';
import 'package:habit_tracker/core/usecases/usecase.dart';
import 'package:habit_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:habit_tracker/features/auth/domain/repositories/auth_repository.dart';

class SignIn implements UseCase<UserEntity, AuthParams> {
  final AuthRepository repository;

  SignIn(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(AuthParams params) async {
    return await repository.signIn(params.email, params.password);
  }
}

class SignUp implements UseCase<UserEntity, AuthParams> {
  final AuthRepository repository;

  SignUp(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(AuthParams params) async {
    return await repository.signUp(params.email, params.password);
  }
}

class SignOut implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SignOut(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}

class GetCurrentUser implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

class ResetPassword implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPassword(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(params.email);
  }
}

class ResetPasswordParams extends Equatable {
  final String email;

  const ResetPasswordParams({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthParams extends Equatable {
  final String email;
  final String password;

  const AuthParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
