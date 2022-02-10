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
