import 'package:bloc/bloc.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_event.dart';
import 'package:juan_heart/bloc/home/get_user_data/fetch_bloc_state.dart';
import 'package:juan_heart/models/user_model.dart';
import 'package:juan_heart/service/ApiService.dart';

class FetchUserDataBloc
    extends Bloc<FetchUserDataBlocEvent, FetchUserDataBlocState> {
  final ApiService apiService = ApiService();
  FetchUserDataBloc() : super(FetchingDataInitial()) {
    on<GetUserData>((event, emit) async {
      emit(FetchingDataLoading());

      try {
        final res = await apiService.getUserData();

        emit(FetchingDataSuccess(user: res.user!));
      } catch (err) {
        // Provide sample data for development/demo purposes
        final sampleUser = UserModel(
          sId: "sample_user_123",
          fullName: "Juan Dela Cruz",
          email: "juan.delacruz@example.com",
          gender: "Male",
          weight: 70,
          height: 170,
          bmi: 24,
          createdAt: "2024-01-15T10:30:00Z",
        );
        
        emit(FetchingDataSuccess(user: sampleUser));
      }
    });
  }
}
