import CLua

extension Lua {
    open class Number: Lua.StoredValue, CustomDebugStringConvertible {
        override open func kind() -> Lua.Kind { return .number }
        
        open func toDouble() -> Double {
            push(vm)
            let v = lua_tonumberx(vm.state, -1, nil)
            vm.pop()
            return v
        }
        
        open func toInteger() -> Int64 {
            push(vm)
            let v = lua_tointegerx(vm.state, -1, nil)
            vm.pop()
            return v
        }
        
        open var debugDescription: String {
            push(vm)
            let isInteger = lua_isinteger(vm.state, -1) != 0
            vm.pop()
            
            if isInteger { return toInteger().description }
            else { return toDouble().description }
        }
        
        open var isInteger: Bool {
            push(vm)
            let isInteger = lua_isinteger(vm.state, -1) != 0
            vm.pop()
            return isInteger
        }
        
        override open class func arg(_ vm: Lua.VirtualMachine, value: LuaValue) -> String? {
            if value.kind() != .number { return "number" }
            return nil
        }
    }
}

extension Double: LuaValue {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushnumber(vm.state, self)
    }

    public func kind() -> Lua.Kind { return .number }

    public static func arg(_ vm: Lua.VirtualMachine, value: LuaValue) -> String? {
        value.push(vm)
        let isDouble = lua_isinteger(vm.state, -1) != 0
        vm.pop()
        if !isDouble { return "double" }
        return nil
    }
}

extension Int64: LuaValue {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushinteger(vm.state, self)
    }
    
    public func kind() -> Lua.Kind { return .number }

    public static func arg(_ vm: Lua.VirtualMachine, value: LuaValue) -> String? {
        value.push(vm)
        let isDouble = lua_isinteger(vm.state, -1) != 0
        vm.pop()
        if !isDouble { return "integer" }
        return nil
    }
}

extension Int: LuaValue {
    public func push(_ vm: Lua.VirtualMachine) {
        lua_pushinteger(vm.state, Int64(self))
    }

    public func kind() -> Lua.Kind { return .number }

    public static func arg(_ vm: Lua.VirtualMachine, value: LuaValue) -> String? {
        return Int64.arg(vm, value: value)
    }
}
