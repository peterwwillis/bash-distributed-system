# shell distributed system

## About
The Shell Distributed System is a distributed system implemented as shell
scripts (and some extra unix tools). The purpose of the system is to demonstrate
how a distributed system works. It can also be used for general purpose
computing tasks when a more complex system would be overkill or take too long to
adapt.

---

# Design Components

## Communication Medium

### Description
 - Defines the method for different components to communicate between each
   other, and with users.

### Implementation type
- REST Server implementing CGI standard
  - busybox httpd
    - busybox httpd -p 8080 -f -v -h /tmp/http-dir
- HTTP client that makes requests/posts data

### Supported operations
1. Pass a request to a CGI script
  - Ex:
    - GET /processor/jobs/status
    - GET /processor/jobs/${JOB_NUMBER}/status
    - POST /processor/jobs/new
2. Upload a file and pass that file and some arguments to a CGI script
  - Ex:
    - POST /processor/jobs/new
    - curl -X POST -d '@some-file.json' http://localhost:8080/cgi-bin/processor/jobs/new


## Job Processor

### Description
- Perform tasks and record their status.
  A job processor has to be able to accept jobs, record their status,
  and report it when queried.
  A job processor implements whatever the mechanism is for executing
  a job - be it locally, or remotely (say, by SaaS).

### Implementation type:
- Shell script

### Supported operations:
1. Create a new job
  - POST /processor/job/new
    - local node type:
      - input data: '{
          "commands": [ { "exec": [ "curl", "https://www.google.com/" ] } ] ,
          "environment": {} ,
          "request_id": "123456789"
        }'
      - scheduler request ID
2. Record the status of a job
  - local node type:
    - POST /processor/job/$request_id/status
    - echo "status" > state/processor/job/$request_id/status
3. Return the status of a job
  - local node type:
    - GET /processor/job/$request_id/statu
    - cat state/processor/job/$request_id/status
4. Record output log of a job to a file
  - local node type:
    - $command $arguments > state/processor/job/$request_id/log 2>&1


## Job Scheduler

### Description
 - Execute a job processor task

### Supported operations
1. List nodes you can run a job on
2. Place a job on a node
3. Add a job to a scheduler queue
4. Check if a job is still valid in a scheduler queue
5. Remove a job from a scheduler queue
  - If timed out
  - If completed
  - If failed
  - If re-executed too many times


## Node

### Description
- A TCP host:port with a job processor listening on it,
  OR a SaaS service that we have a wrapper for that we
  can treat as a job processor.

### Supported operations
1. List jobs on the node
2. Run a job
3. Return job status
4. Kill a job


## DAG

### Description
- Just a job that calls other jobs.
  Each job should keep track of what its dependent jobs are, and
  what job called it.
  The job should keep state that other jobs can query, so that
  you can walk all the jobs in real time to discover the full
  dag.


---


## Sample Operation Script

### tl;dr
1. Submit new job to REST API
2. Backend schedules job in queue
3. Scheduler polls queue, finds job, executes
4. User requests status from scheduler
5. Scheduler returns job status

### Walkthrough

#### 1. Submit new job to scheduler REST API
- First, a user requests a new job be placed
  - POST /scheduler/jobs/new
    - Post data: '{"action": "add_job", "command": [ "curl", "https://www.google.com/" ] }'
    - The new job request is added to the job queue in the scheduler.

#### 2. Backend schedules job in queue
- The scheduler backend adds a request to its job queue
  - receives post data from above
  - adds job to internal state job queue stack
    - scheduler.sh new job
      - make new request id 123456789, add to $request_data_json
      - echo "$request_data_json" > state/scheduler/queue/123456789.job
  - Returned data: '$request_data_json'

#### 3. Scheduler polls queue, finds job, adds to node
- In the background, the scheduler polls for new requests to schedule
   - Scheduler locks internal state (for job queue table)
   - Scheduler lists internal state for job queue request IDs
   - For each job queue request ID:
     - Scheduler finds a node to place the job on
       - `GET /scheduler/nodes/list`
         - This will probably need some filter parameters in the future.
           Maybe send it the job request so it can filter the nodes based on it.
       - Returned data: 
         ```
         { "nodes": [
             { "name": "node01", "ipv4": [ "192.168.0.1" ], "hostname": "node01.internal", "uri": "http://node01.internal:5678" } ,
             { "name": "localhost", "ipv4": [ "127.0.0.1" ], "hostname": "localhost", "uri": "http://localhost:5678" }
           ]
         }
         ```
     - Scheduler starts the job on the node
       - Scheduler uses some credentials to send a request to the node to start the job
         - `POST /nodemgr/jobs/run?job-number=2&json_data=$json_data`
         - Returned data:
           ```
           { "nodejobs": [
               { "nodejob-idx": "123456789", "schedulerjob-idx": "2", "hostname": "node01.internal", "ipv4": [ "192.168.20.22" ] }
             ]
           }
           ```
       - Scheduler records information about the node job into state
         - records the job that was placed at X time on Y node with Z reference data about the backend
         - records that the placement was successful
     - Returned data: '/scheduler/jobs/2'

#### 4. Node runs the job
   - Use an internal function to map an internal node identifier to an external node identifier and metadata
     - If cloud:
       - If ec2: Use AWS API to find an ec2 node to run job on
       - If ecs: Use AWS API to find a cluster to run job on
     - If local:
       - It's localhost; we have a configuration block with the service configuration
   - Credentials dictate actions
     - If cloud:
       - If ecs: send API request (using AWS credentials) to start a job on the cluster.
                 record whatever response we get back so we can find the running job id.
     - If local:
       - Run the process in the background.
     - use whatever API of the backend node thing to send the request

#### 5. User requests status from scheduler
- The user requests the status of jobs
  - GET /scheduler/jobs
    - Returned data: '2'
  - GET /scheduler/jobs/2/status
    - Returned data: '{"state": "stopped", "status": "good", "node": "node-01", "created-at": "Some Timestamp"}'

#### 6. Scheduler returns job status
- Scheduler receives job status request
- In the background, the scheduler polls all running jobs for updates
  - GET /scheduler/jobs
    - Scheduler looks at its internal state for jobs that were registered
      (this probably will need lots of different filters; currently running? dead?)
    - Returned data: '2'
  - GET /scheduler/jobs/2/status
    - Queries node for job state
      - GET /node/
      - If cloud infra, queries API of SaaS for job state
      - If linux box, checks for a process running
    - Return data based on job status
      - If the job has stopped, mark state as 'stopped'
      - If the job is still running, mark state as 'running'
      - If the job did not exit with an error, mark status as 'good'
      - If the job exited with an error, mark status as 'error'
      - Returned data: '{"state": "running", "status": "unknown", "node": "node-01", "created-at": "Some Timestamp"}'
  - Update the job based on status
    - If the timeout has triggered, kill the job
      - POST /scheduler/jobs/2/update?kill=1
    - Otherwise, just post the current status
      - POST /scheduler/jobs/2/update

