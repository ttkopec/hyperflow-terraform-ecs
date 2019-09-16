import json
import os

from influxdb import DataFrameClient
from jinja2 import Environment, FileSystemLoader
from pandas import DataFrame

'''
CPU value	Memory value (MiB)
256 (.25 vCPU)	512 (0.5 GB), 1024 (1 GB), 2048 (2 GB)
512 (.5 vCPU)	1024 (1 GB), 2048 (2 GB), 3072 (3 GB), 4096 (4 GB)
1024 (1 vCPU)	2048 (2 GB), 3072 (3 GB), 4096 (4 GB), 5120 (5 GB), 6144 (6 GB), 7168 (7 GB), 8192 (8 GB)
2048 (2 vCPU)	Between 4096 (4 GB) and 16384 (16 GB) in increments of 1024 (1 GB)
4096 (4 vCPU)	Between 8192 (8 GB) and 30720 (30 GB) in increments of 1024 (1 GB)

ref: https://docs.aws.amazon.com/AmazonECS/latest/userguide/task_definition_parameters.html#task_size
'''

# list of 3 element tuples with all possible variants of hardware configurations:
# (cpu_value, mem_value, weight_of_configuration)
DEFAULT_TASK_CONFIGS = [
    ('256', '512', 10),
    # ('256', '1024', 10),
    # ('256', '2048', 10),

    ('512', '1024', 20),
    # ('512', '2048', 20),
    # ('512', '3072', 20),
    # ('512', '4096', 20),

    ('1024', '2048', 40),
    # ('1024', '3072'),
    # ('1024', '4096'),
    # ('1024', '5120'),
    # ('1024', '6144'),
    # ('1024', '7168'),
    # ('1024', '8192'),

    # ('2048', '4096'),
    # ('2048', '5120'),
    # ('2048', '6144'),
    # ('2048', '7168'),
    # ('2048', '8192'),

    # ('4096', '8192')
]

DEFAULT_TASK_CONFIGS = {'_'.join(['var', *conf[:2]]): conf for conf in DEFAULT_TASK_CONFIGS}
_costs = [config[2] for config in DEFAULT_TASK_CONFIGS.values()]
COST_MAX, COST_MIN = max(_costs), min(_costs)


def load_templates(directory):
    return Environment(
        loader=FileSystemLoader(directory)
    )


def load_tasks(workflow_filepath):
    with open(workflow_filepath, 'r') as fp:
        workflow = json.load(fp)

    return {
        task['config']['executor']['executable']
        for task in workflow.get('tasks', workflow.get('processes', []))
        if 'name' in task
    }


def save(strings, filepath, directory='.'):
    if not os.path.isdir(directory):
        os.mkdir(directory)

    with open(os.path.join(directory, filepath), 'w') as fp:
        strings = '\n'.join(strings) if isinstance(strings, list) else strings

        fp.write(strings)


def request_influx(influx, task_name, config_list):
    config_list = ["'{}'".format(config) for config in config_list]
    query = 'SELECT "start", "end", "taskID", "configId", "download_start", "download_end", "upload_start", ' \
            '"upload_end", "execute_start", "execute_end" ' \
            'FROM "hflow_task" ' \
            'WHERE "taskID" = \'{}\' ' \
            'AND ("configId" = {}) ' \
            'AND "experiment" =~ /2019-05-26/'.format(task_name, ' OR "configId" = '.join(config_list))

    try:
        return influx.query(query)['hflow_task']
    except KeyError:
        print(f'No data for task {task_name}')
        return DataFrame()


def calculate_time_cost_tradeoff(time, time_min, time_max, cost, cost_min, cost_max):
    return 0.7 * (time - time_min) / (time_max - time_min) + \
           0.3 * (cost - cost_min) / (cost_max - cost_min)


def get_best_config(df, default='var_256_512'):
    if df.empty:
        return default
    else:
        df['exec_time'] = (df.end - df.start) / 1000
        time = df['exec_time']

        time_max, time_min = time.max(), time.min()

        for i, row in df.iterrows():
            df.loc[i, 'time_cost'] = calculate_time_cost_tradeoff(row['exec_time'],
                                                                  time_min,
                                                                  time_max,
                                                                  DEFAULT_TASK_CONFIGS[row['configId']][2],
                                                                  COST_MIN,
                                                                  COST_MAX)

        print(df.sort_values('time_cost'))

        return df.sort_values('time_cost').iloc[0].configId


def gen_test(templates_dir, task_configs, out_tasks_filepath):
    """
    Generates for test run:
    1. ecs task definitions
    2. hyperflow configs using generated task definitions
    """
    env = load_templates(templates_dir)

    print('Generating tasks')
    task_tmpl = env.get_template('hflow_worker.j2')
    config_tmpl = env.get_template('awsFargateCommand.config.j2')

    task_defs = []
    configs = []

    for name, conf in task_configs.items():
        cpu, mem, weight = conf
        task_defs.append(task_tmpl.render(NAME=name, CPU=cpu, MEMORY=mem))
        configs.append(name)

    print(f'Saving {len(task_defs)} task defs to {out_tasks_filepath}')
    save(task_defs, out_tasks_filepath)

    print(f'Saving {len(configs)} hyperflow configs')

    for config_name in configs:
        # config_name is name of a task def
        save(config_tmpl.render(TASKS_MAPPING={}, CONFIG_ID=config_name, DEFAULT_TASK=config_name),
             f'awsFargateCommand_{config_name}.config.js',
             'hyperflow_configs')

    save(configs, 'config_list.txt', 'hyperflow_configs')


def gen_prod(templates_dir, workflow_filepath, config_list, out_tasks_filepath, database, url):
    """
    1. fetch data from influx related to test run
    2. choose best configuration for each task basing on influx data
    3. generate task definition for each workflow task
    4. generate one hyperflow config
    """
    influx = DataFrameClient(database=database, host=url)
    env = load_templates(templates_dir)
    tasks = load_tasks(workflow_filepath)

    print('Generating hyperflow config')
    task_tmpl = env.get_template('hflow_worker.j2')

    task_defs = []
    task_name_to_task_def = {}

    for task_name in tasks:
        print(f'Analyzing task {task_name}')

        # request influx for data regarding task exec time
        df = request_influx(influx, task_name, config_list)

        # calculate best config, for example: var_256_512
        config = get_best_config(df)

        # extract cpu and mem from config code
        cpu, mem = config.split('_')[1:]
        config_name = '_'.join([task_name.replace('.', '_'), cpu, mem])

        task_defs.append(task_tmpl.render(NAME=config_name, CPU=cpu, MEMORY=mem))
        task_name_to_task_def[task_name] = config_name

    print(f'Saving {len(task_defs)} tasks to {out_tasks_filepath}')
    save(task_defs, out_tasks_filepath)

    config = env.get_template('awsFargateCommand.config.j2').render(CONFIG_ID='prod',
                                                                    TASKS_MAPPING=task_name_to_task_def,
                                                                    DEFAULT_TASK='string')

    print('Saving production ready hyperflow config')
    save(config, 'awsFargateCommand.config.js', 'hyperflow_configs')


if __name__ == '__main__':
    # todo use argparse

    gen_test('tasks_templates', DEFAULT_TASK_CONFIGS, 'tasks.tf')

    # gen_prod('tasks_templates', 'workflow.json', ['var_256_512', 'var_512_1024', 'var_1024_2048'], 'tasks_prod.tf',
    #          'hyperflow-database', '172.18.0.4')
