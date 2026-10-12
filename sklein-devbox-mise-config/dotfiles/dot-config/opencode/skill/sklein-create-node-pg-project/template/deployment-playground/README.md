# Deployment Playground

Local playground for testing the application in a production-like environment.

## Setup

```bash
$ podman compose build
$ podman compose run --rm app seed
$ podman compose up -d app
```

## Logs

```bash
$ podman compose logs -f app
Attempting to connect to postgres://postgres:****@postgres:5432/postgres
Migrations done
Attempting to connect to postgres://postgres:****@postgres:5432/postgres
contacts: Result(3) [
  {
    id: '1',
    firstname: 'Alice',
    lastname: 'Martin',
    created_at: 2026-05-24T20:52:32.617Z
  },
  {
    id: '2',
    firstname: 'Bob',
    lastname: 'Durand',
    created_at: 2026-05-24T20:52:32.617Z
  },
  {
    id: '3',
    firstname: 'Charlie',
    lastname: 'Petit',
    created_at: 2026-05-24T20:52:32.617Z
  }
]
```

## Tear down

```bash
$ podman compose down -v
```
