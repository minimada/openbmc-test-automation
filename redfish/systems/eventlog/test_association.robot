*** Settings ***
Documentation       REST test Error callout association.

Resource            ../../../lib/bmc_redfish_resource.robot
Resource            ../../../lib/bmc_redfish_utils.robot
Resource            ../../../lib/connection_client.robot
Resource            ../../../lib/openbmc_ffdc.robot
Resource            ../../../lib/utils.robot
Resource            ../../../lib/state_manager.robot
Resource            ../../../lib/boot_utils.robot


Suite Setup         Suite Setup Execution
Suite Teardown      Suite Teardown Execution
Test Setup          Test Setup Execution
Test Teardown       FFDC On Test Case Fail

***Variables***
#${target_device_path}  /sys/devices/device
${target_device_path}  /sys/devices/platform/ahb/ahb:apb/f0082000.i2c/i2c-2/2-0058
${POWERSUPPLY0_INVENTORY_URI}  ${MOTHERBOARD_INVENTORY_URI}powersupply0
${PERSIST_INVENTORY_PATH}  /var/lib/phosphor-inventory-manager

${stack_mode}          skip

*** Test Cases ***

Create Test Error Callout And Verify
    [Documentation]  Create error log callout and verify via REST.
    [Tags]  Create_Test_Error_Callout_And_Verify

    Create Test Error With Callout
    Verify Test Error Log And Callout


Create Test Error Callout And Verify AdditionalData
    [Documentation]  Create Test Error Callout And Verify AdditionalData.
    [Tags]  Create_Test_Error_Callout_And_Verify_AdditionalData

    # Test error log entry example:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ]

    Create Test Error With Callout
    ${elog_entry}=  Get Elog URL List
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    ${jsondata}=  To JSON  ${resp.content}
    List Should Contain Value
    ...  ${jsondata["data"]["AdditionalData"]}  CALLOUT_DEVICE_PATH_TEST=${target_device_path}
    List Should Contain Value  ${jsondata["data"]["AdditionalData"]}  DEV_ADDR=0x0DEADEAD


Create Test Error Callout And Verify Associations
    [Documentation]  Create test error callout and verify associations.
    [Tags]  Create_Test_Error_Callout_And_Verify_Associations

    # Test error log association entry example:
    # "associations": [
    #   [
    #        "callout",
    #        "fault",
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #   ]
    # ]

    Create Test Error With Callout
    ${elog_entry}=  Get Elog URL List
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    ${jsondata}=  To JSON  ${resp.content}
    List Should Contain Value  ${jsondata["data"]["Associations"][0]}  callout
    List Should Contain Value  ${jsondata["data"]["Associations"][0]}  fault
    List Should Contain Value
    ...  ${jsondata["data"]["Associations"][0]}
    ...  ${POWERSUPPLY0_INVENTORY_URI}
    #...  /xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0


Create Test Error Callout And Delete
    [Documentation]  Create Test Error Callout And Delete.
    [Tags]  Create_Test_Error_Callout_And_Delete

    # Test error log entry example:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ],
    #    "Id": 1,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.TestCallout",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1487747332528,
    #    "associations": [
    #        [
    #          "callout",
    #          "fault",
    #          "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/1/callout": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #    ]
    # },

    Create Test Error With Callout
    ${elog_entry}=  Get Elog URL List
    Delete Error Log Entry  ${elog_entry[0]}
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}/callout
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Create Two Test Error Callout And Delete
    [Documentation]  Create Two Test Error Callout And Delete.
    [Tags]  Create_Two_Test_Error_Callout_And_Delete

    # Test error log entry example:
    #  "/xyz/openbmc_project/logging/entry/1": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ],
    #    "Id": 1,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.TestCallout",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1487747332528,
    #    "associations": [
    #        [
    #          "callout",
    #          "fault",
    #          "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/1/callout": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/2": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ],
    #    "Id": 2,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.TestCallout",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1487747332528,
    #    "associations": [
    #        [
    #          "callout",
    #          "fault",
    #          "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/2/callout": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #    ]
    # },

    # Create two error logs.
    Create Test Error With Callout
    Create Test Error With Callout

    # Delete entry/2 elog entry.
    ${elog_entry}=  Get Elog URL List
    Delete Error Log Entry  ${elog_entry[1]}

    # Verify if entry/1 exist and entry/2 is deleted.
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}
    ${resp}=  OpenBMC Get Request  ${elog_entry[1]}
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}


Create Test Error Callout And Verify LED
    [Documentation]  Create an error log callout and verify respective
    ...  LED state.
    [Tags]  Create_Test_Error_Callout_And_Verify_LED

    Create Test Error With Callout

    ${resp}=  Get LED State XYZ  cpu0_fault
    Should Be Equal  ${resp}  ${1}


Set Resolved Field And Verify Callout Deletion
    [Documentation]  Set the "Resolved" error log and verify callout is deleted
    [Tags]  Set_Resolved_Field_And_Verify_Callout_Deletion

    Delete All Error Logs
    Create Test Error With Callout
    ${elog_entry}=  Get URL List  ${BMC_LOGGING_ENTRY}
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    ${jsondata}=  To JSON  ${resp.content}
    Should Contain  ${jsondata["data"]["Associations"][0]}  callout

    # Set the error log field "Resolved".
    # By doing so, the callout object should get deleted automatically.
    ${valueDict}=  Create Dictionary  data=${1}
    OpenBMC Put Request  ${elog_entry[0]}/attr/Resolved  data=${valueDict}

    # Verify if the callout entry is deleted.
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}/callout
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_NOT_FOUND}

*** Keywords ***

Callout Test Binary Exist
    [Documentation]  Verify existence of prerequisite callout-test.

    Open Connection And Log In
    ${out}  ${stderr}=  Execute Command
    ...  which /tmp/tarball/bin/callout-test  return_stderr=True
    Should Be Empty  ${stderr}
    Should Contain  ${out}  callout-test


Create Test Error With Callout
    [Documentation]  Generate test error log with callout for CPU0.

    # Test error log entry example:
    #  "/xyz/openbmc_project/logging/entry/4": {
    #  "AdditionalData": [
    #      "CALLOUT_DEVICE_PATH_TEST=/sys/devices/platform/fsi-master/slave@00:00",
    #      "CALLOUT_ERRNO_TEST=0",
    #      "DEV_ADDR=0x0DEADEAD"
    #    ],
    #    "Id": 4,
    #    "Message": "example.xyz.openbmc_project.Example.Elog.TestCallout",
    #    "Resolved": 0,
    #    "Severity": "xyz.openbmc_project.Logging.Entry.Level.Error",
    #    "Timestamp": 1487747332528,
    #    "associations": [
    #        [
    #          "callout",
    #          "fault",
    #          "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #        ]
    #    ]
    # },
    # "/xyz/openbmc_project/logging/entry/4/callout": {
    #    "endpoints": [
    #        "/xyz/openbmc_project/inventory/system/chassis/motherboard/cpu0"
    #    ]
    # },

    BMC Execute Command
    ...  /tmp/tarball/bin/callout-test ${target_device_path}

Verify Test Error Log And Callout
    [Documentation]  Verify test error log entries.
    ${elog_entry}=  Get Elog URL List
    ${resp}=  OpenBMC Get Request  ${elog_entry[0]}
    ${json}=  To JSON  ${resp.content}

    Should Be Equal  ${json["data"]["Message"]}
    ...  example.xyz.openbmc_project.Example.Elog.TestCallout

    Should Be Equal  ${json["data"]["Severity"]}
    ...  xyz.openbmc_project.Logging.Entry.Level.Error

    ${content}=  Read Attribute  ${elog_entry[0]}/callout  endpoints

    Should Be Equal  ${content[0]}
    ...  ${POWERSUPPLY0_INVENTORY_URI}


Test Setup Execution
    [Documentation]  Do test case setup tasks.

    ${status}=  Run Keyword And Return Status  Callout Test Binary Exist
    Run Keyword If  ${status} == ${False}  Install Tarball
    Delete All Error Logs


Install Tarball
    [Documentation]  Install tarball on BMC.

    Run Keyword If  '${DEBUG_TARBALL_PATH}' == '${EMPTY}'  Return from Keyword
    BMC Execute Command  rm -rf /tmp/tarball
    Install Debug Tarball On BMC  ${DEBUG_TARBALL_PATH}


Install Inventory Path
    [Documentation]  Install inventory path

    BMC Execute Command
    ...  mkdir -p ${PERSIST_INVENTORY_PATH}${POWERSUPPLY0_INVENTORY_URI}
    BMC Execute Command
    ...  touch ${PERSIST_INVENTORY_PATH}${POWERSUPPLY0_INVENTORY_URI}/xyz.openbmc_project.Inventory.Item.PowerSupply
    BMC Execute Command
    ...  systemctl restart xyz.openbmc_project.Inventory.Manager

    ${resp}=  OpenBMC Get Request  ${POWERSUPPLY0_INVENTORY_URI}/
    Should Be Equal As Strings  ${resp.status_code}  ${HTTP_OK}

Check Inventory Path
    [Documentation]  Make sure the test inventory path has already been created

    ${resp}=  OpenBMC Get Request  ${POWERSUPPLY0_INVENTORY_URI}/
    Run Keyword If  ${resp.status_code} == ${HTTP_NOT_FOUND}
    ...  Install Inventory Path


Suite Setup Execution
   [Documentation]  Do test case setup tasks.

    Redfish.Login

    Redfish Purge Event Log

    Redfish Power On  stack_mode=skip  quiet=1

    ${status}=  Run Keyword And Return Status  Logging Test Binary Exist
    Run Keyword If  ${status} == ${False}  Install Tarball

    Check Inventory Path

Suite Teardown Execution
    [Documentation]  Do the post suite teardown.

    Redfish.Logout
