/**
 * Go application Jenkinsfile example
 */

@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'go-service'
    language = 'go'
    
    // Custom Go commands
    buildCommand = 'go build -v ./...'
    testCommand = 'go test -v -coverprofile=coverage.out ./...'
    bddTestCommand = 'go test -v ./features/...'
    
    notifyChannel = 'go-team'
}
