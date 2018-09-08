import os


def read_csv(filename):
    with open(filename,'r') as f:
        lines = f.readlines()
        print (lines[0])

if __name__ == '__main__':
    filename = r'C:\Users\IBM_ADMIN\My Documents\SametimeFileTransfers\entmt.csv'
    read_csv(filename)




