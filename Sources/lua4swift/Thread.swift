import CLua

extension Lua {
    final public class Thread: Lua.StoredValue, LuaValueRepresentable {
        public var kind: Lua.Kind { return .thread }

        public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Thread {
            guard value.kind == .thread else { throw Lua.TypeGuardError(kind: .thread) }
            return value as! Thread
        }
    }
}
