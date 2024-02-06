import CLua

extension Lua {
    public struct Error: Swift.Error {
        public let literal: String

        internal init(_ e: String) {
            self.literal = e
        }
    }

    open class Function: Lua.StoredValue, LuaValueRepresentable, SimpleUnwrapping {
        private func set(env: Table?) {
            guard let env else {
                assert(false, "no environment")
                return
            }
            env.push(vm)
            lua_setupvalue(vm.state, -2, 1)
        }

        internal func call(_ args: [LuaValueRepresentable]) throws -> [LuaValueRepresentable] {
            defer {
                luaC_fullgc(vm.state, 0)
            }
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
                let err = vm.popError()
                throw Lua.Error(err)
            }
        }
    }
}
