import Cocoa
import XCTest

@testable import lua4swift

class Lua_Tests: XCTestCase {
    func testFundamentals() {
        let vm = Lua.VirtualMachine()
        let table = vm.createTable()
        table[3] = "foo"
        XCTAssert(table[3] is String)
        XCTAssertEqual(table[3] as! String, "foo")
    }

    func testStringX() {
        let vm = Lua.VirtualMachine()

        let stringxLib = vm.createTable()

        stringxLib["split"] = vm.createFunction { [unowned vm] args in
            let subject = try String.unwrap(vm.state, args[0])
            let separator = try String.unwrap(vm.state, args[1])
            let fragments = subject.components(separatedBy: separator)

            let results = vm.createTable()
            for (i, fragment) in fragments.enumerated() {
                results[i+1] = fragment
            }
            return results
        }

        vm.globals["stringx"] = stringxLib

        do {
            let values = try vm.eval("return stringx.split('hello world', ' ')")
            XCTAssertEqual(values.count, 1)
            XCTAssert(values[0] is Lua.Table)
            let array: [String] = (values[0] as! Lua.Table).asArray()!
            XCTAssertEqual(array, ["hello", "world"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCustomType() throws {
        class Note: LuaCustomTypeInstance {
            var name = ""
            static func luaTypeName() -> String {
                return "note"
            }
        }

        let vm = Lua.VirtualMachine()

        let noteLib: Lua.CustomType<Note> = vm.createCustomType { type in
            type["setName"] = type.createMethod { [unowned vm] (self, args) -> Void in
                let name = try String.unwrap(vm.state, args[0])
                self.name = name
            }
            type["getName"] = type.createMethod { (self: Note, _) in
                self.name
            }
        }

        noteLib["new"] = vm.createFunction { [unowned vm] args in
            let name = try String.unwrap(vm.state, args[0])
            let note = Note()
            note.name = name
            return vm.createUserdata(note)
        }

        // setup the note class
        vm.globals["note"] = noteLib

        _ = try! vm.eval("myNote = note.new('a custom note')")
        XCTAssert(vm.env?["myNote"] is Lua.Userdata)

        // extract the note
        // and see if the name is the same

        let myNote: Note = try (vm.env?["myNote"] as! Lua.Userdata).toCustomType()
        XCTAssert(myNote.name == "a custom note")

        // This is just to highlight changes in Swift
        // will get reflected in Lua as well
        // TODO: redirect output from Lua to check if both
        // are equal

        myNote.name = "now from XCTest"
        _ = try! vm.eval("print(myNote:getName())")

        // further checks to change name in Lua
        // and see change reflected in the Swift object

        _ = try! vm.eval("myNote:setName('even')")
        XCTAssert(myNote.name == "even")

        _ = try! vm.eval("myNote:setName('odd')")
        XCTAssert(myNote.name == "odd")
    }

    func testLifetime() throws {
        class LT: LuaCustomTypeInstance {
            static var deinitCount = 0

            static func luaTypeName() -> String {
                return "LifeThreateningLifestyles"
            }

            deinit {
                Self.deinitCount += 1
            }
        }

        try {
            let vm = Lua.VirtualMachine()
            let lib: Lua.CustomType<LT> = vm.createCustomType { _ in }

            lib["new"] = vm.createFunction { [unowned vm] _ in
                _ = vm
                let l = LT()
                return vm.createUserdata(l)
            }

            vm.globals["LT"] = lib

            _ = try vm.eval("""
                local l = LT.new()
                global = LT.new()
            """)
        }()

        XCTAssertEqual(LT.deinitCount, 2)
    }

    func testLightLifetime() throws {
        class O: NSObject { }
        weak var weakObj: O? = nil
        try {
            var obj: O? = O()
            weakObj = obj

            let vm = Lua.VirtualMachine()
            let fun = vm.createFunction { _ -> Lua.LightUserdata in
                return Lua.LightUserdata(ptr: obj!)
            }

            vm.globals["fun"] = fun

            let r = try vm.eval("return fun()")
            let lu = try XCTUnwrap(r.first as? Lua.LightUserdata)
            XCTAssertNotNil(lu.ptr as? O)
            obj = nil
        }()
        XCTAssertNil(weakObj)
    }

    func testSetEnv() throws {
        class T: LuaCustomTypeInstance {
            static func luaTypeName() -> String {
                return "T"
            }
        }

        let vm = Lua.VirtualMachine()
        let lib: Lua.CustomType<T> = vm.createCustomType { t in
            t["callback"] = t.createMethod { (self, args) -> Void in
                let fx = try Lua.Function.unwrap(args[0])
                _ = try fx.call([])
            }
        }

        lib["new"] = vm.createFunction { [unowned vm] _ in
            _ = vm
            let l = T()
            return vm.createUserdata(l)
        }

        vm.globals["T"] = lib

        _ = try vm.eval("""
            local l = T.new()
            l:callback(function ()
            end)
        """)
    }

    func testFunctionDump() throws {
        let add = try {
            let vm = Lua.VirtualMachine()

            let sub = vm.createFunction { [unowned vm] (args) -> Int64 in
                _ = vm
                let l = try Int64.unwrap(args[0])
                let r = try Int64.unwrap(args[1])
                return l-r
            }
            XCTAssertThrowsError(try sub.dump())

            _ = try vm.eval("""
                function add(a, b)
                    return a+b
                end
            """)
            let add = try XCTUnwrap(vm.env?["add"] as? Lua.Function)
            return try XCTUnwrap(try? add.dump())
        }()

        let vm = Lua.VirtualMachine()
        let r = try vm.eval(add, args: [5, 7])
        let a = try XCTUnwrap(r[0] as? Int64)
        XCTAssertEqual(a, 12)
    }
}
