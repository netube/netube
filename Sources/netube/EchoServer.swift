import Foundation
import Socket
import Dispatch

class EchoServer {
        private static let quitCommand: String = ":quit"
        private static let shutdownCommand: String = ":off"
        private static let bufferSize: Int = 4096

        private let port: Int
        private var listenSocket: Socket? = nil
        private var isRunning: Bool = true
        private var connectedSockets: [Int32: Socket] = [Int32: Socket]()
        private let socketLockQueue: DispatchQueue = DispatchQueue(label: "org.netube.EchoServer.socketLockQueue")
        
        init(port: Int) {
                self.port = port
        }
        deinit {
                connectedSockets.values.forEach { $0.close() }
                listenSocket?.close()
        }
        
        func run() {
                let queue = DispatchQueue.global(qos: .userInteractive)
                queue.async { [unowned self] in
                        do {
                                try self.listenSocket = Socket.create(family: .inet6)
                                guard let socket: Socket = self.listenSocket else {
                                        print("Unable to unwrap socket...")
                                        return
                                }
                                try socket.listen(on: self.port)
                                print("Listening on port: \(socket.listeningPort)")

                                repeat {
                                        let newSocket: Socket = try socket.acceptClientConnection()
                                        print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                                        print("Socket Signature: \(String(describing: newSocket.signature?.description))")

                                        self.addNewConnection(socket: newSocket)
                                } while self.isRunning

                        } catch let error {
                                guard let socketError: Socket.Error = error as? Socket.Error else {
                                        print("Unexpected error...")
                                        return
                                }
                                if self.isRunning {
                                        print("Error reported:\n \(socketError.description)")
                                }
                        }
                }
                dispatchMain()
        }
        
        private func addNewConnection(socket: Socket) {
                
                // Add the new socket to the list of connected sockets...
                socketLockQueue.sync { [unowned self, socket] in
                        self.connectedSockets[socket.socketfd] = socket
                }
                
                let queue: DispatchQueue = DispatchQueue.global(qos: .default)
                
                // Create the run loop work item and dispatch to the default priority global queue...
                queue.async { [unowned self, socket] in
                        
                        var isConnected: Bool = true
                        
                        var readData: Data = Data(capacity: EchoServer.bufferSize)
                        
                        do {
                                try socket.write(from: "Hello, type '\(EchoServer.quitCommand)' to end session" +
                                        "or '\(EchoServer.shutdownCommand)' to stop server.\n")
                                repeat {
                                        let bytesRead = try socket.read(into: &readData)
                                        if bytesRead > 0 {
                                                guard let response = String(data: readData, encoding: .utf8) else {
                                                        print("Error decoding response...")
                                                        readData.count = 0
                                                        break
                                                }
                                                try self.dealingResponse(socket: socket, response: response, keep: &isConnected)
                                        }
                                        if bytesRead == 0 {
                                                isConnected = false
                                                break
                                        }
                                        readData.count = 0
                                        
                                } while isConnected
                                
                                print("Socket: \(socket.remoteHostname):\(socket.remotePort) closed...")
                                socket.close()
                                self.socketLockQueue.sync { [unowned self, socket] in
                                        self.connectedSockets[socket.socketfd] = nil
                                }
                                
                        } catch let error {
                                guard let socketError = error as? Socket.Error else {
                                        print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                                        return
                                }
                                if self.isRunning {
                                        print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                                }
                        }
                }
        }
        private func dealingResponse(socket: Socket, response: String, keep: inout Bool) throws {
                if response.lowercased.hasPrefix(EchoServer.shutdownCommand) {
                        print("Shutdown requested by connection at \(socket.remoteHostname):\(socket.remotePort)")
                        self.shutdownServer()
                        return
                }
                print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
                let reply: String = "Server response: \n\(response)\n"
                try socket.write(from: reply)

                if response.lowercased.hasPrefix(EchoServer.quitCommand) || response.hasSuffix(EchoServer.quitCommand) {
                        keep = false
                }
        }

        private func shutdownServer() {
                print("\nShutdown in progress...")
                isRunning = false
                connectedSockets.values.forEach { $0.close() }
                listenSocket?.close()
                DispatchQueue.main.sync {
                        exit(0)
                }
        }
}
