import sys
import random

PTRACE_FILENAME = 'fermi.ptrace'
FLOORPLAN_FORMAT_CLONE = False

def gen_rand(component_powers):
    values = []
    values.append(round(component_powers[1], 4))
    for _ in range(0, 2):
        if component_powers[1] - component_powers[0] < component_powers[2] - component_powers[1]:
            val1 = random.uniform(component_powers[0], component_powers[1])
            val2 = 2 * component_powers[1] - val1
            while val2 >= component_powers[2]:
                val1 = random.uniform(component_powers[0], component_powers[1])
                val2 = 2 * component_powers[1] - val1
        else:
            val1 = random.uniform(component_powers[1], component_powers[2])
            val2 = 2 * component_powers[1] - val1
            while val2 <= component_powers[0]:
                val1 = random.uniform(component_powers[1], component_powers[2])
                val2 = 2 * component_powers[1] - val1
        values.append(round(val1, 4))
        values.append(round(val2, 4))
    return values

def main():
    if len(sys.argv) != 2:
        print('Usage: python3 power_report_to_ptrace_converter.py <power_report_log_file>')
        sys.exit(0)
    with open(sys.argv[1], 'r') as power_report:
        lines = power_report.readlines()
        component_powers = {}
        for line in lines:
            power = line.split(' = ')
            if len(power) == 2:
                if power[0][-2] == 'P':
                    component = power[0][8:-2]
                    if 'avg' in power[0]:
                        if component == 'IB':
                            if 'IC' not in component_powers.keys():
                                component_powers['IC'] = (0, float(power[1]), 0)
                            else:
                                component_powers['IC'] = (component_powers['IC'][0], component_powers['IC'][1] + float(power[1]), component_powers['IC'][2])
                        elif component == 'SHRD':
                            if 'DC' not in component_powers.keys():
                                component_powers['DC'] = (0, float(power[1]), 0)
                            else:
                                component_powers['DC'] = (component_powers['DC'][0], component_powers['DC'][1] + float(power[1]), component_powers['DC'][2])
                        elif component == 'TC':
                            if 'CC' not in component_powers.keys():
                                component_powers['CC'] = (0, float(power[1]), 0)
                            else:
                                component_powers['CC'] = (component_powers['CC'][0], component_powers['CC'][1] + float(power[1]), component_powers['CC'][2])
                        elif component == 'SP' or component == 'FPU' or component == 'IDLE_CORE' or component == 'PIPE':
                            if 'CORE' not in component_powers.keys():
                                component_powers['CORE'] = (0, float(power[1]), 0)
                            else:
                                component_powers['CORE'] = (component_powers['CORE'][0], component_powers['CORE'][1] + float(power[1]), component_powers['CORE'][2])
                        elif component == 'MC':
                            if 'DRAM' not in component_powers.keys():
                                component_powers['DRAM'] = (0, float(power[1]), 0)
                            else:
                                component_powers['DRAM'] = (component_powers['DRAM'][0], component_powers['DRAM'][1] + float(power[1]), component_powers['DRAM'][2])
                        else:
                            if component not in component_powers.keys():
                                component_powers[component] = (0, float(power[1]), 0)
                            else:
                                component_powers[component] = (component_powers[component][0], component_powers[component][1] + float(power[1]), component_powers[component][2])
                    elif 'max' in power[0]:
                        if component == 'IB':
                            if 'IC' not in component_powers.keys():
                                component_powers['IC'] = (0, 0, float(power[1]))
                            else:
                                component_powers['IC'] = (component_powers['IC'][0], component_powers['IC'][1], component_powers['IC'][2] + float(power[1]))
                        elif component == 'SHRD':
                            if 'DC' not in component_powers.keys():
                                component_powers['DC'] = (0, 0, float(power[1]))
                            else:
                                component_powers['DC'] = (component_powers['DC'][0], component_powers['DC'][1], component_powers['DC'][2] + float(power[1]))
                        elif component == 'TC':
                            if 'CC' not in component_powers.keys():
                                component_powers['CC'] = (0, 0, float(power[1]))
                            else:
                                component_powers['CC'] = (component_powers['CC'][0], component_powers['CC'][1], component_powers['CC'][2] + float(power[1]))
                        elif component == 'SP' or component == 'FPU' or component == 'IDLE_CORE' or component == 'PIPE':
                            if 'CORE' not in component_powers.keys():
                                component_powers['CORE'] = (0, 0, float(power[1]))
                            else:
                                component_powers['CORE'] = (component_powers['CORE'][0], component_powers['CORE'][1], component_powers['CORE'][2] + float(power[1]))
                        elif component == 'MC':
                            if 'DRAM' not in component_powers.keys():
                                component_powers['DRAM'] = (0, 0, float(power[1]))
                            else:
                                component_powers['DRAM'] = (component_powers['DRAM'][0], component_powers['DRAM'][1], component_powers['DRAM'][2] + float(power[1]))
                        else:
                            if component not in component_powers.keys():
                                component_powers[component] = (0, 0, float(power[1]))
                            else:
                                component_powers[component] = (component_powers[component][0], component_powers[component][1], component_powers[component][2] + float(power[1]))
                    elif 'min' in power[0]:
                        if component == 'IB':
                            if 'IC' not in component_powers.keys():
                                component_powers['IC'] = (float(power[1]), 0, 0)
                            else:
                                component_powers['IC'] = (component_powers['IC'][0] + float(power[1]), component_powers['IC'][1], component_powers['IC'][2])
                        elif component == 'SHRD':
                            if 'DC' not in component_powers.keys():
                                component_powers['DC'] = (float(power[1]), 0, 0)
                            else:
                                component_powers['DC'] = (component_powers['DC'][0] + float(power[1]), component_powers['DC'][1], component_powers['DC'][2])
                        elif component == 'TC':
                            if 'CC' not in component_powers.keys():
                                component_powers['CC'] = (float(power[1]), 0, 0)
                            else:
                                component_powers['CC'] = (component_powers['CC'][0] + float(power[1]), component_powers['CC'][1], component_powers['CC'][2])
                        elif component == 'SP' or component == 'FPU' or component == 'IDLE_CORE' or component == 'PIPE':
                            if 'CORE' not in component_powers.keys():
                                component_powers['CORE'] = (float(power[1]), 0, 0)
                            else:
                                component_powers['CORE'] = (component_powers['CORE'][0] + float(power[1]), component_powers['CORE'][1], component_powers['CORE'][2])
                        elif component == 'MC':
                            if 'DRAM' not in component_powers.keys():
                                component_powers['DRAM'] = (float(power[1]), 0, 0)
                            else:
                                component_powers['DRAM'] = (component_powers['DRAM'][0] + float(power[1]), component_powers['DRAM'][1], component_powers['DRAM'][2])
                        else:
                            if component not in component_powers.keys():
                                component_powers[component] = (float(power[1]), 0, 0)
                            else:
                                component_powers[component] = (component_powers[component][0] + float(power[1]), component_powers[component][1], component_powers[component][2])
                if power[0][-1] == 'P':
                    component = power[0][8:-1]
                    if 'avg' in power[0]:
                        if component == 'CONST_DYNAMIC':
                            if 'CORE' not in component_powers.keys():
                                component_powers['CORE'] = (0, float(power[1]), 0)
                            else:
                                component_powers['CORE'] = (component_powers['CORE'][0], component_powers['CORE'][1] + float(power[1]), component_powers['CORE'][2])
                    elif 'max' in power[0]:
                        if component == 'CONST_DYNAMIC':
                            if 'CORE' not in component_powers.keys():
                                component_powers['CORE'] = (0, 0, float(power[1]))
                            else:
                                component_powers['CORE'] = (component_powers['CORE'][0], component_powers['CORE'][1], component_powers['CORE'][2] + float(power[1]))
                    elif 'min' in power[0]:
                        if component == 'CONST_DYNAMIC':
                            if 'CORE' not in component_powers.keys():
                                component_powers['CORE'] = (float(power[1]), 0, 0)
                            else:
                                component_powers['CORE'] = (component_powers['CORE'][0] + float(power[1]), component_powers['CORE'][1], component_powers['CORE'][2])
        for component in component_powers.keys():
            if component == 'DRAM':
                component_powers[component] = tuple(sorted([power / 12 for power in component_powers[component]]))
            elif component != 'L2C':
                component_powers[component] = tuple(sorted([power / 16 for power in component_powers[component]]))
        ptrace_values = {}
        for component in component_powers.keys():
            if component == 'DRAM':
                for i in range(1, 7):
                    ptrace_values['DRAM' + str(i)] = gen_rand(component_powers[component])
                    ptrace_values['MEM' + str(i)] = ptrace_values['DRAM' + str(i)]
            elif component == 'L2C':
                ptrace_values['L2CACHE'] = gen_rand(component_powers[component])
            elif component == 'IC':
                for i in range(1, 17):
                    ptrace_values['ICACHE' + str(i)] = gen_rand(component_powers[component])
            elif component == 'SCHED':
                for i in range(1, 17):
                    ptrace_values['WSCHED' + str(i)] = gen_rand(component_powers[component])
            elif component == 'RF':
                for i in range(1, 17):
                    ptrace_values['REGFILE' + str(i)] = gen_rand(component_powers[component])
            elif component == 'CORE':
                for i in range(1, 17):
                    ptrace_values['CORES' + str(i)] = gen_rand(component_powers[component])
            elif component == 'SFU':
                for i in range(1, 17):
                    ptrace_values['SFU' + str(i)] = gen_rand(component_powers[component])
            elif component == 'NOC':
                for i in range(1, 17):
                    ptrace_values['NETW' + str(i)] = gen_rand(component_powers[component])
            elif component == 'DC':
                for i in range(1, 17):
                    ptrace_values['L1CACHE' + str(i)] = gen_rand(component_powers[component])
            elif component == 'CC':
                for i in range(1, 17):
                    ptrace_values['CNSTCACHE' + str(i)] = gen_rand(component_powers[component])
        order = ['DRAM1', 'DRAM2', 'DRAM3', 'DRAM4', 'DRAM5', 'DRAM6',
                'L2CACHE', 'ICACHE1', 'ICACHE2', 'ICACHE3', 'ICACHE4', 'ICACHE5',
                'ICACHE6', 'ICACHE7', 'ICACHE8', 'ICACHE9', 'ICACHE10',
                'ICACHE11', 'ICACHE12', 'ICACHE13', 'ICACHE14', 'ICACHE15',
                'ICACHE16', 'WSCHED1', 'WSCHED2', 'WSCHED3', 'WSCHED4',
                'WSCHED5', 'WSCHED6', 'WSCHED7', 'WSCHED8', 'WSCHED9',
                'WSCHED10', 'WSCHED11', 'WSCHED12', 'WSCHED13', 'WSCHED14',
                'WSCHED15', 'WSCHED16', 'REGFILE1', 'REGFILE2', 'REGFILE3',
                'REGFILE4', 'REGFILE5', 'REGFILE6', 'REGFILE7', 'REGFILE8',
                'REGFILE9', 'REGFILE10', 'REGFILE11', 'REGFILE12', 'REGFILE13',
                'REGFILE14', 'REGFILE15', 'REGFILE16', 'CORES1', 'CORES2',
                'CORES3', 'CORES4', 'CORES5', 'CORES6', 'CORES7', 'CORES8',
                'CORES9', 'CORES10', 'CORES11', 'CORES12', 'CORES13', 'CORES14',
                'CORES15', 'CORES16', 'SFU1', 'SFU2', 'SFU3', 'SFU4', 'SFU5',
                'SFU6', 'SFU7', 'SFU8', 'SFU9', 'SFU10', 'SFU11', 'SFU12',
                'SFU13', 'SFU14', 'SFU15', 'SFU16', 'NETW1', 'NETW2', 'NETW3',
                'NETW4', 'NETW5', 'NETW6', 'NETW7', 'NETW8', 'NETW9', 'NETW10',
                'NETW11', 'NETW12', 'NETW13', 'NETW14', 'NETW15', 'NETW16',
                'L1CACHE1', 'L1CACHE2', 'L1CACHE3', 'L1CACHE4', 'L1CACHE5',
                'L1CACHE6', 'L1CACHE7', 'L1CACHE8', 'L1CACHE9', 'L1CACHE10',
                'L1CACHE11', 'L1CACHE12', 'L1CACHE13', 'L1CACHE14', 'L1CACHE15',
                'L1CACHE16', 'CNSTCACHE1', 'CNSTCACHE2', 'CNSTCACHE3',
                'CNSTCACHE4', 'CNSTCACHE5', 'CNSTCACHE6', 'CNSTCACHE7',
                'CNSTCACHE8', 'CNSTCACHE9', 'CNSTCACHE10', 'CNSTCACHE11',
                'CNSTCACHE12', 'CNSTCACHE13', 'CNSTCACHE14', 'CNSTCACHE15',
                'CNSTCACHE16']
        if FLOORPLAN_FORMAT_CLONE:
            for i in range(1, 7):
                ptrace_values['MEM' + str(i)] = ptrace_values['DRAM' + str(i)]
            ptrace_values['L2C'] = ptrace_values['L2CACHE']
            for i in range(1, 17):
                ptrace_values['SM' + str(i)] = [round(ptrace_values['ICACHE' + str(i)][j] + 
                        ptrace_values['WSCHED' + str(i)][j] +
                        ptrace_values['REGFILE' + str(i)][j] + 
                        ptrace_values['CORES' + str(i)][j] + 
                        ptrace_values['SFU' + str(i)][j] + 
                        ptrace_values['NETW' + str(i)][j] +
                        ptrace_values['L1CACHE' + str(i)][j] +
                        ptrace_values['CNSTCACHE' + str(i)][j], 4) for j in range(0, 5)]
            order += ['MEM1', 'MEM2', 'MEM3', 'MEM4', 'MEM5', 'MEM6',
                    'L2C', 'SM1', 'SM2', 'SM3', 'SM4', 'SM5', 'SM6', 'SM7', 'SM8',
                    'SM9', 'SM10', 'SM11', 'SM12', 'SM13', 'SM14', 'SM15', 'SM16']
        else:
            ptrace_values['PLACEHLDR'] = [0] * 5
            order = ['MEM' + str(i) for i in range(1, 7)] + ['PLACEHLDR'] + order
        ptrace_values = {key: ptrace_values[key] for key in order}
        with open(PTRACE_FILENAME, 'w') as ptrace:
            ptrace.writelines(['\t'.join(order[:-1]) + '\t' + order[-1] + '\n'])
            for i in range(0, 5):
                line = ''
                for key in order[:-1]:
                    line += (str(ptrace_values[key][i]) + '\t')
                line += ('\t' + str(ptrace_values[order[-1]][i]) + '\n')
                ptrace.writelines([line])

if __name__ == '__main__':
    main()
