package main

# Policy: Dockerfile must not use root user
deny[msg] {
    input[i].Cmd == "user"
    input[i].Value[_] == "root"
    
    msg := "Dockerfile must not use root user. Add 'USER <non-root-user>' instruction"
}

# Policy: Dockerfile should use specific base image versions
warn[msg] {
    input[i].Cmd == "from"
    val := input[i].Value[_]
    endswith(val, ":latest")
    
    msg := sprintf("Base image uses ':latest' tag: %s. Use specific version for reproducibility", [val])
}

# Policy: Require HEALTHCHECK in Dockerfile
warn[msg] {
    not dockerfile_has_healthcheck
    
    msg := "Dockerfile should include HEALTHCHECK instruction for container health monitoring"
}

dockerfile_has_healthcheck {
    input[_].Cmd == "healthcheck"
}

# Policy: Minimize layers by combining RUN commands
warn[msg] {
    run_count := count([cmd | input[i].Cmd == "run"; cmd := input[i]])
    run_count > 5
    
    msg := sprintf("Dockerfile has %d RUN commands. Consider combining them to reduce layers", [run_count])
}

# Policy: Use COPY instead of ADD (unless extracting archives)
warn[msg] {
    input[i].Cmd == "add"
    not is_archive_operation(input[i])
    
    msg := "Use COPY instead of ADD unless extracting archives. ADD has implicit behavior that can be unexpected"
}

is_archive_operation(cmd) {
    val := cmd.Value[_]
    endswith(val, ".tar")
}

is_archive_operation(cmd) {
    val := cmd.Value[_]
    endswith(val, ".tar.gz")
}

is_archive_operation(cmd) {
    val := cmd.Value[_]
    endswith(val, ".zip")
}

# Policy: Require non-empty LABEL with maintainer info
warn[msg] {
    not has_maintainer_label
    
    msg := "Dockerfile should include LABEL with maintainer information"
}

has_maintainer_label {
    input[_].Cmd == "label"
    input[_].Value[_] == "maintainer"
}

# Policy: Avoid using sudo in Dockerfile
deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, "sudo")
    
    msg := "Avoid using 'sudo' in Dockerfile. Use appropriate USER instruction instead"
}

# Policy: Always clean package manager cache
warn[msg] {
    has_apt_install
    not has_apt_clean
    
    msg := "When using apt-get install, always clean up with 'apt-get clean && rm -rf /var/lib/apt/lists/*'"
}

has_apt_install {
    input[_].Cmd == "run"
    val := concat(" ", input[_].Value)
    contains(val, "apt-get install")
}

has_apt_clean {
    input[_].Cmd == "run"
    val := concat(" ", input[_].Value)
    contains(val, "apt-get clean")
}

# Policy: Use specific versions for apt packages
warn[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, "apt-get install")
    not contains(val, "=")
    
    msg := "Consider pinning apt package versions for reproducibility (e.g., package=version)"
}

# Policy: Set working directory
warn[msg] {
    not has_workdir
    
    msg := "Dockerfile should set WORKDIR to establish a consistent working directory"
}

has_workdir {
    input[_].Cmd == "workdir"
}

# Policy: Expose ports should be documented
warn[msg] {
    has_expose := count([cmd | input[i].Cmd == "expose"; cmd := input[i]])
    has_expose == 0
    
    msg := "Consider using EXPOSE to document which ports your application uses"
}
