import 'dart:convert';
import 'dart:io';
import 'lib/main.dart' as appwrite_func;

class MockRequest {
  final String? body;
  final String method;
  final Map<String, String> headers;
  MockRequest({this.body = '{}', this.method = 'POST', this.headers = const {}});
}

class MockResponse {
  dynamic jsonVal;
  int? statusCodeVal;
  
  dynamic json(Map<String, dynamic> data, [int statusCode = 200]) {
    jsonVal = data;
    statusCodeVal = statusCode;
    return data;
  }
}

class MockContext {
  final MockRequest req;
  final MockResponse res;
  
  MockContext({required this.req, required this.res});
  
  void log(dynamic message) {
    print('[LOG] $message');
  }
  
  void error(dynamic message) {
    print('[ERROR] $message');
  }
}

void main() async {
  print('=== STARTING LOCAL DART FUNCTION DRY-RUN TEST ===');

  final requestBody = jsonEncode({
    'topic': 'Vini Jr',
    'language': 'en',
    'publishImmediately': true,
    'dryRun': true
  });

  final context = MockContext(
    req: MockRequest(body: requestBody, method: 'POST'),
    res: MockResponse()
  );

  print('Triggering main(context)...');
  await appwrite_func.main(context);
  
  print('\n=== DART FUNCTION EXECUTION COMPLETED ===');
  print('Status Code: ${context.res.statusCodeVal}');
  print('Response JSON: ${jsonEncode(context.res.jsonVal)}');
}
