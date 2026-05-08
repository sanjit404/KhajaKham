// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthLoginEmail>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.loginWithEmail(event.email, event.password);
        if (user != null) emit(AuthSuccess());
        else emit(const AuthFailure('Login failed'));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<AuthSignupEmail>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.signUpWithEmail(event.email, event.password);
        if (user != null) emit(AuthSuccess());
        else emit(const AuthFailure('Signup failed'));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<AuthLoginGoogle>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.signInWithGoogle();
        if (user != null) emit(AuthSuccess());
        else emit(const AuthFailure('Google Sign-In canceled'));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<AuthLogout>((event, emit) async {
      await authRepository.signOut();
      emit(AuthInitial());
    });
  }
}
