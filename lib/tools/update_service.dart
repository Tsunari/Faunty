// Conditional export selecting the appropriate implementation.
// - On web (where `dart.library.js_interop` is available), use the real implementation.
// - On other platforms, use a safe no-op stub that compiles everywhere.
export 'update_service_stub.dart'
  if (dart.library.js_interop) 'update_service_web.dart';
