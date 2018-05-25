"""Script for plotting data from influx db in gnuplot

sample query
curl -G 'http://127.0.0.1:8086/query?pretty=true' --data-urlencode "db=telegraf" --data-urlencode "q=SELECT max(\"usage_user\") AS \"max_usage_user\", max(\"usage_system\") AS \"max_usage_system\" FROM \"telegraf\".\"autogen\".\"cpu\" WHERE time > now() - 1m AND (\"host\"='couchbase-vm-ubuntu-14-04' OR \"host\"='ycsb-v12-large') GROUP BY time(10s), \"host\"" -vvv


"""
import os
import json
import numpy as np
import Gnuplot as gp
import sys
import requests


TEST_DIRECTORY = "./influxplots/"
GNUPLOT_OUTPUT = 'png' # set to png or pdf


command = "ssh omi_influx \"curl -G 'http://127.0.0.1:8086/query?pretty=true' --data-urlencode \\\"db=telegraf\\\" --data-urlencode \\\"epoch=h\\\" --data-urlencode \\\"q=SELECT max(\\\"usage_user\\\") AS \\\"max_usage_user\\\", max(\\\"usage_system\\\") AS \\\"max_usage_system\\\" FROM \\\"telegraf\\\".\\\"autogen\\\".\\\"cpu\\\" WHERE time > now() - 1h AND (\\\"host\\\"='couchbase-vm-ubuntu-14-04' OR \\\"host\\\"='ycsb-v12-large') GROUP BY time(10s), \\\"host\\\"\\\"\""

res = os.popen(command).read()
jsonresult = json.loads(res)
#print(json.dumps(jsonresult, indent=4, sort_keys=True))


def create_plot(timestamp, cpu_sys, cpu_user, hostname):
    g = gp.Gnuplot(persist=0) #persist=1 will leave X11 window open
    X_VALUES = np.arange(1, len(cpu_sys)+1, dtype=np.float)
    timestamp_np = np.array(timestamp)
    cpu_sys_np = np.array(cpu_sys)
    cpu_user_np = np.array(cpu_user)

    d_cpu_sys = gp.Data(X_VALUES, cpu_sys_np, with_='linespoints lt 1 lc rgb "#8FAADC" lw 1 pt 0', title='cpu sys')
    d_cpu_user = gp.Data(X_VALUES, cpu_user_np, with_='linespoints lt 1 lc rgb "#27ad81" lw 1 pt 0', title='cpu user')

    # set y-Range from fixed values (need to be checked)
    #g('set yrange [:' + OPERATION_RANGE['throughput']  + ']')
    
    #labels
    g('set xlabel "Time"')

    g('set ylabel "CPU usage"')

    #legend formatting
    g('set key inside left top')
    g('set key spacing 2')

    #g('set title "'+TEST_DATABASE+' '+td+' Throughput '+timestamp+'"')

    #wanna have a grid?
    #g('set grid')

    # if output to png or pdf file
    g('set term '+GNUPLOT_OUTPUT+'')
    g('set output "'+TEST_DIRECTORY+hostname+'.'+GNUPLOT_OUTPUT+'"')

    g.plot(d_cpu_sys, d_cpu_user)


def read_json(jsonresult):
    for statement in jsonresult['results']:
        #create_plot(jsonresult['results'][])
        for series in statement['series']:
            hostname = series['tags']['host']
            #print(series)
            timestamps = []
            cpu_user = []
            cpu_sys = []
            for value in series['values']:
                timestamps.append(value[0])
                cpu_user.append(0) if not (value[1]) else cpu_user.append(value[1])
                cpu_sys.append(0) if not (value[2]) else cpu_sys.append(value[2])
                
                create_plot(timestamps, cpu_sys, cpu_user, hostname)

read_json(jsonresult)
