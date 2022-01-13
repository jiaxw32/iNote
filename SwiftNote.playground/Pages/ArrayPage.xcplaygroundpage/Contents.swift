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

//: - while
var idx = 0
while idx < primes.count {
    print(primes[idx], separator: "", terminator: " ")
    idx += 1
}
print("")

//: - forEach block
primes.forEach { prime in
    print("\(prime)", separator: "", terminator: " ")
}
print("")

primes.forEach {
    print($0, separator: "", terminator: " ")
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

//: [Next](@next)
