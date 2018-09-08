# -*- coding: utf-8 -*-

import urllib.request as urllib2

def getRequest(url):
    request = urllib2.Request(url)
    request.add_header('User-Agent', 'application/x-www-form-urlencoded')
    response = urllib2.urlopen(request)
    data=response.read()
    return data
