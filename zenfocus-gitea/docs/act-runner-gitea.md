Act Runner
This page will introduce the act runner in detail, which is the runner of Gitea Actions.

Requirements
Currently the runner supports run in two modes. One is running in docker container, another is running in host. It is recommended to run jobs in a docker container, if you chose this mode, you need to install docker first and make sure that the docker daemon is running.

Other OCI container engines which are compatible with Docker's API should also work, but are untested.

However, if you are sure that you want to run jobs directly on the host only, then docker is not required.

There are multiple ways to install the act runner.

Installation with binary
Download the binary
You can download the binary from the release page. However, if you want to use the latest nightly build, you can download it from the download page.

When you download the binary, please make sure that you have downloaded the correct one for your platform. You can check it by running the following command if you are in a Unix-Style OS.

chmod +x act_runner
./act_runner --version

If you see the version information, it means that you have downloaded the correct binary.

Obtain a registration token
You can register a runner in different levels, it can be:

Instance level: The runner will run jobs for all repositories in the instance.
Organization level: The runner will run jobs for all repositories in the organization.
Repository level: The runner will run jobs for the repository it belongs to.
Note that the repository may still use instance-level or organization-level runners even if it has its own repository-level runners. A future release may provide an option to allow more control over this.

Before register the runner and run it, you need a registration token. The level of the runner determines where to obtain the registration token.

Instance level: The admin settings page, like <your_gitea.com>/-/admin/actions/runners.
Organization level: The organization settings page, like <your_gitea.com>/<org>/settings/actions/runners.
Repository level: The repository settings page, like <your_gitea.com>/<owner>/<repo>/settings/actions/runners.
If you cannot see the settings page, please make sure that you have the right permissions and that Actions have been enabled.

The format of the registration token is a random string D0gvfu2iHfUjNqCYVljVyRV14fISpJxxxxxxxxxx.

A registration token can also be obtained from the gitea command-line interface:

gitea --config /etc/gitea/app.ini actions generate-runner-token

You can also use GITEA_RUNNER_REGISTRATION_TOKEN/GITEA_RUNNER_REGISTRATION_TOKEN_FILE environment variable to set a global runner registration token when Gitea starts, for example:

openssl rand -hex 24 > /some-dir/runner-token
export GITEA_RUNNER_REGISTRATION_TOKEN_FILE=/some-dir/runner-token
./gitea --config ...

The token from environment is valid until you reset the token (re-create a new one) via web UI or API.

Tokens are valid for registering multiple runners, until they are revoked and replaced by a new token using the token reset link in the web interface.

Configuration
Configuration is done via a configuration file. It is optional, and the default configuration will be used when no configuration file is specified. You can generate a configuration file by running the following command:

./act_runner generate-config

The default configuration is safe to use without any modification, so you can just use it directly.

./act_runner generate-config > config.yaml
./act_runner --config config.yaml [command]

Register the runner
Registration is required before running the act runner, because the runner needs to know where to get jobs from. And it is also important to Gitea instance to identify the runner.

If this has been installed using the binary package, the act runner can be registered by running the following command.

./act_runner register

Alternatively, you can use the --config option to specify the configuration file mentioned in the previous section.

./act_runner --config config.yaml register

You will be asked to input the registration information step by step. Includes:

The Gitea instance URL, like https://gitea.com/ or http://192.168.8.8:3000/.
The registration token.
The runner name, which is optional. If you leave it blank, the hostname will be used.
The runner labels, which is optional. If you leave it blank, the default labels will be used.
You may be confused about the runner labels, which will be explained later.

If you want to register the runner in a non-interactive way, you can use arguments to do it.

./act_runner register --no-interactive --instance <instance_url> --token <registration_token> --name <runner_name> --labels <runner_labels>


When you have registered the runner, you can find a new file named .runner in the current directory. This file stores the registration information. Please do not edit it manually. If this file is missing or corrupted, you can simply remove it and register again.

If you want to store the registration information in another place, you can specify it in the configuration file, and don't forget to specify the --config option.

Ephemeral Runners
Ephemeral runners provide a security hardening mechanism for enabling organization- or instance-wide runners without requiring full user trust. Once a job is assigned within a spot VM or container, the runner's exposed credentials are automatically revoked—blocking it from polling further jobs before any untrusted code runs, while still allowing it to report progress until completion by either Gitea or the runner.

act_runner 0.2.12+ required.

The updated commands for registering the runner as ephemeral are listed below. Refer to the previous section for detailed information on registering the act_runner.

./act_runner register --ephemeral

./act_runner --config config.yaml register --ephemeral

./act_runner register --no-interactive --ephemeral --instance <instance_url> --token <registration_token> --name <runner_name> --labels <runner_labels>


The runner must be registered each time it is intended to receive a job. After completing the single job it is designed to execute, the runner terminates.

To automate the registration and startup of new runners when a job is queued, use the workflow_job webhook.

Start the runner in command line
After you have registered the runner, you can run it by running the following command:

./act_runner daemon

or

./act_runner daemon --config config.yaml

The runner will fetch jobs from the Gitea instance and run them automatically.

Start the runner with Systemd
It is also possible to run act-runner as a systemd service. Create an unprivileged act_runner user on your system, and the following file in /etc/systemd/system/act_runner.service. The paths in ExecStart and WorkingDirectory may need to be adjusted depending on where you installed the act_runner binary, its configuration file, and the home directory of the act_runner user.

[Unit]
Description=Gitea Actions runner
Documentation=https://gitea.com/gitea/act_runner
After=docker.service

[Service]
ExecStart=/usr/local/bin/act_runner daemon --config /etc/act_runner/config.yaml
ExecReload=/bin/kill -s HUP $MAINPID
WorkingDirectory=/var/lib/act_runner
TimeoutSec=0
RestartSec=10
Restart=always
User=act_runner

[Install]
WantedBy=multi-user.target

Then:

# load the new systemd unit file
sudo systemctl daemon-reload
# start the service and enable it at boot
sudo systemctl enable act_runner --now

If using Docker, the act_runner user should also be added to the docker group before starting the service. Keep in mind that this effectively gives act_runner root access to the system [1].

Start the runner with LaunchDaemon(macOS)
Mac uses launchd in place of systemd for registering daemon processes. By default daemons run as the root user, so if desired an unprivileged _act_runner user can be created via the dscl tool. The following file should then be created at the directory /Library/LaunchDaemon/com.gitea.act_runner.plist. The paths for WorkingDirectory, ProgramArguments, StandardOutPath, StandardErrPath, and the HOME environment variable may need to be updated to reflect your installation. Also note that any executables outside of the example PATH shown will need to be explicitly included and will not be inherited from existing configurations.

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gitea.act_runner</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/act_runner</string>
        <string>daemon</string>
        <string>--config</string>
        <string>/etc/act_runner/config.yaml</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>/var/lib/act_runner</string>
    <key>StandardOutPath</key>
    <string>/var/lib/act_runner/act_runner.log</string>
    <key>StandardErrorPath</key>
    <string>/var/lib/act_runner/act_runner.err</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        <key>HOME</key>
        <string>/var/lib/act_runner</string>
    </dict>
    <key>UserName</key>
    <string>_act_runner</string>
</dict>
</plist>


Then:

sudo launchctl load /Library/LaunchDaemon/com.gitea.act_runner.plist

You can also set up a Linux service or Windows service to let the runner run automatically.

Install with the docker image
Pull the image
You can use the docker image from the docker hub. Just like the binary, you can use the latest nightly build by using the nightly tag, while the latest tag is the latest stable release.

docker pull docker.io/gitea/act_runner:latest # for the latest stable release

If you want to test newly features, you could also use nightly image

docker pull docker.io/gitea/act_runner:nightly # for the latest nightly build

Configuration
Configuration is optional, but you could also generate config file with docker:

docker run --entrypoint="" --rm -it docker.io/gitea/act_runner:latest act_runner generate-config > config.yaml


When you are using the docker image, you can specify the configuration file by using the CONFIG_FILE environment variable. Make sure that the file is mounted into the container as a volume:

docker run -v $PWD/config.yaml:/config.yaml -e CONFIG_FILE=/config.yaml ...

You may notice the commands above are both incomplete, because it is not the time to run the act runner yet. Before running the act runner, we need to register it to your Gitea instance first.

Start the runner with docker
If you are using the docker image, behaviour will be slightly different. Registration and running are combined into one step in this case, so you need to specify the registration information when running the act runner.

A quick start with docker run like below. You need to get <registration_token> from the above step, and give a special unique name for <runner_name>

docker run \
    -e GITEA_INSTANCE_URL=<instance_url> \
    -e GITEA_RUNNER_REGISTRATION_TOKEN=<registration_token> \
    -e GITEA_RUNNER_NAME=<runner_name> \
    --name my_runner \
    -d docker.io/gitea/act_runner:nightly

There are more parameters so that you can configure it.

docker run \
    -v $PWD/config.yaml:/config.yaml \
    -v $PWD/data:/data \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e CONFIG_FILE=/config.yaml \
    -e GITEA_INSTANCE_URL=<instance_url> \
    -e GITEA_RUNNER_REGISTRATION_TOKEN=<registration_token> \
    -e GITEA_RUNNER_NAME=<runner_name> \
    -e GITEA_RUNNER_LABELS=<runner_labels> \
    --name my_runner \
    -d docker.io/gitea/act_runner:nightly

You may notice that we have mounted the /var/run/docker.sock into the container. It is because the act runner will run jobs in docker containers, so it needs to communicate with the docker daemon. As mentioned, you can remove it if you want to run jobs in the host directly. To be clear, the "host" actually means the container which is running the act runner now, instead of the host machine.

To enable ephemeral runners, set the environment variable GITEA_RUNNER_EPHEMERAL=1 in the runner image. This setup doesn't use a /data volume because the credentials are single-use and not intended to be reused. You can find more details about this mode under Ephemeral runners.

docker run \
    -e GITEA_INSTANCE_URL=<instance_url> \
    -e GITEA_RUNNER_REGISTRATION_TOKEN=<registration_token> \
    -e GITEA_RUNNER_EPHEMERAL=1 \
    -e GITEA_RUNNER_NAME=<runner_name> \
    --name my_runner \
    -d docker.io/gitea/act_runner:nightly

docker run \
    -v $PWD/config.yaml:/config.yaml \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e CONFIG_FILE=/config.yaml \
    -e GITEA_INSTANCE_URL=<instance_url> \
    -e GITEA_RUNNER_REGISTRATION_TOKEN=<registration_token> \
    -e GITEA_RUNNER_EPHEMERAL=1 \
    -e GITEA_RUNNER_NAME=<runner_name> \
    -e GITEA_RUNNER_LABELS=<runner_labels> \
    --name my_runner \
    -d docker.io/gitea/act_runner:nightly

Mounting the host's Docker socket using /var/run/docker.sock:/var/run/docker.sock introduces a potential security vulnerability. If a job can access this socket, the reusable GITEA_RUNNER_REGISTRATION_TOKEN could be exposed through Docker inspect data.

Start the runner using docker compose
You could also set up the runner using the following docker-compose.yml:

version: "3.8"
services:
  runner:
    image: docker.io/gitea/act_runner:nightly
    environment:
      CONFIG_FILE: /config.yaml
      GITEA_INSTANCE_URL: "${INSTANCE_URL}"
      GITEA_RUNNER_REGISTRATION_TOKEN: "${REGISTRATION_TOKEN}"
      GITEA_RUNNER_NAME: "${RUNNER_NAME}"
      GITEA_RUNNER_LABELS: "${RUNNER_LABELS}"
    volumes:
      - ./config.yaml:/config.yaml
      - ./data:/data
      - /var/run/docker.sock:/var/run/docker.sock

When using docker, there is no requirement to enter the container and manually run ./act_runner daemon command as shown below. Once the container has been started successfully, it will show up as an active runner in your Gitea instance.

To enable ephemeral runners, set the environment variable GITEA_RUNNER_EPHEMERAL=1 in the runner image. This setup doesn't use a /data volume because the credentials are single-use and not intended to be reused. You can find more details about this mode under Ephemeral runners.

version: "3.8"
services:
  runner:
    image: docker.io/gitea/act_runner:nightly
    environment:
      CONFIG_FILE: /config.yaml
      GITEA_INSTANCE_URL: "${INSTANCE_URL}"
      GITEA_RUNNER_REGISTRATION_TOKEN: "${REGISTRATION_TOKEN}"
      GITEA_RUNNER_NAME: "${RUNNER_NAME}"
      GITEA_RUNNER_LABELS: "${RUNNER_LABELS}"
      GITEA_RUNNER_EPHEMERAL: "1"
    volumes:
      - ./config.yaml:/config.yaml
      - /var/run/docker.sock:/var/run/docker.sock

Mounting the host's Docker socket using /var/run/docker.sock:/var/run/docker.sock introduces a potential security vulnerability. If a job can access this socket, the reusable GITEA_RUNNER_REGISTRATION_TOKEN could be exposed through Docker inspect data.

Advanced Configurations
Configuring cache when starting a Runner using docker image
If you do not intend to use actions/cache in workflow, you can ignore this section.

If you use actions/cache without any additional configuration, it will return the following error:

Failed to restore: getCacheEntry failed: connect ETIMEDOUT IP:PORT

The error occurs because the runner container and job container are on different networks, so the job container cannot access the runner container.

Therefore, it is essential to configure the cache action to ensure its proper functioning. Follow these steps:

1.Obtain the LAN IP address of the host machine where the runner container is running.
2.Find an available port number on the host machine where the runner container is running.
3.Configure the following settings in the configuration file:
cache:
  enabled: true
  dir: ""
  # Use the LAN IP obtained in step 1
  host: "192.168.8.17"
  # Use the port number obtained in step 2
  port: 8088

4.When starting the container, map the cache port to the host machine:
docker run \
  --name gitea-docker-runner \
  -p 8088:8088 \
  -d docker.io/gitea/act_runner:nightly

Labels
flowchart TD
    A[Workflow: runs-on: ubuntu-22.04] --> B[Act Runner receives Job request]
    B --> C[Match label: ubuntu-22.04:docker://node:16-bullseye]
    C --> D[Start Docker container: node:16-bullseye]
    D --> E[Run Job steps inside the container]
    E --> F[Return execution results to Gitea]

The labels of a runner are used to determine which jobs the runner can run, and how to run them.

The default labels are ubuntu-latest:docker://node:16-bullseye,ubuntu-22.04:docker://node:16-bullseye,ubuntu-20.04:docker://node:16-bullseye,ubuntu-18.04:docker://node:16-buster. It is a comma-separated list, and each item is a label.

Let's take ubuntu-22.04:docker://node:16-bullseye as an example. It means that the runner can run jobs with runs-on: ubuntu-22.04, and the job will be run in a docker container with the image node:16-bullseye.

If the default image is insufficient for your needs, and you have enough disk space to use a better and bigger one, you can change it to ubuntu-22.04:docker://<the image you like>. You can find more useful images on act images.

If you want to run jobs in the host directly, you can change it to ubuntu-22.04:host or just ubuntu-22.04, the :host is optional. However, we suggest you to use a special name like linux_amd64:host or windows:host to avoid misusing it.

Starting with Gitea 1.21, you can change labels by modifying runners.labels in the runner configuration file (if you don't have a configuration file, please refer to configuration tutorials). The runner will use these new labels as soon as you restart it, i.e., by calling ./act_runner daemon --config config.yaml.