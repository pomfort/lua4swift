import Foundation
import CLua

extension Lua {
    public struct Error: CustomNSError {
        public static let errorDomain: String = "lua4swift.Lua.Error"
        public static let AuxDataKey = "lua4swift.Lua.Error.aux"
        private static let ErrorCodeKey = "lua4swift.Lua.Error.code"

        public let errorUserInfo: [String: Any]

        public var errorCode: Int {
            self.errorUserInfo[Self.ErrorCodeKey] as? Int ?? 0
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

        private static func make(_ code: Code, aux: String? = nil) -> Self {
            var userInfo: [String: Any] = [
                Self.ErrorCodeKey: code.rawValue,
            ]
            if let aux {
                userInfo[Self.AuxDataKey] = aux
            }
            return .init(errorUserInfo: userInfo)
        }

        static func `internal`(_ s: String) -> Self {
            .make(.internal, aux: s)
        }

        static func internalTyped(_ s: String, _ t: LuaValueRepresentable.Type) -> Self {
            .make(.internalTyped, aux: "(\(t.typeName)): \(s)")
        }

        static var notALuaFunction: Self {
            .make(.notALuaFunction)
        }

        static var methodCall: Self {
            .make(.methodCall)
        }

        static var `nil`: Self {
            .make(.nil)
        }

        static func customTypeGuard(_ t: LuaCustomTypeInstance.Type) -> Self {
            .make(.customTypeGuard, aux: t.luaTypeName())
        }

        static func representableTypeGuard(_ t: LuaValueRepresentable.Type) -> Self {
            .make(.representableTypeGuard, aux: t.typeName)
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
