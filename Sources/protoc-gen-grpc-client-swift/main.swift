import Foundation
import SwiftProtobufPluginLibrary

struct GeneratorPlugin {
    private enum Mode {
        case showHelp
        case showVersion
        case generateFromStdin
        case generateFromFiles(paths: [String])
    }

    init() {}

    func run(args: [String]) -> Int32 {
        var result: Int32 = 0

        let mode = parseCommandLine(args: args)
        switch mode {
        case .showHelp:
            showHelp()
        case .showVersion:
            showVersion()
        case .generateFromStdin:
            result = generateFromStdin()
        case .generateFromFiles(let paths):
            result = generateFromFiles(paths)
        }

        return result
    }

    private func parseCommandLine(args: [String]) -> Mode {
        var paths: [String] = []
        for arg in args {
            switch arg {
            case "-h", "--help":
                return .showHelp
            case "--version":
                return .showVersion
            default:
                if arg.hasPrefix("-") {
                    Stderr.print("Unknown argument: \"\(arg)\"")
                    return .showHelp
                } else {
                    paths.append(arg)
                }
            }
        }
        return paths.isEmpty ? .generateFromStdin : .generateFromFiles(paths: paths)
    }

    private func showHelp() {
        print("\(CommandLine.programName): Convert parsed proto definitions into Swift")
        print("")
        showVersion()
        print("")

        let help = ("""
                    This is a plugin for protoc and should not normally be run directly.
                    If you invoke a recent version of protoc with the --grpc-client-swift_out=<dir>
                    option, then protoc will search the current PATH for protoc-gen-grpc-client-swift
                    and use it to generate Swift output.

                    -h|--help:  Print this help message
                    --version: Print the program version
                    """)

        print(help)
    }

    private func showVersion() {
        print("\(CommandLine.programName) 1.0.0-alpha.2")
    }

    private func generateFromStdin() -> Int32 {
        let requestData = FileHandle.standardInput.readDataToEndOfFile()

        // Support for loggin the request. Useful when protoc/protoc-gen-swift are
        // being invoked from some build system/script. protoc-gen-swift supports
        // loading a request as a command line argument to simplify debugging/etc.
        if let dumpPath = ProcessInfo.processInfo.environment["PROTOC_GEN_SWIFT_LOG_REQUEST"], !dumpPath.isEmpty {
            let dumpURL = URL(fileURLWithPath: dumpPath)
            do {
                try requestData.write(to: dumpURL)
            } catch let e {
                Stderr.print("Failed to write request to '\(dumpPath)', \(e)")
            }
        }

        let request: Google_Protobuf_Compiler_CodeGeneratorRequest
        do {
            request = try Google_Protobuf_Compiler_CodeGeneratorRequest(serializedData: requestData)
        } catch let e {
            Stderr.print("Request failed to decode: \(e)")
            return 1
        }

        let response = generate(request: request)
        guard sendReply(response: response) else { return 1 }
        return 0
    }

    private func generateFromFiles(_ paths: [String]) -> Int32 {
        var result: Int32 = 0

        for p in paths {
            let requestData: Data
            do {
                requestData = try readFileData(filename: p)
            } catch let e {
                Stderr.print("Error reading from \(p) - \(e)")
                result = 1
                continue
            }
            Stderr.print("Read request: \(requestData.count) bytes from \(p)")

            let request: Google_Protobuf_Compiler_CodeGeneratorRequest
            do {
                request = try Google_Protobuf_Compiler_CodeGeneratorRequest(serializedData: requestData)
            } catch let e {
                Stderr.print("Request failed to decode \(p): \(e)")
                result = 1
                continue
            }

            let response = generate(request: request)
            if response.hasError {
                Stderr.print("Error while generating from \(p) - \(response.error)")
                result = 1
            } else {
                for f in response.file {
                    print("+++ Begin File: \(f.name) +++")
                    print(!f.content.isEmpty ? f.content : "<No content>")
                    print("+++ End File: \(f.name) +++")
                }
            }
        }

        return result
    }

    private func generate(request: Google_Protobuf_Compiler_CodeGeneratorRequest) -> Google_Protobuf_Compiler_CodeGeneratorResponse {
        let options: GeneratorOptions
        do {
            options = try GeneratorOptions(parameter: request.parameter)
        } catch GenerationError.unknownParameter(let name) {
            return Google_Protobuf_Compiler_CodeGeneratorResponse(
                error: "Unknown generation parameter '\(name)'")
        } catch GenerationError.invalidParameterValue(let name, let value) {
            return Google_Protobuf_Compiler_CodeGeneratorResponse(
                error: "Unknown value for generation parameter '\(name)': '\(value)'")
        } catch GenerationError.wrappedError(let message, let e) {
            return Google_Protobuf_Compiler_CodeGeneratorResponse(error: "\(message): \(e)")
        } catch let e {
            return Google_Protobuf_Compiler_CodeGeneratorResponse(
                error: "Internal Error parsing request options: \(e)")
        }

        let descriptorSet = DescriptorSet(protos: request.protoFile)
        var responseFiles: [Google_Protobuf_Compiler_CodeGeneratorResponse.File] = []

        for fileDescriptor in descriptorSet.files where fileDescriptor.services.count > 0 {
            let fileGenerator = FileGenerator(fileDescriptor: fileDescriptor, generatorOptions: options)
            var printer = CodePrinter()
            fileGenerator.generateOutputFile(printer: &printer)
            responseFiles.append(
                Google_Protobuf_Compiler_CodeGeneratorResponse.File(name: fileGenerator.outputFilename,
                                                                    content: printer.content))
        }

        return Google_Protobuf_Compiler_CodeGeneratorResponse(files: responseFiles)
    }

    private func sendReply(response: Google_Protobuf_Compiler_CodeGeneratorResponse) -> Bool {
        let serializedResponse: Data
        do {
            serializedResponse = try response.serializedData()
        } catch let e {
            Stderr.print("Failure while serializing response: \(e)")
            return false
        }
        FileHandle.standardOutput.write(serializedResponse)
        return true
    }

}

// MARK: - Hand off to the GeneratorPlugin

// Drop the program name off to get the arguments only.
let args: [String] = [String](CommandLine.arguments.dropFirst(1))
let plugin = GeneratorPlugin()
let result = plugin.run(args: args)
exit(result)
