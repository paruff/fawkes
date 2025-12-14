package com.fawkes.${{ values.name | replace("-", "") }}.bdd;

import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import io.cucumber.spring.CucumberContextConfiguration;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

@CucumberContextConfiguration
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class HealthStepDefinitions {

    @Autowired
    private TestRestTemplate restTemplate;

    private ResponseEntity<String> response;

    @When("I request the health endpoint")
    public void iRequestTheHealthEndpoint() {
        response = restTemplate.getForEntity("/api/health", String.class);
    }

    @When("I request the info endpoint")
    public void iRequestTheInfoEndpoint() {
        response = restTemplate.getForEntity("/api/info", String.class);
    }

    @Then("the response status should be {int}")
    public void theResponseStatusShouldBe(int statusCode) {
        assertThat(response.getStatusCode().value()).isEqualTo(statusCode);
    }

    @Then("the response should contain status {string}")
    public void theResponseShouldContainStatus(String status) {
        assertThat(response.getBody()).contains("\"status\":\"" + status + "\"");
    }

    @Then("the response should contain service name {string}")
    public void theResponseShouldContainServiceName(String serviceName) {
        assertThat(response.getBody()).contains("\"service\":\"" + serviceName + "\"");
    }

    @Then("the response should contain name {string}")
    public void theResponseShouldContainName(String name) {
        assertThat(response.getBody()).contains("\"name\":\"" + name + "\"");
    }

    @Then("the response should contain version {string}")
    public void theResponseShouldContainVersion(String version) {
        assertThat(response.getBody()).contains("\"version\":\"" + version + "\"");
    }
}
