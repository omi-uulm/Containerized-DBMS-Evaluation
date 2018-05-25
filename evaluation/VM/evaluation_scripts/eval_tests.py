#! python3
import os
import numpy as np
import Gnuplot as gp

# TODO name graphs (default, docker, database name)

# test database in lowercase e.g. mongodb, couchbase
TEST_DATABASE = "mongodb"
TEST_SETUP = "disk-bound-workload"
TEST_DIRECTORY = "../results/final/"+TEST_DATABASE+"/"+TEST_SETUP+"/"
TEST_DEPLOYMENT = ['vm', 'dockered', 'dockered_attached_vol']
#TEST_DEPLOYMENT = ['dockered']
#THREAD_FOLDERS = ['1_threads/', '2_threads/', '4_threads/', '8_threads/', '16_threads/', '32_threads/', '48_threads/']
THREAD_FOLDERS = ['8_threads/']

OPERATION_METRICS = ['ins_avg_lat', 'read_avg_lat', 'upd_avg_lat']
OPERATION_LABELS = {'ins_avg_lat': 'insert',
                    'read_avg_lat': 'read',
                    'upd_avg_lat': 'update'}
# gnuplot axis range                    
OPERATION_RANGE = {'ins_avg_lat': '35000',
                    'read_avg_lat': '700000',
                    'upd_avg_lat': '',
                    'throughput': '2500',
                    'runtime': '30000000'}
#OPERATION_RANGE = {'ins_avg_lat': '',
#                    'read_avg_lat': '',
#                    'upd_avg_lat': '',
#                    'throughput': '',
#                    'runtime': ''}
X_VALUES = np.arange(1, len(THREAD_FOLDERS)+1, dtype=np.float) #amount of testcases (threads used for tests)
X_VALUES_ADVANCED = np.arange(1, 2, dtype=np.float)

GNUPLOT_OUTPUT = 'png' # set to png or pdf
SINGLE_PLOT = False # set to True if plots needed for every single Timestamp


def get_overall_data(case, td, timestamp):
    """
    Get overall test data from log files
    :param case: string e.g. load, run_workloadA, run_workloadB
    :param td: test deployment
    :return: array for all threads
    """
    runtime = []
    throughput = []

    for tf in THREAD_FOLDERS:
        with open(TEST_DIRECTORY+td+"/"+tf+timestamp+"/"+case+".txt", 'r') as file:
            for line in file:
                line = line.rstrip()
                if "[OVERALL], RunTime" in line:
                    runtime.append(convert_string_to_float(line.split(', ')[-1]))
                if "[OVERALL], Throughput" in line:
                    throughput.append(convert_string_to_float(line.split(', ')[-1]))

    data = {"runtime": runtime,
            "throughput": throughput}

    return data


def get_insert_data(case, td, timestamp):
    ins_op = []
    avg_lat = []

    for tf in THREAD_FOLDERS:
        with open(TEST_DIRECTORY+td+"/"+tf+timestamp+"/"+case+".txt", 'r') as file:
            for line in file:
                line = line.rstrip()
                if "[INSERT], Operations" in line:
                    ins_op.append(convert_string_to_float(line.split(', ')[-1]))
                if "[INSERT], AverageLatency" in line:
                    avg_lat.append(convert_string_to_float(line.split(', ')[-1]))

    data = {"ins_op": ins_op,
            "ins_avg_lat": avg_lat}

    return data


def get_read_data(case, td, timestamp):
    read_op = []
    avg_lat = []

    for tf in THREAD_FOLDERS:
        with open(TEST_DIRECTORY+td+"/"+tf+timestamp+"/"+case+".txt", 'r') as file:
            for line in file:
                line = line.rstrip()
                if "[READ], Operations" in line:
                    read_op.append(convert_string_to_float(line.split(', ')[-1]))
                if "[READ], AverageLatency" in line:
                    avg_lat.append(convert_string_to_float(line.split(', ')[-1]))

    data = {"read_op": read_op,
            "read_avg_lat": avg_lat}

    return data


def get_update_data(case, td, timestamp):
    upd_op = []
    avg_lat = []

    for tf in THREAD_FOLDERS:
        with open(TEST_DIRECTORY+td+"/"+tf+timestamp+"/"+case+".txt", 'r') as file:
            for line in file:
                line = line.rstrip()
                if "[UPDATE], Operations" in line:
                    upd_op.append(convert_string_to_float(line.split(', ')[-1]))
                if "[UPDATE], AverageLatency" in line:
                    avg_lat.append(convert_string_to_float(line.split(', ')[-1]))

    data = {"upd_op": upd_op,
            "upd_avg_lat": avg_lat}

    return data


def convert_string_to_float(value):
    return round(float(value), 0)


def generate_total_avg(data):
    values = {"load": {
                    "throughput": calc_avg('load', 'throughput', data),
                    "runtime": calc_avg('load', 'runtime', data),
                    "ins_avg_lat": calc_avg('load', 'ins_avg_lat', data),
                    "read_avg_lat": calc_avg('load', 'read_avg_lat', data),
                    "upd_avg_lat": calc_avg('load', 'upd_avg_lat', data)
              },
              #"runA": {
              #    "throughput": calc_avg('runA', 'throughput', data),
              #    "runtime": calc_avg('runA', 'runtime', data),
              #    "ins_avg_lat": calc_avg('runA', 'ins_avg_lat', data),
              #    "read_avg_lat": calc_avg('runA', 'read_avg_lat', data),
              #    "upd_avg_lat": calc_avg('runA', 'upd_avg_lat', data)
              #},
              "runB": {
                  "throughput": calc_avg('runB', 'throughput', data),
                  "runtime": calc_avg('runB', 'runtime', data),
                  "ins_avg_lat": calc_avg('runB', 'ins_avg_lat', data),
                  "read_avg_lat": calc_avg('runB', 'read_avg_lat', data),
                  "upd_avg_lat": calc_avg('runB', 'upd_avg_lat', data)
              }
            }
    return values


def calc_avg(test, metric, data):
    """Create avg of given data for specific test netric
    
    :param test: string
    :param metric: string
    :param data: dict
    :return: list
    """
    acc_data = map(lambda x: x, (d[test][metric] for d in data))
    sum_data = ([sum(x) for x in zip(*list(acc_data))])
    avg_data = [x / len(data) for x in sum_data]

    return avg_data


def read_timestamps(td):
    return sorted(os.listdir(TEST_DIRECTORY+td+'/8_threads/'))


def create_throughput_plot(data, td, timestamp):
    g = gp.Gnuplot(persist=0) #persist=1 will leave X11 window open
    load = np.array(data['load']['throughput'])
    runA = np.array(data['runA']['throughput'])
    runB = np.array(data['runB']['throughput'])

    d_load = gp.Data(X_VALUES, load, with_='linespoints lt 1 lc rgb "#C55A46" lw 3 pt 7', title='load')
    d_runA = gp.Data(X_VALUES, runA, with_='linespoints lt 1 lc rgb "#8FAADC" lw 3 pt 13', title='workloadA')
    d_runB = gp.Data(X_VALUES, runB, with_='linespoints lt 1 lc rgb "#27ad81" lw 3 pt 20', title='workloadB')

    # set y-Range from fixed values (need to be checked)
    g('set yrange [:' + OPERATION_RANGE['throughput']  + ']')
    
    #labels
    g('set xlabel "Threads"')
    g('set xtics ("1"1,"2"2,"4"3,"8"4,"16"5,"32"6,"48"7)') #set labels for threads on x axis
    #g('set xtics ("1"1,"2"2,"4"3,"8"4,"16"5,"32"6)') #set labels for threads on x axis

    g('set ylabel "Throughput [ops/sec]"')

    #legend formatting
    g('set key inside left top')
    g('set key spacing 2')

    g('set title "'+TEST_DATABASE+' '+td+' Throughput '+timestamp+'"')

    #wanna have a grid?
    #g('set grid')

    # if output to png or pdf file
    g('set term '+GNUPLOT_OUTPUT+'')
    g('set output "'+TEST_DIRECTORY+td+'/plots/overall_throughput_'+td+'_'+timestamp+'.'+GNUPLOT_OUTPUT+'"')

    g.plot(d_load, d_runA, d_runB)


def create_runtime_plot(data, td, timestamp):
    g = gp.Gnuplot(persist=0)  # persist=1 will leave X11 window open
    load = np.array(data['load']['runtime'])
    runA = np.array(data['runA']['runtime'])
    runB = np.array(data['runB']['runtime'])

    d_load = gp.Data(X_VALUES, load, with_='linespoints lt 1 lc rgb "#C55A46" lw 3 pt 7', title='load')
    d_runA = gp.Data(X_VALUES, runA, with_='linespoints lt 1 lc rgb "#8FAADC" lw 3 pt 13', title='workloadA')
    d_runB = gp.Data(X_VALUES, runB, with_='linespoints lt 1 lc rgb "#27ad81" lw 3 pt 20', title='workloadB')

    # set y-Range from fixed values (need to be checked)
    g('set yrange [:' + OPERATION_RANGE['runtime']  + ']')

    # labels
    g('set xlabel "Threads"')
    g('set xtics ("1"1,"2"2,"4"3,"8"4,"16"5,"32"6,"48"7)')  # set labels for threads on x axis
    #g('set xtics ("1"1,"2"2,"4"3,"8"4,"16"5,"32"6)') #set labels for threads on x axis

    g('set ylabel "Runtime [ms]"')

    # legend formatting
    g('set key inside right top')
    g('set key spacing 2')

    g('set title "'+TEST_DATABASE+' '+td+' Runtime ' + timestamp + '"')

    # wanna have a grid?
    # g('set grid')

    # if output to png or pdf file
    g('set term '+GNUPLOT_OUTPUT+'')
    g('set output "'+TEST_DIRECTORY + td + '/plots/overall_runtime_'+ td + '_' + timestamp + '.'+GNUPLOT_OUTPUT+'"')

    g.plot(d_load, d_runA, d_runB)


def create_latency_plot(data, td, timestamp):
    for om in OPERATION_METRICS:
        g = gp.Gnuplot(persist=0)  # persist=1 will leave X11 window open
        load = np.array(data['load'][om])
        if (len(load) == 0):
            load = np.zeros(len(THREAD_FOLDERS))

        runA = np.array(data['runA'][om])
        if (len(runA) == 0):
            runA = np.zeros(len(THREAD_FOLDERS))
        runB = np.array(data['runB'][om])
        if (len(runB) == 0):
            runB = np.zeros(len(THREAD_FOLDERS))

        d_load = gp.Data(X_VALUES, load, with_='linespoints lt 1 lc rgb "#C55A46" lw 3 pt 7', title='load')
        d_runA = gp.Data(X_VALUES, runA, with_='linespoints lt 1 lc rgb "#8FAADC" lw 3 pt 13', title='workloadA')
        d_runB = gp.Data(X_VALUES, runB, with_='linespoints lt 1 lc rgb "#27ad81" lw 3 pt 20', title='workloadB')

        # set y-Range from fixed values (need to be checked)
        g('set yrange [:' + OPERATION_RANGE[om]  + ']')

        # labels
        g('set xlabel "Threads"')
        g('set xtics ("1"1,"2"2,"4"3,"8"4,"16"5,"32"6,"48"7)')  # set labels for threads on x axis
        #g('set xtics ("1"1,"2"2,"4"3,"8"4,"16"5,"32"6)') #set labels for threads on x axis

        g('set ylabel "Average Latency (us)"')

        # legend formatting
        g('set key inside left top')
        g('set key spacing 2')

        g('set title "'+TEST_DATABASE+' '+td+' '+OPERATION_LABELS[om]+' latency ' + timestamp + '"')

        # wanna have a grid?
        # g('set grid')

        # if output to png or pdf file
        g('set term '+GNUPLOT_OUTPUT+'')
        g('set output "'+TEST_DIRECTORY + td + '/plots/'+OPERATION_LABELS[om]+'_latency_'+ td + '_' + timestamp + '.'+GNUPLOT_OUTPUT+'"')

        g.plot(d_load, d_runA, d_runB)

def plot_deprecated_single(values, td, timestamp):
    create_throughput_plot(values, td, timestamp)
    create_latency_plot(values, td, timestamp)
    create_runtime_plot(values, td, timestamp)

###########################################################
# plots for advanced evaluation
###########################################################

def print_runB_data(deployment_data, test_metric):
    g = gp.Gnuplot(persist=0) #persist=1 will leave X11 window open
    vm_data = np.array(deployment_data['vm']['runB'][test_metric])
    docker_data = np.array(deployment_data['dockered']['runB'][test_metric])
    docker_host_vol_data = np.array(deployment_data['dockered_attached_vol']['runB'][test_metric])

    d_data = gp.Data(vm_data, title='vm')
    d_docker = gp.Data(docker_data, title='dockered')
    d_docker_host_vol = gp.Data(docker_host_vol_data, title='dockered-host')

    # set y-Range from fixed values (need to be checked)
    #g('set yrange [:' + OPERATION_RANGE['throughput']  + ']')
    
    #g('set auto x')
    g('set style data histogram')
    g('set style histogram cluster gap 1')
    g('set style fill solid noborder')
    g('set boxwidth 0.9')
    g('set xtic rotate by -45 scale 0')

    #labels
    g('set xlabel "Setup"')
    g('set xtics ("vm"1,"docker"2,"docker vol"3)') #set labels for threads on x axis
    #g('set xtics ("1"1,"2"2,"4"3,"8"4,"16"5,"32"6)') #set labels for threads on x axis

    #g('set ylabel '+test_metric+'')

    #legend formatting
    g('set key inside left top')
    g('set key spacing 2')

    g('set title "'+TEST_DATABASE+' '+TEST_SETUP+' '+test_metric+' total'+'"')

    #wanna have a grid?
    #g('set grid')

    # if output to png or pdf file
    g('set term '+GNUPLOT_OUTPUT+'')
    g('set output "'+TEST_DIRECTORY+'plots/overall_'+test_metric+'.'+GNUPLOT_OUTPUT+'"')

    g.plot(d_data, d_docker, d_docker_host_vol)


def get_data():
    deployment_data = {}
    for td in TEST_DEPLOYMENT:
        timestamps = read_timestamps(td)
        aggr_values = []
        for timestamp in timestamps:
            # load other data from methods
            load = {}
            load.update(get_overall_data("load", td, timestamp))
            load.update(get_insert_data("load", td, timestamp))
            load.update(get_read_data("load", td, timestamp))
            load.update(get_update_data("load", td, timestamp))

            #runA = {}
            #runA.update(get_overall_data("run_workloadA", td, timestamp))
            #runA.update(get_insert_data("run_workloadA", td, timestamp))
            #runA.update(get_read_data("run_workloadA", td, timestamp))
            #runA.update(get_update_data("run_workloadA", td, timestamp))

            runB = {}
            runB.update(get_overall_data("run_workloadB", td, timestamp))
            runB.update(get_insert_data("run_workloadB", td, timestamp))
            runB.update(get_read_data("run_workloadB", td, timestamp))
            runB.update(get_update_data("run_workloadB", td, timestamp))

            values = {"load": load,
                    #"runA": runA,
                    "runB": runB}
            aggr_values.append(values)

           #if SINGLE_PLOT:
           #    plot_deprecated_single(values, td, timestamp)

        # create average for latency and other metrics
        total_avg = generate_total_avg(aggr_values)
        deployment_data.update({td: total_avg})

        # deprecated plot. but keep it at the moment in case of multiple runs with different threadcount
        #create_throughput_plot(total_avg, td, 'total')
        #create_latency_plot(total_avg, td, 'total')
        #create_runtime_plot(total_avg, td, 'total')

    # plot test data
    print_runB_data(deployment_data, "throughput")
    print_runB_data(deployment_data, "runtime")
    print_runB_data(deployment_data, "upd_avg_lat")
    print_runB_data(deployment_data, "read_avg_lat")


#init function call
get_data()
