//
// -------------------------------------------------------------------------
// Copyright 2018 Bing Djeung
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

struct Configuration: CustomStringConvertible
{
        let leftHost: String
        let leftPort: Int
        let rightHost: String
        let rightPort: Int
        let secret: String
        let cipher: Cipher
        let hash: Hash
        let exchange: Exchange

        var description: String
        {
                return """
                       left_host : \(leftHost)
                       left_port : \(leftPort)
                       right_host: \(rightHost)
                       right_port: \(rightPort)
                       secret    : \(secret)
                       cipher    : \(cipher.rawValue)
                       hash      : \(hash.rawValue)
                       exchange  : \(exchange.rawValue)
                       """
        }
}
