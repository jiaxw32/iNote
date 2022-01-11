//: [Previous](@previous)

import Foundation

var greeting = "Hello, playground"

//: [Next](@next)

//: 创建一个字符串变量

var str0: String

var str1 = ""

var str2 = String()

print("\(type(of: str0)), \(type(of: str1)), \(type(of: str2))")

//: 字符串长度

let strLen = "Hello World!"
print("the length of str is: \(strLen.count)")

//: 字符串连接

var str3 = "Hello"
var str4 = "World"
let str5 = str3 + " " + str4
print(str5)

//: 字符串比较

let cmp_str1 = "mango"
let cmp_str2 = "apple"
let cmp_str3 = "mango"

// 判断一个字符串是否大于另一个字符串
if cmp_str1 > cmp_str2 {
    print("\(cmp_str1) is greater than \(cmp_str2)")
} else {
    print("\(cmp_str1) is not greater than \(cmp_str2)")
}

// 判断两个字符串是否相等
if cmp_str1 == cmp_str3 {
    print("\(cmp_str1) is equal to \(cmp_str3)")
} else {
    print("\(cmp_str1) is not equal to \(cmp_str3)")
}

//: 遍历字符串中的字符

for ch in greeting {
    print(ch)
}

//: 字符串截取

let strMain = "TutorialKart"
let start = strMain.index(strMain.startIndex, offsetBy: 2)
let end = strMain.index(strMain.endIndex, offsetBy: -4)
let range = start..<end
let subStr = strMain[range]
print(subStr)

//: 检查字符串是否为空

let aEmptyStr = ""
print("Is the string empty? \(aEmptyStr.isEmpty)")

//: 检查一个字符串是否包含另外一个字符串

var strOne = "Hello World"
var strTwo = "Wor"
var result = strOne.contains(strTwo)
print("Does strOne contains strTwo: \(result)")

//: 检查字符串以特定前缀开关或结尾

strTwo = "Hello"
result = strOne.starts(with: strTwo)
print("Does strOne start with strTwo? \(result)")

result = strOne.hasPrefix(strTwo)
print("Does strOne start with strTwo? \(result)")

result = strOne.hasSuffix(strTwo)
print("Does strOne end with strTwo? \(result)")

//: 检查变量类型是否为字符串

let dict: [String:Any] = ["key1": "value1", "key2": 30]

let x = dict["key1"]
var ans = x is String
print("Is the variable a String? \(ans)")

let y = dict["key2"]
ans = y is String
print("Is the variable a String? \(ans)")

//: 字符串大小写转换

print("Original String: \(greeting)")
print("Lowercase String: \(greeting.lowercased())")
print("Uppercase String: \(greeting.uppercased())")

//: 字符串中插入字符

let ch: Character = "X"
let idx0 = greeting.index(greeting.endIndex, offsetBy: 0)
greeting.insert(ch, at: idx0)
print(greeting)

// 超出字符串索引会触发异常
//let idx1 = greeting.index(greeting.startIndex, offsetBy: 100)
//greeting.insert(ch, at: idx1)
//print(greeting)

//: 字符串中移除字符

print("The string before remove: \(greeting)")
let idx = greeting.index(greeting.endIndex, offsetBy: -1)
let removedChar = greeting.remove(at: idx)
print("The string after remove: \(greeting)")


//: 移除字符串中最后一个字符

print("The string before remove: \(greeting)")
let _ = greeting.removeLast()
print("The string before remove: \(greeting)")

//: 移除字符串中特定字符

var str01 = "An apple a day, keeps doctor away."
let chars: Set<Character> = ["p", "y"]
//str01.removeAll {
//    chars.contains($0)
//}
str01.removeAll { ch in
    chars.contains(ch)
}
print(str01)

//: 反转字符串

let words = "Backwards"

for ch in words.reversed() {
    print(ch, terminator: "-")
}
print("")

let reversedWords = String(words.reversed())
print(reversedWords)

//: 字符串分隔

let line = "BLANCHE:   I don't want realism. I want magic!"
let separator = Character(" ")
let splitResult1 = line.split(separator: separator)
print(type(of: splitResult1), splitResult1)

let splitResult2 = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: false)
print(splitResult2)

//: 字符串类型转换

let strNumber = "256"
let num = Int(strNumber)
print("type of number: \(type(of: num))")

if num != nil {
    print(num!)
}

let strMix = "256abc"
if let retConvert = Int(strMix) {
    print(retConvert)
} else {
    print("The convert result is nil")
}

