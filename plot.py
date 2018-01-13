import os
import sys
import numpy as np
import argparse
import matplotlib.pyplot as plt
from scipy.interpolate import UnivariateSpline
from matplotlib.pyplot import figure, show

import plotly.plotly as py
from plotly.graph_objs import *

trace0 = Scatter(
    x=[1, 2, 3, 4],
    y=[10, 15, 13, 17]
)
trace1 = Scatter(
    x=[1, 2, 3, 4],
    y=[16, 5, 11, 9]
)
data = Data([trace0, trace1])

#py.plot(data, filename = 'basic-line')



# ------------------------------------------------------------------------------
#---------------------------------------
def read(path):
    lines = []
    try:
        f = open(path,'r')
        lines = [line for line in f.read().split('\n')]
        f.close()
        return lines
    except:
        print '... error loading %s' % path
        return lines

#---------------------------------------
def parse(lines, set_='test', tag='Hit@1'):
    data = []
    try:
        for l in lines:
            if set_ in l and tag in l and 'epoch ' in l and 'package 0' in l:
                tag_pos = l.find(tag, l.find(set_ + ':')) + len(tag + ': ')
                t = l[tag_pos : tag_pos + 6]
                print "%s: %s" %(tag, t)
                data.append(float(t))
    except:
        print 'error parsing %s' % set_
        pass
    return data

#---------------------------------------
def parseYT8M(lines, set_='test', tag='Hit@1'):
    data = []
    try:
        for l in lines:
            if tag in l:
                tag_pos = l.find(tag) + len(tag + ': ')
                t = l[tag_pos : tag_pos + 4]
                print "%s: %s" %(tag, t)
                data.append(float(t))
    except:
        print 'error parsing %s' % set_
        pass
    return data

#---------------------------------------
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Logfile plotting script.')
    parser.add_argument('filepath', metavar='p', help='logfile path', nargs='+')
    parser.add_argument('sets', help='data set', default='train,test')
    args = parser.parse_args()
    files = args.filepath
    sets = args.sets.split(',')
    container = {}
    for f in files:
        for set_ in sets:
            #print '... loading %s' % os.path.basename(f)
            print "set: ", set_
            print '... loading %s' % '../' + '/'.join(f.split('/')[-3:])
            lines = read(f)
            if 'yt8m' in f:
                container['score'] = parseYT8M(lines, set_)
            else:
                container['score'] = parse(lines, set_)
    
    print "sucess"
    #print container['score']
    step = range(len(container['score']))
    #print step
    trace0 = Scatter(y=container['score'], x=step)
    data = Data([trace0])
    
py.plot(data, filename = 'basic-line')
