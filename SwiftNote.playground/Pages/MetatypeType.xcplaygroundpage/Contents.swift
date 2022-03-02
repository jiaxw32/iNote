//: [Previous](@previous)

import Foundation

/*
 func type<T, Metatype>(of value: T) -> Metatype
 
 references:
 1. https://developer.apple.com/documentation/swift/2885064-type
 2. https://swiftgg.gitbook.io/swift/yu-yan-can-kao/03_types#self-type
 */

//: ## Example1

protocol MyProtocol {}

do {
    print("Example1:")
    let i: Any = 3
    let type = type(of: i)
    print("'\(i)' of type \(type)")
    
    if type == Int.self {
        print("'type(of: aIntVar)' is equal to Int.self")
    }
    
    if type is Int.Type {
        print("the type 'type(of: aIntVar)' is 'Int.Type'")
    }
    
    _ = Int.self is Int.Type // true
    
    _ = MyProtocol.self is MyProtocol.Type // false
    _ = MyProtocol.self is MyProtocol.Protocol // true
}

//: ## Example2

do {
    print("\nExample2:")
    class Smiley {
        class var text: String {
            return ":)"
        }
    }
    
    class EmojiSmiley: Smiley {
        override class var text: String {
            return "😀"
        }
    }
    
    func printSmileyInfo(_ value: Smiley) -> Void {
        let t = type(of: value)
        print("Smile", t.text)
    }
    
    let smiley = Smiley()
    printSmileyInfo(smiley)
    
    let emojiSmiley = EmojiSmiley()
    printSmileyInfo(emojiSmiley)
}

//: ## Example3

print("\nExample3:")
protocol P {}
extension String: P {}

func printGenericInfo<T>(_ value: T) {
    let t = type(of: value)
    print("'\(value)' of type '\(t)'")
}

let s1: P = "Hello"
printGenericInfo(s1) // 'Hello' of type 'P'

let s2: String = "World"
printGenericInfo(s2) // 'World' of type 'String'

let s3: Any = "Swift"
printGenericInfo(s3) // 'World' of type 'Any'


//: ## Example4

do {
    print("\nExample4:")
    class SomeBaseClass {
        class func printClassName() {
            print("SomeBaseClass")
        }
    }
    
    class SomeSubClass: SomeBaseClass{
        override class func printClassName() {
            print("SomeSubClass")
        }
    }
    
    let obj: SomeBaseClass = SomeSubClass()
    type(of: obj).printClassName(); // SomeSubClass
    
    class AnotherSubClass: SomeBaseClass {
        let str: String
        required init(astr: String) {
            self.str = astr
        }
        
        override class func printClassName() {
            print("AnotherSubClass")
        }
    }
    
    let metatype: AnotherSubClass.Type = AnotherSubClass.self
    let instance = metatype.init(astr: "Hello")
    print(instance.str)
}


//: [Next](@next)
