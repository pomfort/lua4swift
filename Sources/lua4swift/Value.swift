import CLua

public protocol LuaValueRepresentable {
    func push(_ vm: Lua.State)
    static func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Self
    static var typeName: String { get }
}

extension LuaValueRepresentable {
    public static var typeName: String { String(describing: Self.self) }
}

public protocol SimpleUnwrapping: LuaValueRepresentable { }

public extension SimpleUnwrapping {
    internal static func unwrap(_ value: LuaValueRepresentable) throws -> Self {
        guard let v = value as? Self else { throw Lua.Error.representableTypeGuard(Self.self) }
        return v
    }

    static func unwrap(_: Lua.State, _ value: LuaValueRepresentable) throws -> Self {
        try self.unwrap(value)
    }
}

extension Lua {
    open class StoredValue: Equatable {
        fileprivate let registryLocation: Int
        internal var vm: State

        internal init(_ vm: State) {
            self.vm = vm
            vm.pushFromStack(-1)
            registryLocation = vm.ref(RegistryIndex)
        }

        deinit {
            vm.unref(RegistryIndex, registryLocation)
        }

        open func push(_ vm: State) {
            vm.rawGet(tablePosition: RegistryIndex, index: registryLocation)
        }

        public static func ==(lhs: StoredValue, rhs: StoredValue) -> Bool {
            if lhs.vm.state != rhs.vm.state { return false }

            lhs.push(lhs.vm)
            lhs.push(rhs.vm)
            let result = lua_compare(lhs.vm.state, -2, -1, LUA_OPEQ) == 1
            lhs.vm.pop(2)

            return result
        }

        public var metatable: Table? {
            self.push(vm)
            defer { vm.pop() }
            guard lua_getmetatable(self.vm.state, -1) == 1 else { return nil }
            return self.vm.popValue(-1) as? Table
        }
    }
}
