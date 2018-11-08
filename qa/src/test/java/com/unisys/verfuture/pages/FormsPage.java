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
public class FormsPage extends TestBase {
	@FindBy(css = "#nav-formI9")
	WebElement i9formLink;
	@FindBy(css = "#nav-find-id")
	WebElement findI9FormLink;
	@FindBy(css = "div > button:nth-child(4)")
	WebElement resetLink;
	@FindBy(css="#nav-find-all")
	WebElement listallI9formsLink;

	// Initializing the Page Objects:
	public FormsPage(WebDriver driver) {
		PageFactory.initElements(driver, this);
	}

	public String verifyFormsPageTitle() {
		return driver.getTitle();
	}

	public I9FormPage clickOni9FormLink() throws InterruptedException {
		logger.info("User has clicked on I9FormLink");
		Thread.sleep(1000);
		TestUtil.waitForVisibilityofElement(i9formLink);
		TestUtil.clickElement(i9formLink, "i9form is clicked");
       	return PageFactory.initElements(driver,I9FormPage.class);
	}
	
	public FindI9FormPage clickOnFindI9FormLink() throws InterruptedException {
		logger.info("User has clicked on FindI9FormLink");
		Thread.sleep(1000);
		TestUtil.waitForVisibilityofElement(findI9FormLink);
		TestUtil.clickElement(findI9FormLink, "FindI9Form Link is clicked");
       	return PageFactory.initElements(driver,FindI9FormPage.class);
	}
	public ListAllI9FormsPage clickOnlistAllI9FormsLink() throws InterruptedException {
		logger.info("User has clicked on listallI9formsLink");
		Thread.sleep(1000);
		TestUtil.waitForVisibilityofElement(listallI9formsLink);
		TestUtil.clickElement(listallI9formsLink, "ListAllI9Forms Link is clicked");
       	return PageFactory.initElements(driver,ListAllI9FormsPage.class);
	}

}
