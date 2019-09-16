# HyperFlow deployment on Amazon ECS

This project contains infrastructure configuration files for deployment of HyperFlow and workflows on Amazon ECS/EC2 + Docker with autoscaling. The files are as follows:
 
- main.tf - main entry file with cluster definition
- security.tf - definition of security groups
- vpc.tf - definitions of isolated VPC
- iam.tf - IAM roles and policies
- log.tf - CloudWatch settings
- services.tf - definitions of services running independently from performed computations 
- variables.tf - definitions of variables that should be changed by user according to their needs

## User Variables
The most important variables from the user perspective are defined in the variables.tf file

- region - AWS region
- zone - AWS zone
- hflow_image_uri - URI identifying HyperFlow worker container. Worker container should be build according to 
  [hyperflow-awsfargate-executor](https://github.com/ttkopec/hyperflow-awsfargate-executor/tree/feature/monitoring-setup) 
  project. 
- influx_image_uri - URI identifying InfluxDB container
- grafana_image_uri - URI identifying Grafana container, can be either ECR or official DockerHub URI, 
  default: **grafana/grafana:6.1.6**

## Overview
In order to setup ECS Fargate cluster, user must:

1. Generate `task.tf` file containing definitions of tasks with different hardware specifications. File 
   [generate_tasks.py](generate_tasks.py) contains `gen_test` and `gen_prod` functions, which serve this purpose (for 
   more info regarding usage of those functions, please refer to their docstrings). 
   * Edit `generate_tasks.py`:
       ```python
        if __name__ == '__main__':
           gen_test('tasks_templates', DEFAULT_TASK_CONFIGS, 'tasks.tf')
       ```      
    * Run script:
        ```bash
        python3 generate_tasks.py
        ```
   Output should consist of:
   * `task.tf` - Terraform file used for task creation
   * `hyperflow_configs` - directory with `.config.js` files used by 
   [HyperFlow](https://github.com/hyperflow-wms/hyperflow)
   
2. Run command
    ```bash
    terraform apply
    ```
   to generate all necessary AWS resources.
   
3. Run `hyperflow` workflow according to [guide](https://github.com/hyperflow-wms/hyperflow).
4. Teardown architecture
    ```bash
    terraform destroy
    ```
 
 **Note**
 <br/>
 `gen_test` function should be used in order to create configuration files used during test run, which aims to find best 
 possible and most cost efficient configurations for execution of a workflow.
 <br/>
 `gen_prod` function should be used after execution of test run. It uses data generated during test run and stored 
 inside **InfludDB** by worker containers. Purpose of `prod` run is to choose best configuration for each task basing on 
 gathered **InfluxDB** data and generate `task_prod.tf` Terraform file and exactly one `.config.js` file, which can be 
 later used by [HyperFlow](https://github.com/hyperflow-wms/hyperflow) during optimal workflow execution. 