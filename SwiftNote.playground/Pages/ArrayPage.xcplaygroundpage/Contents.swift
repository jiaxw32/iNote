//: [Previous](@previous)

import Foundation

//: # Swift Array

//: ## 创建数组

print("### Initialization of the array\n")

//: - 创建空数组

do {
    var emptyArray0 = [Int]()
    emptyArray0.append(0)
    emptyArray0.append(1)
    print(emptyArray0)

    var fruits: [String] = []
    fruits.append("apple")
    print(fruits)
}


//: - 创建具有初始值的数组

do {
    let countries = ["USA", "India", "Russia", "China", "Japan"]
    print(countries)
}
//: - 指定大小创建数组

// Array(repeating: defaultValue, count: specificSize)

do {
    let arr0 = Array(repeating: "", count: 8)
    print(arr0)

    let arr1 = [Int](repeating: 0, count: 4)
    print(arr1)
}

//: - 创建具有不同数据类型的数组

do {
    let arr0 = ["a", 1, "b", 2, "c"] as [Any]
    print(type(of: arr0), arr0)

    let arr1: [Any] = ["a", 1, "b", 2]
    print(arr1)
}

//: ## 遍历数组

print("\n### Traversing the array\n")

var primes: [Int] = [2, 3, 5, 7, 11]

//: - for in
for prime in primes {
    print(prime, terminator: " ")
}
print("")

//: - range

print("iterating over array elements using range:", terminator: " ")
for idx in 0..<primes.count {
    print(primes[idx], terminator: " ")
}
print("")

print("iterating over array elements using indices:", terminator: " ")
for idx in primes.indices {
    print(primes[idx], terminator: " ")
}
print("")

//: - while
var idx = 0
print("iterating over array elements using while:", terminator: " ")
while idx < primes.count {
    print(primes[idx], terminator: " ")
    idx += 1
}
print("")

//: - forEach block

print("iterating over array elements using forEach block:", terminator: " ")
primes.forEach { prime in
    print("\(prime)", terminator: " ")
}
print("")

print("iterating over array elements using forEach block:", terminator: " ")
primes.forEach {
    print($0, terminator: " ")
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

print("\n### Accessing the array elements\n")

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

print("\n### Check the array\n")

//: - Check Array is Empty

let myArray: [Int] = [0, 1, 2, 3]
print("Is the array empty?", myArray.isEmpty)

do {
    let arr: [String] = []
    print("Is the array empty?", arr.isEmpty)
}

//: - Check if specific element is present

let num0: Int = 5
print("Is elelment \(num0) present in array? \(myArray.contains(num0))")

let num1: Int = 3
print("Is elelment \(num1) present in array? \(myArray.contains(num1))")

//: - 检测两个数组是否相等

do {
    let arr0: [String] = ["apple", "mango", "cherry"]
    let arr1: [String] = ["apple", "avacado", "cherry"]

    if arr0 == arr1 {
        print("Two arrays are equal.")
    } else {
        print("Two arrays are not equal.")
    }
}


//: ## 在数组中查找元素索引

print("\n### Search elements in a array\n")

//: - 查找元素索引

do {
    let fruits = ["apple", "banana", "cherry", "mango"]
    let ele = "pear"

    if let idx = fruits.firstIndex(of: ele) {
        print("Index of \(ele) is \(idx)")
    } else {
        print("'pear' is not present in the array.")
    }
}

//: - 查找元素最小值

let nums = [6, 4 ,2, 8, 10]

if let result = nums.min() {
    print("Minimum num is: \(result)")
} else {
    print("Array is emptry")
}

do {
    let fruits = ["apple", "banana", "cherry", "mango"]
    if let result = fruits.min(by: { element0, element1 in element0.count < element1.count }) {
        print("Minimum element: \(result)")
    }
}

//: - 查找最大值

if let num = nums.max() {
    print("Maximum num is: \(num)")
} else {
    print("Array is empty.")
}

do {
    let fruits = ["apple", "banana", "cherry", "mango"]
    if let result = fruits.max(by: { $0.count < $1.count}) {
        print("Maximum element: \(result)")
    }
}

//: ## 数组转换

print("\n### Transformation of the array\n")

//: - 数组添加元素

do {
    var fruits = ["apple", "banana", "cherry"]
    let anotherFruit = "mango"
    fruits.append(anotherFruit)
    print(fruits)
}

//: - 数组添加数组

do {
    var fruits = ["apple", "banana", "cherry"]
    let moreFruits = ["mango", "guava"]
    fruits.append(contentsOf: moreFruits)
    print(fruits)
}

//: - 连接两个数组

do {
    let arr01: [Int] = [22, 54]
    let arr02: [Int] = [35, 68]

    let new_array = arr01 + arr02
    print(new_array)
}

//: - 删除数组中前 N 个元素

do {
    let fruits = ["apple", "banana", "cherry"]
    print("Original Array: \(fruits)")
    let result = fruits.dropFirst(2)
    print("Drop first N result Array: \(result)")
}

//: - 删除数组中第一个元素

do {
    let fruits = ["apple", "banana", "cherry"]
    print("Original Array: \(fruits)")
    let result = fruits.dropFirst()
    print("Drop first result Array: \(result)")
}

//: - 删除数组中最后 N 个元素

do {
    let fruits = ["apple", "banana", "cherry"]
    print("Original Array: \(fruits)")
    var result = fruits.dropLast(2)
    print("Drop last N result Array: \(result)")

    result = fruits.dropLast(10)
    print("Another drop last N result Array: \(result)")

    result = fruits.dropLast()
    print("Drop last result Array: \(result)")
}

//: - 在数组指定位置插入元素

do {
    var fruits = ["apple", "banana", "cherry", "mango"]
    let fruitGuava = "guava"
    fruits.insert(fruitGuava, at: 0)
    print(fruits)
    //Swift/Array.swift:405: Fatal error: Array index is out of range
    //fruits_03.insert(fruitGuava, at: 10)
}

//: - 在数组指定公位置插入另外一个数组

do {
    var fruits = ["apple", "banana", "cherry"]
    let moreFruits = ["guava", "mango"]
    fruits.insert(contentsOf: moreFruits, at: 0)
    print(fruits)
}

//: - 删除数组中指定位置元素

var numbers = [2, 3, 5, 7, 11]
numbers.remove(at: 1)
numbers.forEach { print($0, terminator: " ") }
print("")

//: - 指定条件删除数组中元素

numbers.removeAll(where: { $0 > 5})
print(numbers)

//: - 删除数组中所有元素

numbers.removeAll()
print(numbers)

//: - 反转数组

do {
    var anotherNumbers = [2, 3, 5, 7, 11]
    print("Original array: \(anotherNumbers)")

    let reverseResult: [Int] = anotherNumbers.reversed()
    print("Reversed Array: \(reverseResult)")

    anotherNumbers.reverse()
    print("Reverse Array: \(anotherNumbers)")
}

//: [Next](@next)
