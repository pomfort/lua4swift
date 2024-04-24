import CLua

extension Lua {
    public enum Error: Swift.Error {
        case `internal`(String)
        case methodCall
        case representableTypeGuard(LuaValueRepresentable.Type)
        case customTypeGuard(LuaCustomTypeInstance.Type)
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
                throw Lua.Error.internal(vm.popError())
            }
        }
    }
}
