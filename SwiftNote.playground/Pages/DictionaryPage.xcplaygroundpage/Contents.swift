//: [Previous](@previous)

import Foundation

//: [Next](@next)

//: # 在 Swift 中使用字典

//: ## 初始化字典

//: - 创建一个空字典

let emptyDict1 = [String: String]()
let emptyDict2 = Dictionary<String, Int>()
// [Key: Value] 是 Dictionary<Key, Value> 简写，emptyDict3 等价于 emptyDict2
let emptyDict3: [String: Int] = [:]

//: - 创建一个具有初始值的字典

let myDictionary:[String: Int] = ["Mohan":75, "Raghu":82, "John":79]

//: - 从数组创建字典

let names = ["Mohan", "Raghu", "John"]
let marks = [75, 82, 79]
let dictFromArray = Dictionary(uniqueKeysWithValues: zip(names, marks))

//: - 获取字典大小

let count = myDictionary.count
print("my dictioanry size: \(count)")

//: - 检查字典是否为空

if emptyDict1.isEmpty {
    print("This dictionary is empty.")
} else {
    print("This dictionary is not empty.")
}

if myDictionary.isEmpty {
    print("This dictionary is empty.")
} else {
    print("This dictionary is not empty.")
}

//: ## 迭代字典

//: - 方式一
for (key, value) in myDictionary {
    print("\(key): \(value)")
}

//: - 方式二
for (idx, key_value) in myDictionary.enumerated() {
    print("\(idx) -> \(key_value)")
}

//: - 方式三
for (_, key_value) in myDictionary.enumerated() {
    print("\(key_value)")
}

//: - 方式四
for (item) in myDictionary.enumerated() {
    print("\(item)")
}

//: ## 检查字典中是否存在指定 Key

let keyExists = myDictionary["Sam"] != nil

if keyExists {
    print("The key is present in the dictionary.")
} else {
    print("The key is not present in the dictionary.")
}

//: ## 打印字典中所有的 Key

//: - 方法一
for key in myDictionary.keys {
    print("\(key)")
}

//: - 方法二
for (key, _) in myDictionary {
    print("\(key)")
}
//: - 方法三
for item in myDictionary.enumerated() {
    print("\(item.offset): \(item.element.key)")
}

//: - 获取字典中的键值数组

let keys = myDictionary.keys
let values = myDictionary.values

print("my dictionary keys\n---------")
for key in myDictionary.keys {
    print("\(key)")
}

print("my dictionary values\n---------")
for value in myDictionary.values {
    print("\(value)")
}

//: ## 字典的合并

var dict1: [String: Int] = ["Mohan":75, "Raghu":82, "John":79]
let dict2: [String: Int] = ["Surya":91, "John":80, "Saranya":92]

//: - 如果字典中存在重复的键，保留旧值，忽略新值
dict1.merge(dict2) { (current, _) in
    current
}

print("dictionary1\n------------")
for (key, value) in dict1 {
    print("\(key): \(value)")
}

print("dictionary2\n------------")
for (key, value) in dict2 {
    print("\(key): \(value)")
}

//: - 如果字典中存在重复的键，保留新值，忽略旧值
dict1.merge(dict2) { (_, new) in
    new
}

print("dictionary1\n------------")
for (key, value) in dict1 {
    print("\(key): \(value)")
}

print("dictionary2\n------------")
for (key, value) in dict2 {
    print("\(key): \(value)")
}
