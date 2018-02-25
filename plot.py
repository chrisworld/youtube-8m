import os
import sys
import numpy as np
import argparse
#import matplotlib.pyplot as plt
#from scipy.interpolate import UnivariateSpline
#from matplotlib.pyplot import figure, show

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
                #print "%s: %s" %(tag, t)
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
                #print "%s: %s" %(tag, t)
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
        print "file: ", f
        for set_ in sets:
            #print '... loading %s' % os.path.basename(f)
            print "... set: ", set_
            print '... loading %s' % '../' + '/'.join(f.split('/')[-3:])
            lines = read(f)
            if 'yt8m' in f:
                container[f] = parseYT8M(lines, set_, tag='Loss')
                #container[f] = parseYT8M(lines, set_, tag='Hit@1')
            else:
                #container['score'] = parse(lines, set_)
                container[f] = parse(lines, set_)
    
    print "sucess"

    # put data into the traces
    line_labels = ['Logistic', 'LSTM', 'GRU']
    trace = []
    label = 0;
    for f in files:
        step = range(len(container[f]))
        #trace.append(Scatter(y=container[f], x=step, name=f, lines=1.3))

        # line plot
        #trace.append({'type': 'scatter', 'mode': 'lines', 'name': line_labels[label], 'x': step, 'y': container[f], 'line': {'shape': 'spline', 'smoothing': 1}})
        
        # box plot
        trace.append({'type': 'box', 'name': line_labels[label], 'y': container[f]})
        label = label + 1

    data = Data(trace)

py.plot(data, filename = 'Loss_unbal_3e_box')

# call plot in terminal py2.7
#python plot.py logs/exp3/yt8m_train_bal_train_FrameLevelLogisticModel_100epochs.log logs/exp3/yt8m_train_bal_train_LstmModel_100epochs.log logs/exp3/yt8m_train_bal_train_GRUModel_100epochs.log train
#python plot.py logs/exp3/yt8m_train_unbal_train_FrameLevelLogisticModel_3epochs.log logs/exp3/yt8m_train_unbal_train_LstmModel_3epochs.log logs/exp3/yt8m_train_unbal_train_GRUModel_3epochs.log train
