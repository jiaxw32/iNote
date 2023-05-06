import UIKit
import Foundation

var greeting = "Hello, playground"


let stringNumbers = ["1", "2", "three"]
let maybeInts = stringNumbers.map { Int($0) }
print(type(of: maybeInts))

for item in maybeInts {
    print(item as Any, terminator: " ")
}
print("")

var iter = maybeInts.makeIterator()
while let num = iter.next() {
    print(num as Any)
}


func printInt(i: Int) {
    print("You passed \(i)")
}

let funcVar = printInt

//type(of: funcVar)

printInt(i: 0)
funcVar(0) // 调用函数变量，不需要传递参数标签

let isEven = { $0 % 2 == 0}
print(type(of: isEven))

let isEvenAlt = { (i: Int8) -> Bool in i % 2 == 0 }
print(type(of: isEvenAlt))

let isEvenAlt2: (Int8) -> Bool = { $0 % 2 == 0 }
print(type(of: isEvenAlt2))


let seq1 = [1, 2, 3].lazy.filter { $0 > 1 }.map { $0 * 2 } // LazyMapSequence<LazyFilterSequence<Array<Int>>, Int>
let seq2 = [1, 2, 3].filter { $0 > 1 }.map { $0 * 2 } // LazyMapSequence<LazyFilterSequence<Array<Int>>, Int>
print(type(of: seq1), type(of: seq2))


import Foundation

var _defaultModel: String?

class Car: NSObject {
    var model: String?

    init(model aModel: String?) {
        super.init()
        model = aModel
    }

    convenience override init() {
        self.init(model: _defaultModel)
    }
    
    @objc func startEngine() ->Void {
        print("Starting the \(model ?? "")'s engine.")
    }
    
    @objc func driveForDistance(_ distance: Double) -> Void {
        print("The \(model ?? "") just drove \(distance) miles.")
    }
    
    @objc func turnByAngle(_ angel: Double, quickly: Bool) -> Void {
        print("Angel: \(angel), quickly: \(quickly)")
    }
    
    func testPerformSel(){
        let stepTwo = #selector(driveForDistance(_:))
        porsche.perform(
            stepTwo,
            with: NSNumber(value: 5.0))
        
        let stepThree = #selector(turnByAngle(_:quickly:))

        if porsche.responds(to: stepThree) {
            porsche.perform(
                stepThree,
                with: NSNumber(value: 9.0),
                with: NSNumber(value: true))
        }
    }
}

let porsche = Car()
porsche.model = "Tesla"

porsche.perform(#selector(Car.startEngine))
let stepOne = NSSelectorFromString("startEngine")
porsche.perform(stepOne)

let stepTwo = #selector(Car.driveForDistance(_:))
porsche.perform(
    stepTwo,
    with: NSNumber(value: 5.0))

let stepThree = #selector(Car.turnByAngle(_:quickly:))
if porsche.responds(to: stepThree) {
    porsche.perform(
        stepThree,
        with: NSNumber(value: 9.0),
        with: NSNumber(value: true))
}
print("\(NSStringFromSelector(stepOne))")





protocol MyProtocol {
//    func extensionMethod()
}

struct MyStruct: MyProtocol {}

extension MyStruct {
    func extensionMethod() {
        print("In Struct")
    }
}

extension MyProtocol {
    func extensionMethod() {
        print("In Protocol")
    }
}

let myStruct = MyStruct()
let proto: MyProtocol = myStruct

myStruct.extensionMethod() // -> “In Struct”
proto.extensionMethod() // -> “In Protocol”



/*
class Person: NSObject {
    func sayHi() {
        print("Hello")
    }
}
func greetings(person: Person) {
    person.sayHi()
}
greetings(person: Person()) // prints 'Hello'



class MisunderstoodPerson: Person {}

extension MisunderstoodPerson {
    override func sayHi() {
        print("No one gets me.")
    }
}
greetings(person: MisunderstoodPerson()) // prints 'Hello'

 */



protocol Greetable {
    func sayHi()
}
extension Greetable {
    func sayHi() {
        print("Hello")
    }
}
func greetings(greeter: Greetable) {
    greeter.sayHi()
}

class Person: Greetable {
}
class LoudPerson: Person {
    func sayHi() {
        print("HELLO")
    }
}

let p = LoudPerson()
p .sayHi()

greetings(greeter: p)

/*
class MyClass {
}
extension MyClass {
    func extensionMethod() {}
}

class SubClass: MyClass {
    override func extensionMethod() {}
}
*/


struct Password {
    var text: String
    init?(input: String) {
        if input.count < 6 {
            print("Password too short.")
            return nil
        }
        text = input
    }
}
let password = Password(input: "hell0")

type(of: password)
