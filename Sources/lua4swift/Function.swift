import CLua

extension Lua {
    public struct Error: Swift.Error {
        public let literal: String

        internal init(_ e: String) {
            self.literal = e
        }
    }

    open class Function: Lua.StoredValue, LuaValueRepresentable {
        open func call(_ args: [LuaValueRepresentable]) throws -> [LuaValueRepresentable] {
            let debugTable = vm.globals["debug"] as! Table
            let messageHandler = debugTable["traceback"]

            let originalStackTop = vm.stackSize()

            messageHandler.push(vm)
            push(vm)
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
                let err = vm.popError()
                throw Lua.Error(err)
            }
        }

        public var kind: Lua.Kind { return .function }

        open class func arg(_ vm: Lua.VirtualMachine, value: LuaValueRepresentable) -> String? {
            if value.kind != .function { return "function" }
            return nil
        }
    }

    public typealias TypeChecker = (Lua.VirtualMachine, LuaValueRepresentable) -> String?

    public typealias SwiftFunction = (Arguments) throws -> [LuaValueRepresentable]

    open class Arguments {
        internal var values = [LuaValueRepresentable]()

        open var string: String { return values.remove(at: 0) as! String }
        open var number: Number { return values.remove(at: 0) as! Number }
        open var boolean: Bool { return values.remove(at: 0) as! Bool }
        open var function: Function { return values.remove(at: 0) as! Function }
        open var table: Table { return values.remove(at: 0) as! Table }
        open var userdata: Userdata { return values.remove(at: 0) as! Userdata }
        open var lightUserdata: LightUserdata { return values.remove(at: 0) as! LightUserdata }
        open var thread: Thread { return values.remove(at: 0) as! Thread }

        open var integer: Int64 { return (values.remove(at: 0) as! Number).toInteger() }
        open var double: Double { return (values.remove(at: 0) as! Number).toDouble() }

        open func removeValue(at index: Int) -> LuaValueRepresentable { return values.remove(at: index) }

        open func customType<T: LuaCustomTypeInstance>() -> T { return (values.remove(at: 0) as! Userdata).toCustomType() }
    }
}
