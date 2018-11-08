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
public class SubmitNewI9FormPage extends TestBase {
	@FindBy(css = "#fullLegalName")
	WebElement fulllegalname_Txt;
	@FindBy(css = "#alias")
	WebElement alias_Txt;
	@FindBy(css = "#dob")
	WebElement dob_Txt;
	@FindBy(css = "#address")
	WebElement addr_Txt;
	@FindBy(css = "#status")
	WebElement statusDrp;
	@FindBy(css = "#exampleSelectMulti")
	WebElement multiSelect;
	@FindBy(css = "#exampleFile")
	WebElement fileUploadBtn;
	@FindBy(css = "#alienNum")
	WebElement alien_Txt;
	// @FindBy(xpath = "//input[@class='input' and @type='text']")
	// WebElement fullName_Txt;
	// @FindBy(css = "#myForm > div:nth-child(2) > label > input")
	// WebElement aliasTxt;
	// @FindBy(css = "#myForm > div:nth-child(3) > label > input")
	// WebElement dobTxt;
	// @FindBy(css = "#myForm > div:nth-child(4) > label > input")
	// WebElement addrTxt;
	@FindBy(css = "#myForm > div:nth-child(5) > label > input")
	WebElement aliennoTxt;
	@FindBy(css = "form > button")
	WebElement subBtn;

	// Initializing the Page Objects:
	public SubmitNewI9FormPage(WebDriver driver) {
		PageFactory.initElements(driver, this);
	}

	public String verifyFormsPageTitle() {
		return driver.getTitle();
	}

	public void fillformWithDetails(String nm, String alias_nm, String dob, String addr, String status)
			throws InterruptedException, AWTException {
		TestUtil.waitForVisibilityofElement(fulllegalname_Txt);
		fulllegalname_Txt.sendKeys(nm);
		TestUtil.waitForVisibilityofElement(alias_Txt);
		alias_Txt.sendKeys(alias_nm);
		TestUtil.waitForVisibilityofElement(dob_Txt);
		dob_Txt.sendKeys(dob);
		TestUtil.waitForVisibilityofElement(addr_Txt);
		addr_Txt.sendKeys(addr);
		// TestUtil.waitForVisibilityofElement(status);
		Select statusDrpdn = new Select(statusDrp);
		((Select) statusDrpdn).selectByVisibleText("US Citizen");
	}

	public void multiSelection() {
		// Multiple selection
		List<WebElement> listOptions = multiSelect.findElements(By.tagName("option"));
		multiSelect.sendKeys(Keys.CONTROL);
		listOptions.get(1).click();// Selects the first option.
		listOptions.get(2).click();// Selects the second option.
	}

	public void fileUpload() throws AWTException, InterruptedException {
		// Get the file name from resources folder
		ClassLoader classLoader = getClass().getClassLoader();
		File file = new File(classLoader.getResource("testdata/Postman.docx").getFile());
		StringSelection sel = new StringSelection(file.toString());
		// Copy to clipboard
		Toolkit.getDefaultToolkit().getSystemClipboard().setContents(sel, null);
		System.out.println("selection" + sel);
		TestUtil.clickElement(fileUploadBtn, "Clicked on File Upload Button");
		// Create object of Robot class
		Robot robot = new Robot();
		Thread.sleep(1000);

		// Press Enter
		robot.keyPress(KeyEvent.VK_ENTER);

		// Release Enter
		robot.keyRelease(KeyEvent.VK_ENTER);

		// Press CTRL+V
		robot.keyPress(KeyEvent.VK_CONTROL);
		robot.keyPress(KeyEvent.VK_V);

		// Release CTRL+V
		robot.keyRelease(KeyEvent.VK_CONTROL);
		robot.keyRelease(KeyEvent.VK_V);
		Thread.sleep(1000);

		// Press Enter
		robot.keyPress(KeyEvent.VK_ENTER);
		robot.keyRelease(KeyEvent.VK_ENTER);
		Thread.sleep(500);

	}

	public void inputAlienno(String alienno) {
		TestUtil.waitForVisibilityofElement(aliennoTxt);
		aliennoTxt.sendKeys(alienno);
		logger.info("Form is filled with data");

	}

	public confirmationPage clickOnSubmit() {
		TestUtil.waitForVisibilityofElement(subBtn);
		TestUtil.clickElement(subBtn, "submit button is clicked");
		logger.info("Clicked on submit button");
		return PageFactory.initElements(driver, confirmationPage.class);
	}

}
