import Foundation
import CLua

extension Lua {
    public class Error: NSError, @unchecked Sendable {
        public static let errorDomain: String = "lua4swift.Lua.Error"
        public static let AuxDataKey = "lua4swift.Lua.Error.aux"
        public static let LineKey = "lua4swift.Lua.Error.line"

        public var errorCode: Code {
            .init(rawValue: self.code) ?? .nil
        }

        override public static var supportsSecureCoding: Bool {
            true
        }

        public enum Code: Int {
            case `nil` = 0
            case `internal` = 1
            case notALuaFunction = 2
            case customTypeGuard = 3
            case representableTypeGuard = 4
            case methodCall = 5
            case internalTyped = 6
        }

        private static func make(_ code: Code, line: Int?, aux: String? = nil) -> Error {
            var userInfo: [String: Any] = [:]
            if let aux {
                userInfo[Self.AuxDataKey] = aux
            }
            if let line {
                userInfo[Self.LineKey] = line
            }
            return Error(domain: Self.errorDomain, code: code.rawValue, userInfo: userInfo)
        }

        static func `internal`(_ s: String) -> Error {
            .make(.internal, line: nil, aux: s)
        }

        static func internalTyped(_ s: String, _ t: LuaValueRepresentable.Type) -> Error {
            .make(.internalTyped, line: nil, aux: "(\(t.typeName)): \(s)")
        }

        static var notALuaFunction: Error {
            .make(.notALuaFunction, line: nil)
        }

        static func methodCall(_ line: Int) -> Error {
            .make(.methodCall, line: line)
        }

        static var `nil`: Error {
            .make(.nil, line: nil)
        }

        static func customTypeGuard(_ line: Int, _ t: LuaCustomTypeInstance.Type) -> Error {
            .make(.customTypeGuard, line: line, aux: t.luaTypeName())
        }

        static func representableTypeGuard(_ line: Int, _ t: LuaValueRepresentable.Type) -> Error {
            .make(.representableTypeGuard, line: line, aux: t.typeName)
        }
    }

    open class Function: Lua.StoredValue, LuaValueRepresentable, SimpleUnwrapping {
        private var capturesEnv: Bool {
            guard let _envname = lua_getupvalue(vm.state, -1, 1) else { return false }
            vm.pop()
            let envname = String(cString: _envname)
            return envname == "_ENV"
        }

        private func set(env: Table?) {
            guard let env else {
                assert(false, "no environment")
                return
            }
            guard self.capturesEnv else { return }
            env.push(vm)
            lua_setupvalue(vm.state, -2, 1)
        }

        public func dump(strip: Bool = false) throws -> Data {
            self.push(self.vm)
            defer { self.vm.pop() }

            var data = Data()
            let r = withUnsafeMutablePointer(to: &data) {
                lua_dump(self.vm.state, { _, p, sz, d in
                    guard let d, let p else { fatalError("invalid dump data") }
                    d.bindMemory(to: Data.self, capacity: 1).pointee
                        .append(p.assumingMemoryBound(to: UInt8.self), count: sz)
                    return 0
                }, $0, strip ? 1 : 0)
            }
            guard r == 0 else {
                assert(r == 1)
                throw Error.notALuaFunction
            }
            return data
        }

        internal func call(_ args: [LuaValueRepresentable]) throws -> [LuaValueRepresentable] {
            let debugTable = vm.globals["debug"] as! Lua.Table
            let messageHandler = debugTable["traceback"]

            let originalStackTop = vm.stackSize()

            messageHandler.push(vm)
            self.push(vm)
            self.set(env: vm.env)

            for arg in args {
                arg.push(vm)
            }

            let result = lua_pcallk(vm.state, Int32(args.count), LUA_MULTRET, Int32(originalStackTop + 1), 0, nil)
            vm.remove(originalStackTop + 1)

            if result == LUA_OK {
                var values = [LuaValueRepresentable]()
                let numReturnValues = vm.stackSize() - originalStackTop

                for _ in 0..<numReturnValues {
                    let v = vm.popValue(originalStackTop+1)!
                    values.append(v)
                }

                return values
            } else {
                throw vm.popError()
            }
        }
    }
}
