// Copyright 2016 the Dart project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/core.dart';
import 'package:mojo/application.dart';


import 'mojo/example/echo.mojom.dart';

class EchoImpl implements Echo {
  EchoStub _stub;
  EchoApplication _application;

  EchoImpl(this._application, MojoMessagePipeEndpoint endpoint) {
    _stub = new EchoStub.fromEndpoint(endpoint, this);
    _stub.onError = _errorHandler;
  }

  echoString(String value, [Function responseFactory]) {
    return responseFactory(value);
  }

  Future close() => _stub.close();

  _errorHandler(Object e) => _application.removeService(this);
}

class EchoApplication extends Application {
  List<EchoImpl> _echoServices;
  bool _closing;

  EchoApplication.fromHandle(MojoHandle handle)
      : _closing = false,
        _echoServices = [],
        super.fromHandle(handle) {
    onError = _errorHandler;
  }

  @override
  void acceptConnection(String requestorUrl, String resolvedUrl,
      ApplicationConnection connection) {
    connection.provideService(Echo.serviceName, _createService);
  }

  void removeService(EchoImpl service) {
    if (!_closing) {
      _echoServices.remove(service);
    }
  }

  EchoImpl _createService(MojoMessagePipeEndpoint endpoint) {
    if (_closing) {
      endpoint.close();
      return null;
    }
    var echoService = new EchoImpl(this, endpoint);
    _echoServices.add(echoService);
    return echoService;
  }

  _errorHandler(Object e) async {
    _closing = true;
    for (var service in _echoServices) {
      await service.close();
    }
    MojoHandle.reportLeakedHandles();
  }
}

main(args, handleToken) {
  print("server spawned");
  MojoHandle appHandle = new MojoHandle(handleToken);
  new EchoApplication.fromHandle(appHandle);
}
