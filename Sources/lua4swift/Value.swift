import CLua

public protocol LuaValueRepresentable: CustomStringConvertible {
    func push(_ vm: Lua.State)
    var kind: Lua.Kind { get }
    static func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Self
    static var typeName: String { get }
}

extension Lua {
    public struct TypeGuardError: Swift.Error {
        public let type: String

        init(kind: Kind) {
            self.type = kind.description
        }
        public init(type: String) {
            self.type = type
        }
    }

    public struct MethodCallError: Swift.Error { }

    open class StoredValue: Equatable {
        fileprivate let registryLocation: Int
        internal unowned var vm: State

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
