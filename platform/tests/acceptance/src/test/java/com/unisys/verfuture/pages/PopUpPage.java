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
import com.unisys.verfuture.utilities.TestUtil;

/**
 * Page Object for Manifest Generator page
 * 
 * @author DONTHISR
 *
 */
public class PopUpPage extends TestBase {
	@FindBy(css = "h5")
	WebElement modalBodyTxt;
	@FindBy(css = " div.modal-footer > button")
	WebElement closeBtn;

	// Initializing the Page Objects:
	public PopUpPage(WebDriver driver) {
		PageFactory.initElements(driver, this);
	}

	public String verifyPopUpPageTitle() {
		return driver.getTitle();
	}

	public String getConfirmText() {
		return modalBodyTxt.getText();
	}

	public void clickonCloseBtn() {
		TestUtil.clickElement(closeBtn, "Clicked on close button");
	}

}
