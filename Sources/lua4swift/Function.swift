import CLua

extension Lua {
    public struct Error: Swift.Error {
        public let literal: String

        internal init(_ e: String) {
            self.literal = e
        }
    }

    open class Function: Lua.StoredValue, LuaValueRepresentable, CustomStringConvertible {
        open func call(_ args: [LuaValueRepresentable]) throws -> [LuaValueRepresentable] {
            let debugTable = vm.globals["debug"] as! Table
            let messageHandler = debugTable["traceback"]

            let originalStackTop = vm.stackSize()

            messageHandler.push(vm)
            push(vm)
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
                let err = vm.popError()
                throw Lua.Error(err)
            }
        }

        public var kind: Lua.Kind { return .function }

        public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
            guard value.kind == .function else { throw Lua.TypeGuardError(kind: .function) }
            return value as! Self
        }

        public var description: String { "Function" }
    }
}
