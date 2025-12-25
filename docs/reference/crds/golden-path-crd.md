---
title: Golden Path Devfile Specification
description: Complete field-level specification for Golden Path development environment configuration
---

# Golden Path Devfile Specification

## Overview

The Golden Path Devfile is a standardized development environment configuration using the [Devfile 2.2.2 specification](https://devfile.io/). It defines containerized workspaces for Eclipse Che with pre-configured tools, dependencies, and development workflows.

**Schema Version:** `2.2.2`

**File Location:** `platform/devfiles/goldenpath-{language}.yaml`

---

## Top-Level Fields

| Field             | Type   | Required | Default | Description                                               |
| ----------------- | ------ | -------- | ------- | --------------------------------------------------------- |
| `schemaVersion`   | String | Yes      | -       | Devfile schema version. Must be `2.2.2`.                  |
| `metadata`        | Object | Yes      | -       | Workspace metadata including name, description, and tags. |
| `starterProjects` | Array  | No       | `[]`    | Template repositories for bootstrapping new projects.     |
| `components`      | Array  | Yes      | -       | Container definitions, volumes, and Kubernetes resources. |
| `commands`        | Array  | No       | `[]`    | Executable tasks (build, run, test, debug).               |
| `events`          | Object | No       | `{}`    | Lifecycle hooks (preStart, postStart, preStop, postStop). |

---

## `metadata` Object

Defines workspace identification and categorization.

| Field         | Type          | Required | Default | Description                                                         |
| ------------- | ------------- | -------- | ------- | ------------------------------------------------------------------- |
| `name`        | String        | Yes      | -       | Unique identifier for the Devfile. Format: `goldenpath-{language}`. |
| `displayName` | String        | No       | -       | Human-readable name shown in Eclipse Che workspace selector.        |
| `description` | String        | No       | -       | Multi-line description of the development environment.              |
| `version`     | String        | No       | `1.0.0` | Semantic version of the Devfile configuration.                      |
| `provider`    | String        | No       | -       | Organization or team maintaining the Devfile.                       |
| `supportUrl`  | String        | No       | -       | URL for issue tracking or support documentation.                    |
| `tags`        | Array[String] | No       | `[]`    | Keywords for categorization (e.g., `Python`, `FastAPI`, `Django`).  |
| `icon`        | String        | No       | -       | URL to icon image representing the workspace technology.            |
| `projectType` | String        | No       | -       | High-level project category (e.g., `Python`, `Java`, `Node.js`).    |
| `language`    | String        | No       | -       | Primary programming language of the workspace.                      |

### Example

```yaml
metadata:
  name: goldenpath-python
  displayName: Golden Path Python Development
  version: 1.0.0
  provider: Fawkes Platform Team
  language: Python
```

---

## `starterProjects` Array

Template repositories for creating new projects from scratch.

### Object Structure

| Field                | Type   | Required | Default | Description                                     |
| -------------------- | ------ | -------- | ------- | ----------------------------------------------- |
| `name`               | String | Yes      | -       | Unique identifier for the starter project.      |
| `description`        | String | No       | -       | Brief description of the template's purpose.    |
| `git`                | Object | Yes      | -       | Git repository configuration.                   |
| `git.remotes`        | Object | Yes      | -       | Named remote URLs (typically `origin`).         |
| `git.remotes.origin` | String | Yes      | -       | HTTPS URL to the Git repository.                |
| `git.checkoutFrom`   | Object | No       | -       | Branch or tag to checkout (defaults to `HEAD`). |

### Example

```yaml
starterProjects:
  - name: python-fastapi
    description: FastAPI microservice template
    git:
      remotes:
        origin: https://github.com/paruff/fawkes-template-python-fastapi
```

---

## `components` Array

Defines containers, volumes, and Kubernetes resources for the workspace.

### Container Component

Specifies the main development container.

| Field                     | Type          | Required | Default     | Description                                                  |
| ------------------------- | ------------- | -------- | ----------- | ------------------------------------------------------------ |
| `name`                    | String        | Yes      | -           | Unique component name (e.g., `python`, `java`).              |
| `container`               | Object        | Yes      | -           | Container configuration.                                     |
| `container.image`         | String        | Yes      | -           | OCI image (format: `registry/repository:tag`).               |
| `container.memoryLimit`   | String        | No       | `2Gi`       | Maximum memory allocation (e.g., `4Gi`, `512Mi`).            |
| `container.memoryRequest` | String        | No       | `1Gi`       | Requested memory guarantee.                                  |
| `container.cpuLimit`      | String        | No       | `2`         | Maximum CPU cores (e.g., `2`, `500m` for 0.5 cores).         |
| `container.cpuRequest`    | String        | No       | `500m`      | Requested CPU guarantee.                                     |
| `container.mountSources`  | Boolean       | No       | `true`      | Whether to mount the project source code into the container. |
| `container.sourceMapping` | String        | No       | `/projects` | Path where source code is mounted.                           |
| `container.env`           | Array[Object] | No       | `[]`        | Environment variables.                                       |
| `container.endpoints`     | Array[Object] | No       | `[]`        | Exposed network endpoints.                                   |
| `container.volumeMounts`  | Array[Object] | No       | `[]`        | Volume mount points.                                         |

#### `container.env` Object

| Field   | Type   | Required | Description                                       |
| ------- | ------ | -------- | ------------------------------------------------- |
| `name`  | String | Yes      | Environment variable name (uppercase convention). |
| `value` | String | Yes      | Environment variable value.                       |

#### `container.endpoints` Object

| Field        | Type    | Required | Default  | Description                                        |
| ------------ | ------- | -------- | -------- | -------------------------------------------------- |
| `name`       | String  | Yes      | -        | Endpoint identifier (e.g., `python-app`, `debug`). |
| `targetPort` | Integer | Yes      | -        | Container port to expose.                          |
| `exposure`   | String  | No       | `public` | Access level: `public`, `internal`, `none`.        |
| `protocol`   | String  | No       | `http`   | Protocol: `http`, `https`, `tcp`, `udp`.           |

#### `container.volumeMounts` Object

| Field  | Type   | Required | Description                                                 |
| ------ | ------ | -------- | ----------------------------------------------------------- |
| `name` | String | Yes      | Name of the volume (must match a volume component).         |
| `path` | String | Yes      | Absolute path in the container where the volume is mounted. |

### Volume Component

Defines persistent storage for workspace data.

| Field         | Type   | Required | Default | Description                          |
| ------------- | ------ | -------- | ------- | ------------------------------------ |
| `name`        | String | Yes      | -       | Unique volume name.                  |
| `volume`      | Object | Yes      | -       | Volume configuration.                |
| `volume.size` | String | No       | `1Gi`   | Storage size (e.g., `2Gi`, `500Mi`). |

### Example

```yaml
components:
  - name: python
    container:
      image: quay.io/devfile/universal-developer-image:ubi8-latest
      memoryLimit: 4Gi
      cpuLimit: "2"
      env:
        - name: PYTHON_VERSION
          value: "3.11"
      endpoints:
        - name: python-app
          targetPort: 8000
          exposure: public
      volumeMounts:
        - name: pip-cache
          path: /home/user/.cache/pip

  - name: pip-cache
    volume:
      size: 2Gi
```

---

## `commands` Array

Executable tasks for build, run, test, and debug workflows.

### Object Structure

| Field                  | Type    | Required | Default     | Description                                                    |
| ---------------------- | ------- | -------- | ----------- | -------------------------------------------------------------- |
| `id`                   | String  | Yes      | -           | Unique command identifier (kebab-case).                        |
| `exec`                 | Object  | Yes      | -           | Execution configuration.                                       |
| `exec.label`           | String  | No       | -           | Human-readable command name shown in IDE.                      |
| `exec.component`       | String  | Yes      | -           | Name of the component where the command runs.                  |
| `exec.commandLine`     | String  | Yes      | -           | Shell command to execute (can be multi-line script).           |
| `exec.workingDir`      | String  | No       | `/projects` | Directory where the command executes. Use `${PROJECT_SOURCE}`. |
| `exec.group`           | Object  | No       | -           | Command categorization.                                        |
| `exec.group.kind`      | String  | Yes      | -           | Group type: `build`, `run`, `test`, `debug`.                   |
| `exec.group.isDefault` | Boolean | No       | `false`     | Whether this is the default command for the group.             |

### Example

```yaml
commands:
  - id: install-dependencies
    exec:
      label: "Install Dependencies"
      component: python
      commandLine: pip install -r requirements.txt
      workingDir: ${PROJECT_SOURCE}
      group:
        kind: build
        isDefault: true

  - id: run-tests
    exec:
      label: "Run Tests"
      component: python
      commandLine: pytest tests/ -v
      workingDir: ${PROJECT_SOURCE}
      group:
        kind: test
        isDefault: true
```

---

## `events` Object

Lifecycle hooks executed at specific workspace stages.

| Field       | Type          | Required | Default | Description                                 |
| ----------- | ------------- | -------- | ------- | ------------------------------------------- |
| `preStart`  | Array[String] | No       | `[]`    | Command IDs to run before workspace starts. |
| `postStart` | Array[String] | No       | `[]`    | Command IDs to run after workspace starts.  |
| `preStop`   | Array[String] | No       | `[]`    | Command IDs to run before workspace stops.  |
| `postStop`  | Array[String] | No       | `[]`    | Command IDs to run after workspace stops.   |

### Example

```yaml
events:
  postStart:
    - install-dependencies
```

---

## Available Golden Path Devfiles

| Language | File                     | Description                                       |
| -------- | ------------------------ | ------------------------------------------------- |
| Python   | `goldenpath-python.yaml` | Python 3.11 with Poetry, FastAPI, Django support. |
| AI/ML    | `goldenpath-ai.yaml`     | Python with Jupyter, TensorFlow, PyTorch.         |

---

## Usage

**Launch a workspace in Eclipse Che:**

```bash
# Using Devfile URL
che workspace:create --devfile=https://raw.githubusercontent.com/paruff/fawkes/main/platform/devfiles/goldenpath-python.yaml
```

**Reference in a custom Devfile:**

```yaml
parent:
  uri: https://raw.githubusercontent.com/paruff/fawkes/main/platform/devfiles/goldenpath-python.yaml
```

---

## See Also

- [Devfile 2.2.2 Schema Reference](https://devfile.io/docs/2.2.2/devfile-schema)
- [Eclipse Che Documentation](https://eclipse.dev/che/docs/)
- [Golden Path Usage Guide](../../golden-path-usage.md)
