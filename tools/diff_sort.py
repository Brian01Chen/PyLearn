
def diff_file(f1,f2,is_sort = False):

    if is_sort == False:
        with open(f1,'r') as srcfile,open(f2,'r') as cmpfile:
            cmpcontent = cmpfile.readlines()
            for sn,sline in enumerate(srcfile):
                row , besti, bestj, bestsize = 0, 0, 0, 0
                sl = sline.split()
                
                ssize = len(sline.split())
                cmpcopy = [(rn,line) for rn,line in enumerate(cmpcontent)]
                for cmp in cmpcopy:
                    i, j, size = row_best_match(sline,cmp[1])
                    if size == ssize and i==0 and j==0 :
                    
                        row, besti, bestj, bestsize = cmp[0], i, j, size
                        cmpcopy.remove(cmp)
                        break
                    elif size > bestsize:
                        row, besti, bestj, bestsize = cmp[0], i, j, size
                        continue
                    else:
                        continue
                print ('sn, row, besti, bestj, bestsize,srclenth: ', sn, row, besti, bestj, bestsize, ssize)
    else:
        pass

    
def row_best_match(a,b,alo,ahi,blo,bhi):
    besti, bestj, bestsize = alo, blo, 0
    
    b2j = {}
    for i, elt in enumerate(b):
            indices = b2j.setdefault(elt, [])
            indices.append(i)
    j2len = {}
    nothing = []
    for i in range(alo, ahi):
            # look at all instances of a[i] in b; note that because
            j2lenget = j2len.get                            # j2lenget 字典记录历史数据
            newj2len = {}                                   # newj2len 每次都初始化
            for j in b2j.get(a[i], nothing):
                # a[i] matches b[j]
                if j < blo:
                    continue
                if j >= bhi:
                    break
                k = newj2len[j] = j2lenget(j-1, 0) + 1      # j2lenget(j-1) 记录了上次 k-1 
                if k > bestsize :                           # k>= 可以就远匹配
                    besti, bestj, bestsize = i-k+1, j-k+1, k
            #print ('besti, bestj, bestsize: ' , besti, bestj, bestsize)    
            j2len = newj2len
    
    return besti, bestj, bestsize

def row_all_match_block(a,b):
    
    la,lb = len(a),len(b)
    queue = [(0,la,0,lb)]
    matching_blocks = []
    
    while queue:
        alo,ahi,blo,bhi = queue.pop()
        
        i,j,k = x = row_best_match(a, b, alo, ahi, blo, bhi)
        if k:
            matching_blocks.append(x)
            if alo < i and blo < j:
                queue.append((alo, i, blo, j))
            if i+k < ahi and j+k < bhi:
                queue.append((i+k, ahi, j+k, bhi))
    matching_blocks.sort()
    matching_blocks.append((la,lb,0))
    return matching_blocks

def get_opcodes(matching_blocks):
    i = j = 0
    opcodes = answer = []
    print (matching_blocks)
    for ai,bj,size in matching_blocks:
        tag = ''
        if i < ai and j < bj:
            tag = 'replace'
        elif i < ai:
            #print (i,j,ai,bj,size)
            tag = 'delete'
        elif j < bj:
            tag = 'insert'
        if tag:
            answer.append( (tag, i, ai, j, bj) )
        i, j = ai+size, bj+size
        # the list of matching blocks is terminated by a
        # sentinel with size 0
        if size:
            answer.append( ('equal', ai, i, bj, j) )
    return answer 

if __name__ == '__main__':
    f1 = r'C:\Users\IBM_ADMIN\Desktop\1old.txt'
    f2 = r'C:\Users\IBM_ADMIN\Desktop\2ne.txt'
    diff_file(f1,f2)
    a1 = 'Heloo Friday Moring Good Day\n'
    b1 = 'Hello he Friday Moring Day'
    a11 = a1.split()
    b11 = b1.split()
    blocks = row_all_match_block(a11,b11)
    #print (blocks)
    answer = get_opcodes(blocks)
    #print (answer)

    
    
