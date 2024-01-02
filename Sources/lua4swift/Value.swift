import CLua

public protocol LuaValueRepresentable: CustomStringConvertible {
    func push(_ vm: Lua.VirtualMachine)
    var kind: Lua.Kind { get }
    static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self
}

extension LuaValueRepresentable {
    public var description: String { self.kind.description }
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
