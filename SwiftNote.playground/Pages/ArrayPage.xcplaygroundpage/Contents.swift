//: [Previous](@previous)

import Foundation

//: # Swift Array

//: ## 创建数组

//: - 创建空数组

var emptyArray0 = [Int]()
emptyArray0.append(0)
emptyArray0.append(1)
print(emptyArray0)

//var emptyArray1 = [String]()
//var fruits: [String] = []
//print(fruits)

//: - 创建具有初始值的数组

var countries = ["USA", "India", "Russia", "China", "Japan"]
print(countries)

//: - 指定大小创建数组

// Array(repeating: defaultValue, count: specificSize)
var arr0 = Array(repeating: "", count: 8)
print(arr0)

var arr1 = [Int](repeating: 0, count: 4)
print(arr1)


//: - 创建具有不同数据类型的数组

var arr2 = ["a", 1, "b", 2, "c"] as [Any]
print(type(of: arr2), arr2)

var arr3: [Any] = ["a", 1, "b", 2]
print(arr3)

//: ## 遍历数组

var primes: [Int] = [2, 3, 5, 7, 11]

//: - for in
for prime in primes {
    print(prime, separator: "", terminator: " ")
}
print("")

//: - range

print("iterating over array elements using range:", terminator: " ")
for idx in 0..<primes.count {
    print(primes[idx], separator: "", terminator: " ")
}
print("")

print("iterating over array elements using indices:", terminator: " ")
for idx in primes.indices {
    print(primes[idx], separator: "", terminator: " ")
}
print("")

//: - while
var idx = 0
print("iterating over array elements using while:", terminator: " ")
while idx < primes.count {
    print(primes[idx], separator: "", terminator: " ")
    idx += 1
}
print("")

//: - forEach block

print("iterating over array elements using forEach block:", terminator: " ")
primes.forEach { prime in
    print("\(prime)", separator: "", terminator: " ")
}
print("")

primes.forEach {
    print($0, separator: "", terminator: " ")
}
print("")

//: enumerated

print("iterating over array elements using enumerated method:", terminator: " ")
//use the enumerated method to convert our array into a sequence containing tuples that pair each index with its associated element
for (idx, prime) in primes.enumerated() {
    print("(\(idx), \(prime))", separator: "", terminator: " ")
}
print("")

//: ## 访问数组元素


//: - 通过索引访问数组元素

var fruits: [String] = ["apple", "banana", "cherry", "mango", "guava"]

let element_1 = fruits[0]
print(element_1)

//Fatal error: Index out of range
//let element_2 = fruits[-1]
//print(element_2)

//: - 获取数组首个元素

if let element = fruits.first {
    print("First Element: \(element)")
} else {
    print("Array is empty.")
}

//: - 获取数组最后一个元素

if let element = fruits.last {
    print("Last Element: \(element)")
} else {
    print("Array is empty.")
}

//: - 随机获取数组元素

if let element = fruits.randomElement() {
    print("Random Element: \(element)")
} else {
    print("Array is empty.")
}

//: - for each 遍历

fruits.forEach { fruit in
    let length = fruit.count
    print("\(fruit) - \(length)")
}

//: ## 数组检测

//: - Check Array is Empty

let myArray0: [Int] = [0, 1, 2, 3]
print(myArray0.isEmpty)

let myArray1: [String] = []
print(myArray1.isEmpty)

//: - Check if specific element is present

let num0: Int = 5
print("Is elelment \(num0) present in array? \(myArray0.contains(num0))")

let num1: Int = 3
print("Is elelment \(num1) present in array? \(myArray0.contains(num1))")

//: - 检测两个数组是否相等

let fruits_0: [String] = ["apple", "mango", "cherry"]
let fruits_1: [String] = ["apple", "avacado", "cherry"]

if fruits_0 == fruits_1 {
    print("Two arrays are equal.")
} else {
    print("Two arrays are not equal.")
}

//: ## 在数组中查找元素索引

//: - 查找元素索引

let names = ["apple", "banana", "cherry", "mango"]
let ele = "pear"

if let idx = names.firstIndex(of: ele) {
    print("Index of \(ele) is \(idx)")
} else {
    print("Element is not present in the array.")
}

//: - 查找元素最小值

let nums = [6, 4 ,2, 8, 10]

if let result = nums.min() {
    print("Minimum num is: \(result)")
} else {
    print("Array is emptry")
}

let arr10 = ["apple", "banana", "cherry", "mango"]
if let result = arr10.min(by: { element0, element1 in element0.count < element1.count }) {
    print("Minimum element: \(result)")
}

//: - 查找最大值

if let num = nums.max() {
    print("Maximum num is: \(num)")
} else {
    print("Array is empty.")
}

if let result = arr10.max(by: { $0.count < $1.count}) {
    print("Maximum element: \(result)")
}

//: ## 数组转换

//: - 数组添加元素

var fruits_01 = ["apple", "banana", "cherry"]
var anotherFruit = "mango"
fruits_01.append(anotherFruit)
print(fruits_01)

//: - 数组添加数组

var fruits_02 = ["apple", "banana", "cherry"]
var moreFruits = ["mango", "guava"]
fruits_02.append(contentsOf: moreFruits)
print(fruits_02)

//: - 连接两个数组

var arr01: [Int] = [22, 54]
var arr02: [Int] = [35, 68]

var new_array = arr01 + arr02
print(new_array)

//: - 删除数组中前 N 个元素

print("Original Array: \(fruits_02)")
var result = fruits_02.dropFirst(2)
print("Drop first N result Array: \(result)")

//: - 删除数组中第一个元素

print("Original Array: \(fruits_02)")
result = fruits_02.dropFirst()
print("Drop first result Array: \(result)")

//: - 删除数组中最后 N 个元素

print("Original Array: \(fruits_02)")
result = fruits_02.dropLast(2)
print("Drop last N result Array: \(result)")

result = fruits_02.dropLast(10)
print("Another drop last N result Array: \(result)")


result = fruits_02.dropLast()
print("Drop last result Array: \(result)")

//: - 在数组指定位置插入元素

var fruits_03 = ["apple", "banana", "cherry", "mango"]
var fruitGuava = "guava"
fruits_03.insert(fruitGuava, at: 0)
print(fruits_03)

//Swift/Array.swift:405: Fatal error: Array index is out of range
//fruits_03.insert(fruitGuava, at: 10)

//: - 在数组指定公位置插入另外一个数组

var fruits_04 = ["apple", "banana", "cherry"]
var moreFruits_04 = ["guava", "mango"]
fruits_04.insert(contentsOf: moreFruits_04, at: 0)
print(fruits_04)

//: - 删除数组中指定位置元素

var numbers = [2, 3, 5, 7, 11]
numbers.remove(at: 1)
numbers.forEach { print($0) }

//: - 指定条件删除数组中元素

numbers.removeAll(where: { $0 > 5})
print(numbers)

//: - 删除数组中所有元素

numbers.removeAll()
print(numbers)

//: - 反转数组

var anotherNumbers = [2, 3, 5, 7, 11]
print("Original array: \(anotherNumbers)")

let reverseResult: [Int] = anotherNumbers.reversed()
print("Reversed Array: \(reverseResult)")

anotherNumbers.reverse()
print("Reverse Array: \(anotherNumbers)")

//: [Next](@next)
