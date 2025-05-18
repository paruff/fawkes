package com.unisys.verfuture;

import org.junit.runner.RunWith;



import cucumber.api.CucumberOptions;
import cucumber.api.junit.Cucumber;
/**
 *Runner class for tests with cucumber
 * @author DONTHISR
 *
 */
@RunWith(Cucumber.class)
//@RunWith(Cucumber.class)
@CucumberOptions(
		 features="classpath:features/Employee"		
		,glue={"com.unisys.verfuture.stepdefinitions"},
		plugin= {"pretty","html:target/cucumber-html-report", "json:target/cucumber.json","junit:junit_xml/cucumber.xml"}, //to generate different types of reporting
		monochrome = true, //display the console output in a proper readable format
	    strict = true, //it will check if any step is not defined in step definition file
		dryRun = false //to check the mapping is proper between feature file and step def file
		//tags = {"@smoketest"} 	
		)
 
public class Verfuture_TestSuite {

}
