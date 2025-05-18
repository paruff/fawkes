package com.unisys.verfuture.pages;

import java.awt.AWTException;
import java.awt.Robot;
import java.awt.Toolkit;
import java.awt.datatransfer.StringSelection;
import java.awt.event.KeyEvent;
import java.io.File;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.Keys;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.interactions.Actions;
import org.openqa.selenium.support.CacheLookup;
import org.openqa.selenium.support.FindBy;
import org.openqa.selenium.support.PageFactory;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.Select;
import org.openqa.selenium.support.ui.WebDriverWait;

import com.unisys.verfuture.base.TestBase;
import com.unisys.verfuture.utilities.TestUtil;

/**
 * Page Object for Manifest Generator page
 * 
 * @author DONTHISR
 *
 */
public class FindI9FormPage extends TestBase {
	String Id;
	@FindBy(css = "#id-input")
	WebElement findbyId_Txt;
	@FindBy(xpath = "//button[text()='Submit']")
	WebElement sub_Btn;
	@FindBy(css = "div > span > strong")
	WebElement foundId_Txt;
	@FindBy(css = "div > a[href]")
	WebElement idLink;

	// Initializing the Page Objects:
	public FindI9FormPage(WebDriver driver) {
		PageFactory.initElements(driver, this);
	}

	public String verifyFindI9FormPageTitle() {
		return driver.getTitle();
	}

	public void inputFindbyID(String id, String formId) {
		this.Id = formId;

		try {
			Thread.sleep(2000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		// driver.get("http://verfut-de-external-1nudtvsk6rmml-577586660.us-east-1.elb.amazonaws.com/#/findById");
		// driver.navigate().to(driver.getCurrentUrl());
		TestUtil.waitForVisibilityofElement(findbyId_Txt);
		findbyId_Txt.clear();
		findbyId_Txt.sendKeys(id);
		logger.info("Find By Id field is filled");

	}

	public void clickOnSubmit() {
		// driver.navigate().to(driver.getCurrentUrl());
		try {
			Thread.sleep(2000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		TestUtil.waitForVisibilityofElement(sub_Btn);
		Actions builder = new Actions(driver);
		// TestUtil.waitForElementToBeStable(formsDrpdwn);
		// use Mouse hover action for that element
		builder.moveToElement(sub_Btn).build().perform();
		// TestUtil.clickOnElementJS(sub_Btn);
		TestUtil.clickElement(sub_Btn, "submit button is clicked");
		logger.info("Clicked on submit button");
		try {
			Thread.sleep(2000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	public void refreshPage() {
		Actions actions = new Actions(driver);
		actions.keyDown(Keys.CONTROL).sendKeys(Keys.F5).perform();
		driver.navigate().refresh();
	}

	public void inputFindbyformId(String formId) {
		this.Id = formId;
		TestUtil.waitForVisibilityofElement(findbyId_Txt);
		findbyId_Txt.clear();
		findbyId_Txt.sendKeys(Id);
		logger.info("Find By Id field is filled");

	}

	public String foundId() {
		return foundId_Txt.getText();
	}

	public void clickOnidLink() {
		try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		TestUtil.waitForVisibilityofElement(idLink);
		TestUtil.clickElement(idLink, "ID link is clicked");
		logger.info("Clicked on ID link");

	}

	// public void inputFindbyID(String arg1, String formId) {
	// // TODO Auto-generated method stub
	//
	// }

}
