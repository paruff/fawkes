package com.unisys.verfuture.stepdefinitions;

import java.io.File;
import java.io.IOException;

import org.apache.commons.io.FileUtils;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriverException;
import com.unisys.verfuture.base.TestBase;
import cucumber.api.Scenario;
import cucumber.api.java.After;
import cucumber.api.java.Before;

/**
 * Hooks class for Project
 * 
 * @author DONTHISR
 *
 */

public class Hooks extends TestBase {
	@Before

	@After
    /**
     * Embed a screenshot in test report if test is marked as failed
     */
    public void embedScreenshot(Scenario scenario) throws IOException {
       
        if(scenario.isFailed() && driver != null) {
            try {
            	File scrFile = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
            	String currentDir = System.getProperty("user.dir");
            	FileUtils.copyFile(scrFile, new File(currentDir + "/screenshots/" + System.currentTimeMillis() + ".png"));
            } catch (WebDriverException somePlatformsDontSupportScreenshots) {
                System.err.println(somePlatformsDontSupportScreenshots.getMessage());
            }        
        }       
	}
}
