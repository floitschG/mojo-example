// Copyright 2016 the Dart project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'mojo/example/echo.mojom.dart';
import 'package:mojo/core.dart';
import 'package:mojo/application.dart';

class EchoClientApplication extends Application {
  EchoProxy _echoProxy = new EchoProxy.unbound();

  EchoClientApplication.fromHandle(MojoHandle handle)
      : super.fromHandle(handle) {
    onError = _errorHandler;
  }

  @override
  void acceptConnection(String requestorUrl, String resolvedUrl,
      ApplicationConnection connection) {
  }

  _errorHandler(Object e) async {
    MojoHandle.reportLeakedHandles();
  }

  @override
  initialize(List<String> arguments, String url) {
    connectToService(url.replaceAll("client", "server"), _echoProxy);

    _echoProxy.ptr.echoString("hello world").then((response) {
      print("got response: ${response.value}");
    }).whenComplete(() {
      _echoProxy.close();
    });
  }
}

main(args, handleToken) {
  print("client spawned");
  MojoHandle appHandle = new MojoHandle(handleToken);
  new EchoClientApplication.fromHandle(appHandle);
}
