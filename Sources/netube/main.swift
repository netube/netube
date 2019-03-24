//
// -------------------------------------------------------------------------
// Copyright 2018-2019 Bing Djeung
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -------------------------------------------------------------------------
//

let configuration: Configuration = Configuration(
        leftHost: "0.0.0.0",
        leftPort: 56789,
        rightHost: "8.8.8.8",
        rightPort: 443,
        secret: "EyesOnly",
        cipher: .xchacha20poly1305,
        hash: .sha2_256,
        exchange: .x25519
)
print(configuration)

let port: Int = 54321
let server: EchoServer = EchoServer(port: port)
print("Connect with a command line window by entering 'telnet ::1 \(port)'")

server.run()
