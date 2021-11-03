//
//  main.c
//  HelloLLVM
//
//  Created by jiaxw on 2021/11/3.
//

#include <stdio.h>

/*
 -Xclang -load -Xclang libSkeletonPass.so
 -Xclang -load -Xclang LLVMWObfuscation.dylib -mllvm -enable-indibran
 -Xclang -load -Xclang libHikari.so -flegacy-pass-manager
 -Xclang -load -Xclang libHikari.so -mllvm -enable-allobf
 

 -enable-bcfobf Enable Bogus Control Flow
 -enable-cffobf Enable Control Flow Flattening
 -enable-splitobf Enable Basic Block Spliting
 -enable-subobf Enable Instruction Substitution
 -enable-acdobf Enable AntiClassDump Mechanisms
 -enable-indibran Enable Register-Based Indirect Branching
 -enable-strcry Enable String Encryption
 -enable-funcwra Enable Function Wrapper
 -enable-fco Enable FunctionCallObfuscate. (See HERE for full usage)
 
 -mllvm -enable-allobf
 -mllvm -enable-indibran -mllvm -enable-strcry
 -mllvm -enable-indibran -mllvm split_num=2
 
 bcf, fla, fco, fw, indibr, split, strenc, sub
 */

int sum(int a, int b) {
    return a + b;
}

int multiply(int a, int b) __attribute__((annotate("strenc,indibr"))) {
    return a * b;
}

void swap(int *a, int *b) __attribute__((annotate("strenc,indibr"))){
    int temp;
    temp = *a;
    *a = *b;
    *b = temp;
}

int max(int a, int b){
    return a >= b ? a : b;
}


int main(int argc, const char * argv[]) {
    // insert code here...
    printf("Hello, World!\n");
    
    int a = 1;
    int b = 2;
    
    int c = sum(a, b);
    printf("%d plus %d is equal to %d\n", a, b, c);

    int d = multiply(a, b);
    printf("%d multiplied by %d equal to %d\n",a, b, d);

    swap(&a, &b);
    printf("a = %d, b = %d\n", a, b);
    
    int e = max(a, b);
    printf("max value of (%d, %d) is %d\n", a, b, e);
    
    return 0;
}
