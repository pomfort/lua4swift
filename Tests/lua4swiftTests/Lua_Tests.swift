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

        stringxLib["split"] = vm.createFunction { (subject: String, separator: String) in
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
            let array: [String] = (values[0] as! Lua.Table).asSequence()
            XCTAssertEqual(array, ["hello", "world"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCustomType() {
        class Note: LuaCustomTypeInstance {
            var name = ""
            static func luaTypeName() -> String {
                return "note"
            }
        }

        let vm = Lua.VirtualMachine()

        let noteLib: Lua.CustomType<Note> = vm.createCustomType { type in
            type["setName"] = type.createMethod { (self: Note, name: String) in
                self.name = name
            }
            type["getName"] = type.createMethod { (self: Note) in
                self.name
            }
        }

        noteLib["new"] = vm.createFunction { (name: String) in
            let note = Note()
            note.name = name
            let data = vm.createUserdata(note)
            return data
        }

        // setup the note class
        vm.globals["note"] = noteLib

        _ = try! vm.eval("myNote = note.new('a custom note')")
        XCTAssert(vm.globals["myNote"] is Lua.Userdata)

        // extract the note
        // and see if the name is the same

        let myNote: Note = (vm.globals["myNote"] as! Lua.Userdata).toCustomType()
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
}
