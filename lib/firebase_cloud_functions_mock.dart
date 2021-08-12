library firebase_cloud_functions_mock;

import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:mockito/mockito.dart';

class MockCloudFunctions extends Mock implements FirebaseFunctions {
  Map<String, String> _jsonStore = <String, String>{};

  String _convertMapToJson(Map<String, dynamic> parameters) {
    return json.encode(parameters);
  }

  void mockResult(
      {required String functionName,
      required String json,
      dynamic parameters}) {
    functionName = parameters?.isNotEmpty ?? false
        ? functionName + _convertMapToJson(parameters)
        : functionName;
    _jsonStore[functionName] = json;
  }

  String getMockResult(String functionName, dynamic parameters) {
    parameters = Map<String, dynamic>.from(parameters ?? {});
    functionName = parameters == null
        ? functionName
        : (parameters?.isNotEmpty ?? false
            ? functionName + _convertMapToJson(parameters)
            : functionName);
    assert(
        _jsonStore[functionName] != null, 'No mock result for $functionName');
    return _jsonStore[functionName]!;
  }

  HttpsCallable getHttpsCallable({required String functionName}) {
    return HttpsCallableMock._(this, functionName);
  }

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    return HttpsCallableMock._(this, name);
  }
}

class HttpsCallableMock extends Mock implements HttpsCallable {
  HttpsCallableMock._(this._cloudFunctions, this._functionName);

  final MockCloudFunctions _cloudFunctions;
  final String _functionName;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) {
    final decoded =
        json.decode(_cloudFunctions.getMockResult(_functionName, parameters));
    return Future.value(HttpsCallableResultMock._(decoded));
  }

  /// The timeout to use when calling the function. Defaults to 60 seconds.
  Duration timeout = const Duration(seconds: 60);
}

class HttpsCallableResultMock<T> extends Mock
    implements HttpsCallableResult<T> {
  HttpsCallableResultMock._(T _data) : data = _data;

  /// Returns the data that was returned from the Callable HTTPS trigger.
  final T data;
}
