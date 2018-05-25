#! python3
import os
import numpy as numpy
import Gnuplot as gp
import json
import pprint

# test database in lowercase e.g. mongodb, couchbase
TEST_DATABASE = "mongodb"
#TEST_SETUP = "disk-bound-workload"
TEST_SETUP = "memory-bound-workload"
TEST_DIRECTORY = "../results/final/"+TEST_DATABASE+"/"+TEST_SETUP+"/"
TEST_DEPLOYMENT = ['baremetal_dockered', 'baremetal_dockered_attached_vol', 'vm', 'vm_dockered', 'vm_dockered_attached_vol']
THREAD_FOLDERS = ['8_threads/']


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
                    runtime.append(
                        (convert_string_to_float(line.split(', ')[-1]) / 1000 / 60)
                    )
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

def read_timestamps(td):
    return sorted(os.listdir(TEST_DIRECTORY+td+'/8_threads/'))

def get_data():
    deployment_data = {}
    for td in TEST_DEPLOYMENT:
        print("----------------------------")
        print("Handle Configuration " + td)
        timestamps = read_timestamps(td)
        metricsOverAllRuns = {"metricsLoadPhase": {}, "metricsWorkloadBPhase": {}}
        for timestamp in timestamps:
            # load other data from methods
            metricsLoadPhase = {}
            metricsLoadPhase.update(get_overall_data("load", td, timestamp))    # returns metrics: throughput, runtime
            metricsLoadPhase.update(get_insert_data("load", td, timestamp))     # returns metrics: ins_avg_lat, ins_op
            metricsLoadPhase.update(get_read_data("load", td, timestamp))       # returns metrics: read_avg_lat, read_op
            metricsLoadPhase.update(get_update_data("load", td, timestamp))     # returns metrics: upd_avg_lat, upd_op

            metricsWorkloadBPhase = {}
            metricsWorkloadBPhase.update(get_overall_data("run_workloadB", td, timestamp))
            metricsWorkloadBPhase.update(get_insert_data("run_workloadB", td, timestamp))
            metricsWorkloadBPhase.update(get_read_data("run_workloadB", td, timestamp))
            metricsWorkloadBPhase.update(get_update_data("run_workloadB", td, timestamp))

            values = {"metricsLoadPhase": metricsLoadPhase,
                    "metricsWorkloadBPhase": metricsWorkloadBPhase}

            # write stats for each run
            tf = "8_threads/"
            with open(TEST_DIRECTORY+td+"/"+tf+timestamp+"/data.json", 'w') as fp:
                json.dump(values, fp)

            for metric in metricsLoadPhase:
                if metric in metricsOverAllRuns["metricsLoadPhase"]:
                    metricsOverAllRuns["metricsLoadPhase"][metric] = numpy.append(metricsOverAllRuns["metricsLoadPhase"][metric], metricsLoadPhase[metric])
                else:
                    metricsOverAllRuns["metricsLoadPhase"][metric] = numpy.array(metricsLoadPhase[metric])
            for metric in metricsWorkloadBPhase:
                if metric in metricsOverAllRuns["metricsWorkloadBPhase"]:
                    metricsOverAllRuns["metricsWorkloadBPhase"][metric] = numpy.append(metricsOverAllRuns["metricsWorkloadBPhase"][metric], metricsWorkloadBPhase[metric])
                else:
                    metricsOverAllRuns["metricsWorkloadBPhase"][metric] = numpy.array(metricsWorkloadBPhase[metric])                     
                

        # calculate stats for configuration
        metricsForConfiguration = {"metricsLoadPhase": {}, "metricsWorkloadBPhase": {}}
        for metric in metricsOverAllRuns["metricsLoadPhase"]:
            if metricsOverAllRuns["metricsLoadPhase"][metric].size > 0:
                metricsForConfiguration["metricsLoadPhase"][metric] = {
                    "avg": numpy.average(metricsOverAllRuns["metricsLoadPhase"][metric]),
                    "std": numpy.std(metricsOverAllRuns["metricsLoadPhase"][metric]),
                    "min": numpy.amin(metricsOverAllRuns["metricsLoadPhase"][metric]),
                    "max": numpy.amax(metricsOverAllRuns["metricsLoadPhase"][metric])
                }
        for metric in metricsOverAllRuns["metricsWorkloadBPhase"]:
            if metricsOverAllRuns["metricsWorkloadBPhase"][metric].size > 0:
                metricsForConfiguration["metricsWorkloadBPhase"][metric] = {
                    "avg": numpy.average(metricsOverAllRuns["metricsWorkloadBPhase"][metric]),
                    "std": numpy.std(metricsOverAllRuns["metricsWorkloadBPhase"][metric]),
                    "min": numpy.amin(metricsOverAllRuns["metricsWorkloadBPhase"][metric]),
                    "max": numpy.amax(metricsOverAllRuns["metricsWorkloadBPhase"][metric])
                }

        # write stats for each configuration
        tf = "8_threads/"
        with open(TEST_DIRECTORY+td+"/plots/data.json", 'w') as fp:
            json.dump(metricsForConfiguration, fp)
        print(metricsForConfiguration)

        # create average for latency and other metrics
        #total_avg = generate_total_avg(aggr_values)
        #deployment_data.update({td: total_avg})

        # deprecated plot. but keep it at the moment in case of multiple runs with different threadcount
        #create_throughput_plot(total_avg, td, 'total')
        #create_latency_plot(total_avg, td, 'total')
        #create_runtime_plot(total_avg, td, 'total')

    # plot test data
    #print_runB_data(deployment_data, "throughput")
    #print_runB_data(deployment_data, "runtime")
    #print_runB_data(deployment_data, "upd_avg_lat")
    #print_runB_data(deployment_data, "read_avg_lat")


#init function call
get_data()
