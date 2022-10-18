#  Python program to demonstrate reading files

if __name__ == '__main__':
    with open("./asm.txt") as myfile:
        for line in myfile:
            idx = line.find('; "/')
            if idx != -1:
                content = line[idx + 1: ].strip()
                print(content)