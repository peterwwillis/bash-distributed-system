simple distributed system


communication medium
 - Description: allow communication between different components

 - Implementation type:
   - REST Server
     - Nginx web server
     - busybox httpd?
       - busybox httpd -p 8080 -f -v -h /tmp/http-dir
       - CGI script:
         - printf "Content-Type: text/plain\n\n"
       - curl http://localhost:8080/cgi-bin/some-script

 - Supported operations:
   - Pass a request to a CGI script
     - Ex:
       - GET /processor/jobs/status
       - GET /processor/jobs/<job number>/status
       - POST /processor/jobs/new
   - Upload a file and pass that file and some arguments to a CGI script
     - Ex:
       - POST /processor/jobs/new

job processor
 - Description: Perform tasks and record their status.
                A job processor has to be able to accept jobs, record their status,
                and report it when queried.
                We will support our own TCP service that can act as a job processor,
                or we will supply an API wrapper around a SaaS like AWS ECS so that
                when we call our API wrapper it responds like our own TCP service.
                This way we can run jobs on a Linux box or on a SaaS provider.

 - Implementation type:
   - Shell script

 - Supported operations:
   - Create a new job
     - POST /processor/job/new
       - local node type:
         - input data: '{
             "commands": [ { "exec": [ "curl", "https://www.google.com/" ] } ] ,
             "environment": {} ,
             "request_id": "123456789"
           }'
         - scheduler request ID
   - Record the status of a job
     - local node type:
       - POST /processor/job/$request_id/status
       - echo "status" > state/processor/job/$request_id/status
   - Return the status of a job
     - local node type:
       - GET /processor/job/$request_id/statu
       - cat state/processor/job/$request_id/status
   - Record output log of a job to a file
     - local node type:
       - $command $arguments > state/processor/job/$request_id/log 2>&1

job scheduler
 - Description: Execute a job processor task
 - Supported operations:
   - List nodes you can run a job on
   - Place a job on a node
   - Add a job to a scheduler queue
   - Check if a job is still valid in a scheduler queue
   - Remove a job from a scheduler queue
     - If timed out
     - If completed
     - If failed
     - If re-executed too many times

node
 - Description: A TCP host:port with a job processor listening on it,
                OR a SaaS service that we have a wrapper for that we
                can treat as a job processor.

dag
 - Description: just a job that calls other jobs.
                each job should keep track of what its dependent jobs are, and
                what job called it.
                the job should keep state that other jobs can query, so that
                you can walk all the jobs in real time to discover the full
                dag.

---


SAMPLE OPERATION SCRIPT:

 - First, a user requests a new job be placed
   - POST /scheduler/jobs/new
     - Post data: '{"commands": [ "command": [ "curl", "https://www.google.com/" ] ] }'
     - Post data: 'command=curl "https://www.google.com/"'
     - The new job request is added to the incoming stack in the scheduler.

 - The scheduler adds a request to its incoming stack
   - receives post data from above
   - adds job to internal state incoming stack
     - scheduler.sh new job
       - make new request id 123456789
       - echo "$request_data" > state/incoming/123456789.job
   - Returned data: '{"request_id": "123456789"}'

 - In the background, the scheduler polls for new requests to schedule
    - scheduler locks internal state (for incoming stack table)
    - scheduler lists internal state for incoming stack request IDs

    - for each incoming request ID,
      - scheduler finds a node to place the job on
        - GET /scheduler/nodes/available
          - This will probably need some filter parameters in the future.
            Maybe send it the job request so it can filter the nodes based on it.
        - Use an internal function to map an internal node identifier to an external node identifier and metadata
          - If cloud:
            - If ec2: Use AWS API to find an ec2 node to run job on
            - If ecs: Use AWS API to find a cluster to run job on
          - If local:
            - It's localhost; we have a configuration block with the service configuration
        - Returned data: '{"nodes": 
              [ "name": "node01", "ipv4": [ "192.168.0.1" ], "hostname": "node01.internal", "uri": "http://node01.internal:5678" ] ,
              [ "name": "localhost", "ipv4": [ "127.0.0.1" ], "hostname": "localhost", "uri": "http://localhost:5678" ]
          }' 

      - Scheduler starts the job on the node
        - scheduler uses some credentials to send a request to the node to start the job
          - If cloud:
            - If ecs: send API request (using AWS credentials) to start a job on the cluster.
                      record whatever response we get back so we can find the running job id.
          - If local:
            - Run the process in the background.
          - use whatever API of the backend node thing to send the request
        - scheduler records information about the job into state
          - records the job that was placed at X time on Y node with Z reference data about the backend
          - records that the placement was successful
      - Returned data: '/scheduler/jobs/2'

 - In the background, the scheduler polls all running jobs for updates

   - GET /scheduler/jobs
     - Scheduler looks at its internal state for jobs that were registered
       (this probably will need lots of different filters; currently running? dead?)
     - Returned data: '2'

   - POST /scheduler/jobs/2/update
     - Update the job
       - GET /scheduler/jobs/2/status
         - Queries node for job state
           - If cloud infra, queries API of SaaS for job state
           - If linux box, checks for a process running
         - Return data based on job status
           - If the job has stopped, mark state as 'stopped'
           - If the job is still running, mark state as 'running'
           - If the job did not exit with an error, mark status as 'good'
           - If the job exited with an error, mark status as 'error'
           - Returned data: '{"state": "running", "status": "unknown", "node": "node-01", "created-at": "Some Timestamp"}'
       - If the timeout has triggered, kill the job
         - POST /scheduler/jobs/2/kill

 - The user requests the status of jobs
 
   - GET /scheduler/jobs
     - Returned data: '2'
   - GET /scheduler/jobs/2/status
     - Returned data: '{"state": "stopped", "status": "good", "node": "node-01", "created-at": "Some Timestamp"}'


