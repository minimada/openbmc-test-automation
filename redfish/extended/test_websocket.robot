*** Settings ***

Documentation  Websocket functionality test.

# Test Parameters:
# OPENBMC_HOST       The BMC host name or IP address.
# OPENBMC_USERNAME   The username for the BMC login.
# OPENBMC_PASSWORD   The password for OPENBMC_USERNAME.
# OS_HOST            The OS host name or IP address.
# OS_USERNAME        The username for the OS login.
# OS_PASSWORD        The password for OS_USERNAME.

Resource             ../../lib/esel_utils.robot
Resource             ../../lib/bmc_redfish_resource.robot
Resource             ../../lib/logging_utils.robot
Resource             ../../lib/dump_utils.robot
Resource             ../../syslib/utils_os.robot
Library              ../../lib/gen_cmd.py
Library              OperatingSystem


Suite Setup          Suite Setup Execution
Suite Teardown       Suite Teardown Execution
Test Teardown        Test Teardown Execution


*** Variables ***

${monitor_pgm}          websocket_monitor.py
${monitor_file}         websocket_monitor_out.txt
${esel_received}        eSEL received over websocket interface
${dump_received}        Dump notification received over websocket interface
${min_number_chars}     22
${monitor_cmd}          python3 bin/${monitor_pgm} ${OPENBMC_HOST} --openbmc_username ${OPENBMC_USERNAME}


*** Test Cases ***


Test BMC Websocket ESEL Interface
    [Documentation]  Verify eSELs are reported over the websocket interface.
    [Tags]  Test_BMC_Websocket_ESEL_Interface

    # Check that the ipmitool is available. That tool is used to create an eSEL.
    Tool Exist  ipmitool

    # Spawn the websocket monitor program and then generate an eSEL.
    # The monitor should asynchronously receive the eSEL through the
    # websocket interface and report this fact to standard output.

    Start Websocket Monitor  logging

    ${initial_esel_count}=  Get Number Of Event Logs

    # Generate eSEL (e.g.  typically "CPU 1 core 3 has failed").
    Create eSEL

    ${current_esel_count}=   Get Number Of Event Logs

    Run Keyword If  ${initial_esel_count} == ${current_esel_count}
    ...  Fail  msg=System failed to generate eSEL upon request.

    ${line}=  Grep File  ${monitor_file}  ${esel_received}
    # Typical monitor_file contents:
    # --------------- ON_MESSAGE:begin --------------------
    # {"event":"PropertiesChanged","interface":"xyz.openbmc_project.Logging.
    # Entry","path":"/xyz/openbmc_project/logging/entry/5","properties":{"Id":5}}
    # eSEL received over websocket interface.

    ${num_chars}=  Get Length  ${line}
    Run Keyword If  ${num_chars} < ${min_number_chars}  Fail
    ...  msg=No eSEL notification from websocket_monitor.py.


Test BMC Websocket Dump Interface
    [Documentation]  Verify dumps are reported over the websocket interface.
    [Tags]  Test_BMC_Websocket_Dump_Interface

    Redfish Delete All BMC Dumps

    Start Websocket Monitor  dump/bmc
    ${dump_id}=  Create User Initiated BMC Dump
    Check Existence Of BMC Dump File  ${dump_id}

    # Check that the monitor received notification of the dump.
    ${line}=  Grep File  ${monitor_file}  ${dump_received}
    # Typical monitor_file contents:
    # --------------- ON_MESSAGE:begin --------------------
    # {"event":"PropertiesChanged","interface":"xyz.openbmc_project.Dump.
    # Entry","path":"/xyz/openbmc_project/dump/entry/1","properties":{"Size":157888}}
    # Dump notification received over websocket interface.

    ${num_chars}=  Get Length  ${line}
    Run Keyword If  ${num_chars} < ${min_number_chars}  Fail
    ...  msg=No dump notification from websocket_monitor.py.


*** Keywords ***


Create User Initiated BMC Dump
    [Documentation]  Generate user initiated BMC dump and return the dump id number (e.g., "5").

    ${payload}=  Create Dictionary  DiagnosticDataType=Manager
    ${resp}=  Redfish.Post  /redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData
    ...  body=${payload}  valid_status_codes=[${HTTP_ACCEPTED}, ${HTTP_OK}]

    # Example of response from above Redfish POST request.
    # "@odata.id": "/redfish/v1/TaskService/Tasks/0",
    # "@odata.type": "#Task.v1_4_3.Task",
    # "Id": "0",
    # "TaskState": "Running",
    # "TaskStatus": "OK"

    Wait Until Keyword Succeeds  5 min  15 sec  Is Task Completed  ${resp.dict['Id']}
    ${task_id}=  Set Variable  ${resp.dict['Id']}

    ${task_dict}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}

    # Example of HttpHeaders field of task details.
    # "Payload": {
    #   "HttpHeaders": [
    #     "Host: <BMC_IP>",
    #      "Accept-Encoding: identity",
    #      "Connection: Keep-Alive",
    #      "Accept: */*",
    #      "Content-Length: 33",
    #      "Location: /redfish/v1/Managers/bmc/LogServices/Dump/Entries/2"]
    #    ],
    #    "HttpOperation": "POST",
    #    "JsonBody": "{\"DiagnosticDataType\":\"Manager\"}",
    #     "TargetUri": "/redfish/v1/Managers/bmc/LogServices/Dump/Actions/LogService.CollectDiagnosticData"
    # }

    [Return]  ${task_dict["Payload"]["HttpHeaders"][-1].split("/")[-1]}


Is Task Completed
    [Documentation]  Verify if the given task is completed.
    [Arguments]   ${task_id}

    # Description of argument(s):
    # task_id        Id of task which needs to be checked.

    ${task_dict}=  Redfish.Get Properties  /redfish/v1/TaskService/Tasks/${task_id}
    Should Be Equal As Strings  ${task_dict['TaskState']}  Completed


Start Websocket Monitor
    [Documentation]  Fork the monitor to run in the background.
    [Arguments]  ${monitor_type}

    # Description of Argument(s):
    # monitor_type  The type of websocket notifications to monitor,
    #               either "logging" or "dump".

    # Delete the previous output file, if any.
    Remove File  ${monitor_file}

    ${command}=  Catenate  ${monitor_cmd} --openbmc_password ${OPENBMC_PASSWORD}
    ...   --monitor_type ${monitor_type} 1>${monitor_file} 2>&1

    # Start the monitor. Fork so its a parallel task.
    Shell Cmd  ${command}  fork=${1}

    # Allow time for the monitor to initialize.
    Sleep  5s


Find Websocket Monitor
    [Documentation]  Return the process Id(s) of running websocket monitors.

    ${cmd}=  Catenate  ps -ef | grep '${monitor_cmd}'
    ...  | grep -v grep | grep -v bash | cut -c10-14
    ${shell_rc}  ${pid}=  Shell Cmd  ${cmd}
    # There may be more than one pid returned if there is an instance
    # of a monitory_pgm running from a previous run.
    @{pid_list}=  Split String  ${pid}
    [Return]  ${pid_list}


Kill Websocket Monitor
    [Documentation]  Terminate running websocket monitor.

    ${pid_list}=  Find Websocket Monitor
    FOR  ${pid}  IN  @{pid_list}
        Shell Cmd  kill -s SIGTERM ${pid}
    END


Print Websocket Monitor Log
    [Documentation]  Show the contents of the monitor output file.

    ${websocket_monitor_log}=  OperatingSystem.Get File  ${monitor_file}
    Log to Console  websocket_monitor_log:
    Log to Console  ${websocket_monitor_log}


Suite Setup Execution
    [Documentation]  Do the suite setup tasks.

    Redfish.Login
    Run Keyword  Redfish Power On  stack_mode=skip


    Delete All Error Logs
    Kill Websocket Monitor

    # Allow time for Error Logs to be deleted.
    Sleep  5s


Test Teardown Execution
    [Documentation]  Do teardown tasks after a test.

    FFDC On Test Case Fail
    Run Keyword If  '${TEST_STATUS}' == 'FAIL'  Print Websocket Monitor Log
    Kill Websocket Monitor

    Redfish Delete All BMC Dumps


Suite Teardown Execution
    [Documentation]  Do the post-suite teardown.

    Delete All Error Logs
    Run Keyword and Return Status  Redfish.Logout
