package main

# Policy: Dockerfile must not use root user
deny contains msg if {
    input[i].Cmd == "user"
    input[i].Value[_] == "root"

    msg := "Dockerfile must not use root user. Add 'USER <non-root-user>' instruction"
}

# Policy: Dockerfile should use specific base image versions
warn contains msg if {
    input[i].Cmd == "from"
    val := input[i].Value[_]
    endswith(val, ":latest")

    msg := sprintf("Base image uses ':latest' tag: %s. Use specific version for reproducibility", [val])
}

# Policy: Require HEALTHCHECK in Dockerfile
warn contains msg if {
    not dockerfile_has_healthcheck

    msg := "Dockerfile should include HEALTHCHECK instruction for container health monitoring"
}

dockerfile_has_healthcheck if {
    input[_].Cmd == "healthcheck"
}

# Policy: Minimize layers by combining RUN commands
# Note: The threshold of 5 is a reasonable default but can be adjusted per project
warn contains msg if {
    max_run_commands := 5  # Configurable threshold
    run_count := count([cmd | input[i].Cmd == "run"; cmd := input[i]])
    run_count > max_run_commands

    msg := sprintf("Dockerfile has %d RUN commands. Consider combining them to reduce layers (threshold: %d)", [run_count, max_run_commands])
}

# Policy: Use COPY instead of ADD (unless extracting archives)
warn contains msg if {
    input[i].Cmd == "add"
    not is_archive_operation(input[i])

    msg := "Use COPY instead of ADD unless extracting archives. ADD has implicit behavior that can be unexpected"
}

is_archive_operation(cmd) if {
    val := cmd.Value[_]
    endswith(val, ".tar")
}

is_archive_operation(cmd) if {
    val := cmd.Value[_]
    endswith(val, ".tar.gz")
}

is_archive_operation(cmd) if {
    val := cmd.Value[_]
    endswith(val, ".zip")
}

# Policy: Require non-empty LABEL with maintainer info
warn contains msg if {
    not has_maintainer_label

    msg := "Dockerfile should include LABEL with maintainer information"
}

has_maintainer_label if {
    input[_].Cmd == "label"
    input[_].Value[_] == "maintainer"
}

# Policy: Avoid using sudo in Dockerfile
deny contains msg if {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, "sudo")

    msg := "Avoid using 'sudo' in Dockerfile. Use appropriate USER instruction instead"
}

# Policy: Always clean package manager cache
warn contains msg if {
    has_apt_install
    not has_apt_clean

    msg := "When using apt-get install, always clean up with 'apt-get clean && rm -rf /var/lib/apt/lists/*'"
}

has_apt_install if {
    input[_].Cmd == "run"
    val := concat(" ", input[_].Value)
    contains(val, "apt-get install")
}

has_apt_clean if {
    input[_].Cmd == "run"
    val := concat(" ", input[_].Value)
    contains(val, "apt-get clean")
}

# Policy: Use specific versions for apt packages
warn contains msg if {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, "apt-get install")
    not contains(val, "=")

    msg := "Consider pinning apt package versions for reproducibility (e.g., package=version)"
}

# Policy: Set working directory
warn contains msg if {
    not has_workdir

    msg := "Dockerfile should set WORKDIR to establish a consistent working directory"
}

has_workdir if {
    input[_].Cmd == "workdir"
}

# Policy: Expose ports should be documented
warn contains msg if {
    has_expose := count([cmd | input[i].Cmd == "expose"; cmd := input[i]])
    has_expose == 0

    msg := "Consider using EXPOSE to document which ports your application uses"
}
