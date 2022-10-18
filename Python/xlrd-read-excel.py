import os
import xlrd

sheet_map = {"语数外考场": 0, "物理考场": 1, "化学考场": 2, "生物考场": 3, "历史考场": 4, "地理考场": 5, "政治考场": 6}

def read_excel(filename):
    # 打开文件
    workBook = xlrd.open_workbook(filename)
    # 获取 sheet 页数量
    sheet_count = workBook.nsheets
    print(f"sheet count: {sheet_count}")

    students_map = dict()
    name_col_idx, exam_number_idx = 0, 1

    # 遍历 sheet
    for idx in range(0, sheet_count):
        sheet = workBook.sheet_by_index(idx); # sheet索引从0开始   
        sheet_name = sheet.name
        # 获取行数、列数
        row_count, col_count = sheet.nrows, sheet.ncols
        print(f"sheet name: {sheet_name}, row count: {row_count}, column count: {col_count}")
        ## 遍历行
        for i in range(1, row_count):
            # 读取单元格值
            student_name = sheet.cell(i, name_col_idx).value # 姓名
            exam_number = sheet.cell(i, exam_number_idx).value # 考号

            course_idx = sheet_map[sheet_name] # 课程索引
            if student_name not in students_map:
                course_lst = [-1] * 7 # 初始化 list
                course_lst[course_idx] = exam_number
                students_map[student_name] = course_lst
            else:
                students_map[student_name][course_idx] = exam_number
    
    for k, v in  students_map.items():
        print(k, v)

def read_students(filename: str):
    wb = xlrd.open_workbook(filename)
    sheet = wb.sheet_by_index(0); # sheet索引从0开始   
    row_count = sheet.nrows
    print(f"sheet name: {sheet.name}, row count: {row_count}")

    name_col_idx = 1
    students = list()
    for i in range(2, row_count):
        name = sheet.cell(i, name_col_idx).value
        students.append(name)
    print(students)

if __name__ == '__main__':    
    
    filename = "./期中考场20221016.xlsx"
    if filename and os.path.exists(filename):
        read_excel(filename)
    else:
        print(f'invalid input file, please check your input.')