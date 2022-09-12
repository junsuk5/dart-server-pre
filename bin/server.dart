import 'dart:convert';
import 'dart:io';

import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

final settings = ConnectionSettings(
  host: 'localhost',
  port: 52000,
  user: 'kim',
  password: 'json',
  db: 'myDB',
);
late final MySqlConnection conn;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/boards', _boardsHandler);

Future<Response> _boardsHandler(Request req) async {
  final results = await conn.query('SELECT * FROM board');
  final data = results.map((row) {
    return {
      'id': row.fields['id'],
      'update_time': row.fields['update_time'].toString(),
      'content': row.fields['content']
    };
  }).toList();

  return Response.ok(
    jsonEncode({'success': true, 'data': data}),
    headers: {'Content-type': 'application/json'},
  );
}

Response _rootHandler(Request req) {
  return Response.ok(
    jsonEncode(
      {'success': true, 'data': 'Hello 생존코딩'},
    ),
    headers: {'Content-type': 'application/json'},
  );
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);

  conn = await MySqlConnection.connect(settings);

  print(int.fromEnvironment('MYSQL_PORT', defaultValue: 0));

  print('Server listening on port ${server.port}');
}
