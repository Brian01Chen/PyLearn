

class _CaseFilter(object):
    ttype = None

    def __init__(self, case=None):
        case = case or 'upper'
        self.convert = getattr(str, case)

    def process(self, stream):
        stream = self.convert(stream)
        return stream

if __name__ == '__main__':
    t = _CaseFilter('upper')
    stmts = 'Hello World'
    stt = t.process(stmts)
    print (stt)
        
    
    
    
