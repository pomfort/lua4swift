import CLua

extension Lua {
    final public class Thread: Lua.StoredValue, LuaValueRepresentable {
        public var kind: Lua.Kind { return .thread }
        public static var typeName: String { Lua.Kind.thread.description }
        public var description: String { Lua.Kind.thread.description }

        public static func unwrap(_ vm: Lua.State, _ value: LuaValueRepresentable) throws -> Thread {
            guard value.kind == .thread else { throw Lua.TypeGuardError(kind: .thread) }
            return value as! Thread
        }
    }
}
