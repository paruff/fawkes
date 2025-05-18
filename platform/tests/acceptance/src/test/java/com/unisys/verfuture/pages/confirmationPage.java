package com.unisys.verfuture.pages;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.CacheLookup;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import com.unisys.verfuture.base.TestBase;
import com.unisys.verfuture.cucumber.TestContext;
import com.unisys.verfuture.utilities.TestUtil;

/**
 * Page Object for Manifest Generator page
 * 
 * @author DONTHISR
 *
 */
public class confirmationPage extends TestBase {
	TestContext testContext;
	@FindBy(css = "h3")
	WebElement confirmTxt;

	// Initializing the Page Objects:
	public confirmationPage(WebDriver driver) {
		PageFactory.initElements(driver, this);
	}

	public String verifyConfirmationPageTitle() {
		return driver.getTitle();
	}

	public String getConfirmText() {
		return confirmTxt.getText();
	}

	public String getFormId() {
		String confirmText = this.getConfirmText();
		String formId = confirmText.substring(42);
		System.out.println("Form Id is:" + formId);
		return formId;
	}
	
	public void saveFormIdtoContext() {
	//	testContext.scenarioContext.setContext(Context.PRODUCT_NAME, productName);
	}

}
