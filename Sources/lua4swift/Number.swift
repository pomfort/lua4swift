import CLua

extension Lua {
    public final class Number: Lua.StoredValue, LuaValueRepresentable, CustomDebugStringConvertible {
        public var kind: Lua.Kind { return .number }

        public func toDouble() -> Double {
            push(vm)
            let v = lua_tonumberx(vm.state, -1, nil)
            vm.pop()
            return v
        }

        public func toInteger() -> Int64 {
            push(vm)
            let v = lua_tointegerx(vm.state, -1, nil)
            vm.pop()
            return v
        }

        public var debugDescription: String {
            push(vm)
            let isInteger = lua_isinteger(vm.state, -1) != 0
            vm.pop()

            if isInteger { return toInteger().description }
            else { return toDouble().description }
        }

        public var isInteger: Bool {
            push(vm)
            let isInteger = lua_isinteger(vm.state, -1) != 0
            vm.pop()
            return isInteger
        }

        public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Number {
            guard value.kind == .number else { throw Lua.TypeGuardError(kind: .number) }
            return value as! Number
        }
    }
}

extension Double: LuaValueRepresentable {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushnumber(vm.state, self)
    }

    public var kind: Lua.Kind { return .number }

    public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
        value.push(vm)
        let isDouble = lua_isinteger(vm.state, -1) != 0
        vm.pop()
        guard isDouble else { throw Lua.TypeGuardError(type: "Double") }
        return value as! Double
    }
}

extension Int64: LuaValueRepresentable {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushinteger(vm.state, self)
    }

    public var kind: Lua.Kind { return .number }

    public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
        value.push(vm)
        let isDouble = lua_isinteger(vm.state, -1) != 0
        vm.pop()
        guard isDouble else { throw Lua.TypeGuardError(type: "Int64") }
        return value as! Int64
    }
}

extension Int: LuaValueRepresentable {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushinteger(vm.state, Int64(self))
    }

    public var kind: Lua.Kind { return .number }

    public static func unwrap(_ vm: Lua.VirtualMachine, _ value: LuaValueRepresentable) throws -> Self {
        try Int(Int64.unwrap(vm, value))
    }
}
