import CLua

public protocol LuaValue {
    func push(_ vm: Lua.VirtualMachine)
    func kind() -> Lua.Kind
    static func arg(_ vm: Lua.VirtualMachine, value: LuaValue) -> String?
}

extension Lua {
    open class StoredValue: LuaValue, Equatable {

        fileprivate let registryLocation: Int
        internal unowned var vm: VirtualMachine

        internal init(_ vm: VirtualMachine) {
            self.vm = vm
            vm.pushFromStack(-1)
            registryLocation = vm.ref(RegistryIndex)
        }

        deinit {
            vm.unref(RegistryIndex, registryLocation)
        }

        open func push(_ vm: VirtualMachine) {
            vm.rawGet(tablePosition: RegistryIndex, index: registryLocation)
        }

        open func kind() -> Kind {
            fatalError("Override kind()")
        }

        open class func arg(_ vm: VirtualMachine, value: LuaValue) -> String? {
            fatalError("Override arg()")
        }

        public static func ==(lhs: StoredValue, rhs: StoredValue) -> Bool {
            if lhs.vm.state != rhs.vm.state { return false }

            lhs.push(lhs.vm)
            lhs.push(rhs.vm)
            let result = lua_compare(lhs.vm.state, -2, -1, LUA_OPEQ) == 1
            lhs.vm.pop(2)

            return result
        }
    }
}