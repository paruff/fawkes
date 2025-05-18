package com.unisys.verfuture.cucumber;

public class TestContext {
	public ScenarioContext scenarioContext;

	public TestContext() {
		scenarioContext = new ScenarioContext();
	}

	public ScenarioContext getScenarioContext() {
		return scenarioContext;
	}
}
