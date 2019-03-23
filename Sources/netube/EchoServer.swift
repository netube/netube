import Foundation
import Dispatch
import Socket

class EchoServer
{
        private static let quitCommand: String = ":quit"
        private static let shutdownCommand: String = ":off"
        private static let bufferSize: Int = 4096

        private let port: Int
        private var listenSocket: Socket? = nil
        private var isRunning: Bool = true
        private var connectedSockets: [Int32: Socket] = [Int32: Socket]()
        private let socketLockQueue: DispatchQueue = DispatchQueue(label: "org.netube.socketLockQueue")

        init(port: Int)
        {
                self.port = port
        }

        deinit
        {
                connectedSockets.values.forEach
                {
                        $0.close()
                }
                listenSocket?.close()
        }

        func run()
        {
                let queue = DispatchQueue.global(qos: .userInteractive)
                queue.async
                { [unowned self] in
                        do
                        {
                                try self.listenSocket = Socket.create(family: .inet6)

                                guard let socket: Socket = self.listenSocket
                                else
                                {
                                        print("Unable to unwrap socket...")
                                        return
                                }

                                try socket.listen(on: self.port)
                                print("Listening on port: \(socket.listeningPort)")

                                repeat
                                {
                                        let newSocket: Socket = try socket.acceptClientConnection()
                                        print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                                        print("Socket Signature: \(String(describing: newSocket.signature!.description))")
                                        self.connect(socket: newSocket)
                                }
                                while self.isRunning

                        }
                        catch let error
                        {
                                guard let socketError: Socket.Error = error as? Socket.Error
                                else
                                {
                                        print("Unexpected error...")
                                        return
                                }
                                if self.isRunning
                                {
                                        print("Error reported:\n \(socketError.description)")
                                }
                        }
                }
                dispatchMain()
        }

        private func connect(socket: Socket)
        {
                socketLockQueue.sync
                { [unowned self, socket] in
                        self.connectedSockets[socket.socketfd] = socket
                }
                DispatchQueue.global(qos: .default).async { [unowned self, socket] in
                        self.serve(socket: socket)
                }
        }

        private func serve(socket: Socket)
        {
                var isConnected: Bool = true
                var readData: Data = Data(capacity: EchoServer.bufferSize)
                do
                {
                        try socket.write(from: "Hello, type '\(EchoServer.quitCommand)' to end session or '\(EchoServer.shutdownCommand)' to stop server.\n")
                        repeat
                        {
                                try handle(data: &readData, socket: socket, isConnected: &isConnected)
                        }
                        while isConnected

                        print("Socket: \(socket.remoteHostname):\(socket.remotePort) closed...")
                        socket.close()
                        socketLockQueue.sync
                        { [unowned self, socket] in
                                self.connectedSockets[socket.socketfd] = nil
                        }
                }
                catch let error
                {
                        guard let socketError: Socket.Error = error as? Socket.Error
                        else
                        {
                                print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                                return
                        }
                        if self.isRunning
                        {
                                print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                        }
                }
        }

        private func handle(data: inout Data, socket: Socket, isConnected: inout Bool) throws
        {
                let bytesRead: Int = try socket.read(into: &data)
                if bytesRead > 0
                {
                        guard let message: String = String(data: data, encoding: .utf8)
                        else
                        {
                                print("Error decoding response...")
                                data.count = 0
                                return
                        }
                        try response(message: message, socket: socket, isConnected: &isConnected)
                }
                if bytesRead == 0
                {
                        isConnected = false
                        return
                }
                data.count = 0
        }

        private func response(message: String, socket: Socket, isConnected: inout Bool) throws
        {

                // Drop the last: \n
                let text: String = String(message.lowercased().dropLast())

                switch text
                {
                case EchoServer.quitCommand:
                        isConnected = false
                case EchoServer.shutdownCommand:
                        print("Shutdown requested by connection at \(socket.remoteHostname):\(socket.remotePort)")
                        shutdownServer()
                default:
                        print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(message) ")
                        let echo: String = "Server response: \n\(message)\n"
                        try socket.write(from: echo)
                }
        }

        private func shutdownServer()
        {
                print("\nShutdown in progress...")
                isRunning = false
                connectedSockets.values.forEach
                {
                        $0.close()
                }
                listenSocket?.close()
                DispatchQueue.main.sync
                {
                        exit(0)
                }
        }
}
