import difflib
import re
import sys,os


def comptxt(text1,text2):
    text1_lines = text1.splitlines()
    text2_lines = text2.splitlines()

    pattern = re.compile(" \t")
    hdiff = difflib.HtmlDiff()
    diff = hdiff.make_file(text1_lines, text2_lines)
    #open any web exploer,and enter 'c:\info.html' to view compare result
    with open (r'c:\info.html','w+') as htmlf:
        htmlf.write(diff)
    htmlf.close()
    seqdiff = difflib.SequenceMatcher()
    seqdiff.a = text1
    seqb = seqdiff.b = text2
    for i, elt in enumerate(seqb):
            #print (elt)
            indices = seqdiff.b2j.setdefault(elt, [])
            indices.append(i)

    
def compfile(file1,file2):
    if os.path.exists(file1) and os.path.exists(file2):
        f1 = open(file1,'r')
        content1 = f1.readlines()
        if content1:
            text1 = '\n'.join(content1)
        f2 = open(file2,'r')
        content2 = f2.readlines()
        if content2:
            text2 = '\n'.join(content2)
        if text1 and text2:
            comptxt(text1,text2)
    else:
        print ('filename invalid')

if __name__ == '__main__':
    file1 = r'C:\Users\IBM_ADMIN\Desktop\1old.txt'
    file2 = r'C:\Users\IBM_ADMIN\Desktop\2ne.txt'

    text1 = """ select 1,2
                 from                sysdummy1
                where
                
                with ur;"""
    text2 = """ select 1,2
                 from
                sysdummy1
                with ur;   """

    comptxt(text1,text2)
    #compfile(file1,file2)
