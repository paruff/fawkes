/**
 * Java application Jenkinsfile example
 */

@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'java-service'
    language = 'java'

    // Custom Maven commands
    buildCommand = 'mvn clean package -DskipTests'
    testCommand = 'mvn test'
    bddTestCommand = 'mvn verify -Pcucumber'

    notifyChannel = 'java-team'
}
