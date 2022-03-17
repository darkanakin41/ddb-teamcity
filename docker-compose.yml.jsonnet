local ddb = import 'ddb.docker.libjsonnet';

local domain = std.join('.', [std.extVar("core.domain.sub"), std.extVar("core.domain.ext")]);

ddb.Compose() {
    "services": {
        "db": ddb.Image("postgres:latest")
            + ddb.User()
            + {
                environment: {
                  "POSTGRES_PASSWORD": "teamcity_password",
                  "POSTGRES_USER": "teamcity_user",
                  "POSTGRES_DB": "teamcity_db",
                  "PG_DATA": "/var/lib/postgresql/data",
                },
                volumes: [
                    './buildserver_pgdata:/var/lib/postgresql/data:rw',
                ],
                restart: "unless-stopped"
            },
        "teamcity-server": ddb.Image("jetbrains/teamcity-server:2021.2.3")
            + ddb.VirtualHost("8111", domain, "app")
            + ddb.VirtualHost("8111", "teamcity.darkanakin41.duckdns.org", "app-public")
            + ddb.User()
            + {
                environment: {
                  "POSTGRES_PASSWORD": "teamcity_password",
                  "POSTGRES_USER": "teamcity_user",
                  "POSTGRES_DB": "teamcity_db",
                  "PG_DATA": "/var/lib/postgresql/data",
                },
                volumes: [
                    "./data_dir:/data/teamcity_server/datadir",
                    "./teamcity-server-logs:/opt/teamcity/logs"
                ],
                restart: "unless-stopped"
            },
        "teamcity-agent-1": ddb.Image("jetbrains/teamcity-agent:2021.2.3-linux-sudo")
            + ddb.User()
            + {
                environment: [
                  "SERVER_URL=http://teamcity-server:8111",
                  "DOCKER_IN_DOCKER=start",
                ],
                volumes: [
                    "./agents/agent-1/conf:/data/teamcity_agent/conf",
                    "/opt/buildagent/work:/opt/buildagent/work",
                    "/opt/buildagent/temp:/opt/buildagent/temp",
                    "/opt/buildagent/system:/opt/buildagent/system",
                    "/var/run/docker.sock:/var/run/docker.sock",
                    "/usr/bin/docker:/usr/bin/docker",
                ],
                restart: "unless-stopped",
                networks: ['default'],
                depends_on:["teamcity-server"],
                privileged: true,
            },
        "teamcity-agent-2": ddb.Image("jetbrains/teamcity-agent:2021.2.3-linux-sudo")
            + ddb.User()
            + {
                environment: [
                  "SERVER_URL=http://teamcity-server:8111",
                  "DOCKER_IN_DOCKER=start",
                ],
                volumes: [
                    "./agents/agent-2/conf:/data/teamcity_agent/conf",
                    "/opt/buildagent/work:/opt/buildagent/work",
                    "/opt/buildagent/temp:/opt/buildagent/temp",
                    "/opt/buildagent/system:/opt/buildagent/system",
                    "/var/run/docker.sock:/var/run/docker.sock",
                    "/usr/bin/docker:/usr/bin/docker",
                ],
                restart: "unless-stopped",
                networks: ['default'],
                depends_on: ["teamcity-server"],
                privileged: true,
            },
    }
}
