#code=utf-8
import datetime,time
import os,re


def get_source(filename):
    f = open(filename)
    #createlist表示story创建日期;
    #startlist表示story开始工作日期;
    #endlist表示story完成日期
    
    createlist,startlist,endlist = [],[],[]

    while True:
        line = f.readline().rstrip()
        if (len(line) == 0):
            break
        pattern_day = re.compile('\d{1,2}/\d{1,2}/\d{1,2}')
        day = pattern_day.findall(line)
        '''
        CREATE DATE             START DATE              COMPLET DATE
        12/18/16, 8:15 AM	12/20/16, 2:22 PM	12/30/16, 1:58 PM
        12/19/16, 12:47 PM	12/20/16, 8:15 AM	12/20/16, 4:37 PM
        12/20/16, 11:24 AM	12/21/16, 3:59 PM	1/3/17, 10:02 AM
        '''
        if len(day) == 3:
            createlist.append(day[0])
            startlist.append(day[1])
            endlist.append(day[2])
        
    return createlist,startlist,endlist
        

def days_between(start_date,end_date) :
    if type(start_date) == str :
        start_date = datetime.datetime.strptime(start_date,'%m/%d/%y')
        end_date = datetime.datetime.strptime(end_date,'%m/%d/%y')
    #不足一天完成的story，计算成一天
    days_cost = (end_date-start_date).days + 1
    return days_cost


# story cost 不计算周末
def days_exclude_weekend(start_date,end_date):
    days_cost = days_between(start_date,end_date)
    days_real_cost = days_cost
    if type(start_date) == str :
        start_date = datetime.datetime.strptime(start_date,'%m/%d/%y')
        end_date = datetime.datetime.strptime(end_date,'%m/%d/%y')
    week,leftover = divmod(days_cost,7)
    #weekday() return 0-6
    end_date_ofweek = end_date.weekday()+1
    if week > 1:
        days_real_cost = days_cost - week*2
    if week == 0 and end_date_ofweek < leftover:
        days_real_cost = days_cost - 2
    return days_real_cost
    


if __name__ == '__main__':
    path = os.getcwd()
    filename = os.path.join(path,'datelist.txt')
    createlist,startlist,endlist = get_source(filename)
    #只计算已完成的story个数
    backlog_cost,iteration_cost,story_count = 0,0,len(endlist)
    
    #当发现文件中含3列，可以同时计算Backlog Circle Time and WIP Circle Time
    #Backlog Circle Time: In-Progress Time - Start Time
    #WIP Circle Time: Complete Time - In-Progress Time
    for i in range(0,story_count):
        backlog_cost += days_exclude_weekend(createlist[i],startlist[i])
        iteration_cost += days_exclude_weekend(startlist[i],endlist[i])
    print ('Complete Story: %d' % story_count)
    print ('Circle Time In Backlog : %.2f' % (backlog_cost/story_count) )
    print ('Circle Time In WIP: %.2f' % int(iteration_cost/story_count))
    time.sleep(30)



    
