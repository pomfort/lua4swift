import Foundation
import CLua

extension Lua {
    public enum Error: Swift.Error {
        case `internal`(String)
        case methodCall
        case representableTypeGuard(LuaValueRepresentable.Type)
        case customTypeGuard(LuaCustomTypeInstance.Type)
        case notALuaFunction
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
