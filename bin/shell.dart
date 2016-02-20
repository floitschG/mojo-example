// Copyright 2016 the Dart project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mojo/mojo/application.mojom.dart';
import 'package:mojo/mojo/application_connector.mojom.dart';
import 'package:mojo/mojo/shell.mojom.dart';
import 'package:mojo/mojo/service_provider.mojom.dart';
import 'package:mojo/core.dart';
import 'dart:isolate';

class ApplicationConnectorImpl implements ApplicationConnector {
  final ServiceBroker broker;

  ApplicationConnectorImpl(this.broker);

  @override
  void connectToApplication(String applicationUrl, ServiceProviderStub services,
      ServiceProviderProxy exposedServices) {
    ServiceProviderProxy remoteRequested = new ServiceProviderProxy.unbound();
    services.impl = remoteRequested.ptr;
    ApplicationProxy applicationProxy = broker._apps[applicationUrl];
    if (applicationProxy == null) {
      print("application proxy not found $applicationUrl");
      return;
    }
    broker._apps[applicationUrl].ptr.acceptConnection(
        "", remoteRequested, exposedServices?.impl, applicationUrl);
  }

  @override
  duplicate(ApplicationConnectorStub applicationConnectorRequest) {
    applicationConnectorRequest.impl = new ApplicationConnectorImpl(broker);
  }

  ApplicationConnectorStub get stub {
    var stub = new ApplicationConnectorStub.unbound();
    stub.impl = this;
    return stub;
  }
}

class ShellImpl implements Shell {
  final ServiceBroker broker;

  ShellImpl(this.broker);

  void connectToApplication(String applicationUrl, ServiceProviderStub services,
      ServiceProviderProxy exposedServices) {
    new ApplicationConnectorImpl(broker)
        .connectToApplication(applicationUrl, services, exposedServices);
  }

  void createApplicationConnector(
      ApplicationConnectorStub applicationConnectorRequest) {
    applicationConnectorRequest.impl = new ApplicationConnectorImpl(broker);
  }

  ShellStub get stub {
    var stub = new ShellStub.unbound();
    stub.impl = this;
    return stub;
  }
}

class ServiceBroker {
  Map<String, ApplicationProxy> _apps = <String, ApplicationProxy>{};

  spawnApplication(Uri uri) {
    var applicationPipe = new MojoMessagePipe();
    Isolate
        .spawnUri(uri, [uri.toString()], applicationPipe.endpoints[0].handle.h)
        .then((_) {
      var shell = new ShellImpl(this);

      var app = new ApplicationProxy.fromEndpoint(applicationPipe.endpoints[1]);
      app.ptr.initialize(shell.stub, [uri.toString()], uri.toString());
      _apps[uri.toString()] = app;
    });
  }
}

final ServiceBroker serviceBroker = new ServiceBroker();
