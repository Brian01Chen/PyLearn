import os
import re,codecs
import xml.dom.minidom
import xml.dom


'''
<Collection Name="Properties" Type="CustomProperty">
...
<SubRecord>
               <Property Name="Name">USERSQL</Property>
               <Property Name="Value" PreFormatted="1"> txt
</SubRecord>
...
'''

ELEMENT_NODE = xml.dom.Node.ELEMENT_NODE
TEXT_NODE = xml.dom.Node.TEXT_NODE

class XmlItems(object):

    def __init__(self,source):
        if type(source) == str: 
            self.root = xml.dom.minidom.parse(source)
        else:
            self.root = data
        self.currentNode = self.root
        self.textlist = []
        
    def setCurrentNode (self,node):
        self.currentNode = node
    #获取tagName下所有匹配attrFilter的 text list
    def getTextList(self,tagName,attrFilter=()):
        textlist = self.textlist
        currentNode = self.currentNode
        attrdic = attrFilter
        if currentNode == self.root:
            try :
                nodes = [node for node in currentNode.getElementsByTagName(tagName) \
                     if ((attrdic != () and node.getAttribute(attrdic[0]) == attrdic[1])or attrdic == {})]
            except AttributeError:
                nodes = [node for node in currentNode.getElementsByTagName(tagName)]
        else:
            nodes = [node for node in currentNode.childNodes]
        for node in nodes:
            if node.hasChildNodes():
                for cnode in node.childNodes:
                    if cnode.nodeType == TEXT_NODE:
                        if re.match('\S',cnode.data) :
                            textlist.append(cnode.data)
                    if cnode.nodeType == ELEMENT_NODE:
                        self.setCurrentNode(cnode)
                        self.getTextList(tagName)
            else:
                if node.nodeType == TEXT_NODE:
                    if re.match('\S',node.data) :
                        textlist.append(node.data) 
        return textlist
                
    def getTextNode(self,text):
        currentNode = self.currentNode
        for node in root.getElementsByTagName('tagName'):
            pass
        
def getSourceCode(source):
    nodelist = dom.getElementsByTagName('Record')
    collect = dom.getElementsByTagName('Collection')
    for colt in collect:
        if colt.parentNode.getAttribute('Identifier') == 'V0S0P1':
            if colt.getAttribute('Type') == 'CustomProperty':
                sqlrecord = [record.getElementsByTagName('Property') \
                             for record in colt.getElementsByTagName('SubRecord') \
                             if record.getElementsByTagName('Property')[0].firstChild.data == 'USERSQL']
                print (sqlrecord)
                prop = colt.getElementsByTagName('Property')
                for p in prop:
                    proptxt = prop[prop.index(p)-1].firstChild
                    if proptxt.nodeType == xml.dom.Node.TEXT_NODE:
                        if proptxt.data == 'USERSQL':
                            print (p.firstChild.data   )
            if colt.getAttribute('Type') == 'OutputColumn':
                columns = [x.firstChild.data for x in colt.getElementsByTagName('Property')\
                           if x.getAttribute('Name') == 'Name']
                print (columns)
                      

if __name__ == '__main__':   
    filename = r'C:\Users\IBM_ADMIN\AppData\Local\Programs\Python\Python35\mysrc\tools\log analyse\ds log\Del_Updted_Entmt_Sum_Fact.xml'
    dom = xml.dom.minidom.parse(filename)
    #getSourceCode(dom)
    dsxml = XmlItems(filename)
    dxlist = dsxml.getTextList('Property',('PreFormatted','1'))
    print (dxlist)

