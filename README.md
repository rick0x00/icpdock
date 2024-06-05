# ICPDOCK

Internet Content Provider(ICP) on Docker(icpdock) is a project to implement conteNt provider based on docker.

the objective is implement Content provider and all basic(or advanced) services and tweaks necessaries on always Web Applications(apps, sites, etc...).

this content provider is projected to small business, necessary pre requisites is simple, using ONE ip address on public internet and using Docker + DNS + FRR + "Reverse proxy" turn possible up multiple services using one IP address.

- The all ICP use CI/CD to provision services, manager version of project.
- Include IDS and IPS to grant security of ambient.
- Include observability tools to monitor and inspect traffic.
- include more tools to turn possible work on inside docker network for manage services more securely...
- turn possible make and restore fast and utils backups;
- turn possible implement High availability(HA) for the application never stop, using k8s, DYE Load Balances and fail over, multiple VPS's, sync data... etc...


