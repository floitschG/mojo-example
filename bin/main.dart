// Copyright 2016 the Dart project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'shell.dart';

main(args, msg) {
  Uri serverUri = Platform.script.resolve("package:example/server.dart");
  serviceBroker.spawnApplication(serverUri);
  Uri clientUri = Platform.script.resolve("package:example/client.dart");
  serviceBroker.spawnApplication(clientUri);
}
