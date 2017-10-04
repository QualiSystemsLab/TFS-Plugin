# TFS-Plugin

## Overview

CloudShell custom tasks for TFS build or release workflows.

- StartCloudShellSandbox
	- Start a sandbox from a blueprint name
	- Supports topology inputs
	- Stores environment variables available to other tasks in this workflow run
		- SandboxId
		- SandboxComponents: raw JSON from the sandbox API describing the service and resources:
			- name
			- address
			- attributes
- EndCloudShellSandbox
	- End the sandbox using the sandbox id in the environment
- RunCloudShellCommand
	- Run an environment or service/resource command
	- With inputs
	- Uses the sandbox id in the environment
	- Target resource or service can be specified with a regex in case of a deployed app with a randomized name

	
CloudShell credentials must be set as build or release variables in the build or release `Variables` tab in TFS:

- `cloudshell.apiUrl`
- `cloudshell.username`
- `cloudshell.password`
- `cloudshell.domain`

TODO: Make cloudshell.password a secret variable, which must be accessed from the code differently: https://stackoverflow.com/questions/35294742/how-do-i-use-secret-variables-in-tfs-2015-vnext-build-definitions 


## Usage

Add CloudShell tasks to a TFS build or release workflow:
![](screenshots/add-task.png)

Set CloudShell connection info in workflow variables:
![](screenshots/workflow-variables.png)


Step to start a CloudShell sandbox and wait for Setup:
![](screenshots/start-sandbox-task.png)

Step to run a CloudShell command (environment, resource, or service):
![](screenshots/run-command-task.png)

Step to tear down a CloudShell sandbox:
![](screenshots/end-sandbox-task.png)

How to access CloudShell reservation id and JSON resource and service details from any third-party TFS task:
![](screenshots/accessing-info-task.png)


Executing the workflow:

![](screenshots/queue-new-build.png)

![](screenshots/executing.png)


## Test data

Zip the contents of `test_environment` and drag into the portal.

*!!! Be sure the blueprint is marked public !!!*



## Development and Installation

### System requirements

Tested on Windows 2016 with TFS 2017.1. Both are available as free trials.

TFS 2015 may have an incompatible package format and may not support the `tfx` CLI at all. 

### Downloading separately licensed Microsoft component

Download the VstsTaskSdk library that must be bundled into each task package:

    Save-Module -Name VstsTaskSdk -Path .\

This will download to the current directory.

Under the folder `ps_module` under each task, copy `VstsTaskSdk` *removing the folder like `0.10.0` from the hierarchy* so that these paths exist:

- `StartCloudShellSandbox\ps_module\VstsTaskSdk\`
- `EndCloudShellSandbox\ps_module\VstsTaskSdk\`
- `RunCloudShellCommand\ps_module\VstsTaskSdk\`

In `VstsTaskSdk` you should see multiple files including `VstsTaskSdk.psd1`.


### Installing the tasks on TFS


#### Install a Windows agent

On the machine where you want to install the agent (probably the TFS server itself):
- Go to http://my_tfs_server:8080/tfs/DefaultCollection/_admin/_AgentPool
- Click `Download Agent`
- Disregard the detailed instructions &mdash; all they do is unzip and show how to run if you don't want to run it as a service
- Unzip the zip file in some new directory under `c:\`. Note that if you extract it under your home directory, it will fail to start because of permissions errors.
- In PowerShell, run `.\configure.cmd` in the unzipped directory
- Answer `Y` when asked if you want to run as a service
- After a few minutes, refresh the page above and the agent should show as online
- In the event of failure, check for logs under the directory where you unzipped


#### Get an access token for the CLI

In the TFS 2017 GUI, generate a "personal access token" (PAT): https://roadtoalm.com/2015/07/22/using-personal-access-tokens-to-access-visual-studio-online/


#### Get `tfx` CLI

In PowerShell:

	npm install -g tfx-cli

Windows 2016 or TFS 2017 comes with `npm`.
	
#### Upload using the CLI

In PowerShell:

	tfx login
	URL: http://my_tfs_server:8080/tfs/DefaultCollection
	Token: the access token


Note that the URL must end with DefaultCollection.

Package each task and upload it:

    tfx build tasks upload --task.path .\StartCloudShellSandbox\
    tfx build tasks upload --task.path .\EndCloudShellSandbox\
    tfx build tasks upload --task.path .\RunCloudShellCommand\

Note: You must manually increment the patch number in `task.json` anytime you update a task.

