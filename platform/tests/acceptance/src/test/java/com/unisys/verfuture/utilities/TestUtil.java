package com.unisys.verfuture.utilities;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.List;
import java.util.Random;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedCondition;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.StaleElementReferenceException;
import org.openqa.selenium.WebDriver;

import com.unisys.verfuture.base.*;

public class TestUtil extends TestBase {

	public static long PAGE_LOAD_TIMEOUT = 20;
	public static long IMPLICIT_WAIT = 20;

	public static String TESTDATA_SHEET_PATH = "/testdata/FreeCrmTestData.xlsx";

	static Workbook book;
	static Sheet sheet;
	static JavascriptExecutor js = (JavascriptExecutor) driver;

	public void switchToFrame() {
		driver.switchTo().frame("mainpanel");
	}

	public static Object[][] getTestData(String sheetName) {
		FileInputStream file = null;
		try {
			file = new FileInputStream(TESTDATA_SHEET_PATH);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
		try {
			book = WorkbookFactory.create(file);
		} catch (InvalidFormatException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		sheet = book.getSheet(sheetName);
		Object[][] data = new Object[sheet.getLastRowNum()][sheet.getRow(0).getLastCellNum()];
		// System.out.println(sheet.getLastRowNum() + "--------" +
		// sheet.getRow(0).getLastCellNum());
		for (int i = 0; i < sheet.getLastRowNum(); i++) {
			for (int k = 0; k < sheet.getRow(0).getLastCellNum(); k++) {
				data[i][k] = sheet.getRow(i + 1).getCell(k).toString();
				// System.out.println(data[i][k]);
			}
		}
		return data;
	}

	public static void scrollIntoViewJS(WebElement webElement) {
		// ((JavascriptExecutor)
		// getDriver()).executeScript("arguments[0].scrollIntoView(true);", webElement);
		js.executeScript("arguments[0].scrollIntoView();", webElement);
		logger.info("JS Scrolled into an Element: " + webElement);
	}

	public static void clickOnElementJS(WebElement webElement) {
		scrollIntoViewJS(webElement);
		// ignoreStaleElementError(webElement, 15);
		// JavascriptExecutor executor = (JavascriptExecutor) getDriver();
		js.executeScript("arguments[0].click();", webElement);
		logger.info("JS Clicked on an Element: " + webElement);
	}
	
	//To handle staleElement Exception
	public static void clickOnStableElement(final By locator) {
        WebElement e = new WebDriverWait(driver, 10).until(new ExpectedCondition<WebElement>() {

			public WebElement apply(WebDriver driver) {
				try {
                  return driver.findElement(locator);
              } catch (StaleElementReferenceException ex) {
                  return null;
              }
			}
		});       	
        e.click();
     }  

	public static void ignoreStaleElementError(WebElement webElement, long timeOutInSeconds) {
		long time1 = System.currentTimeMillis();
		try {
			webElement.isEnabled();
		} catch (Exception t) {
			new WebDriverWait(driver, timeOutInSeconds).ignoring(RuntimeException.class)
					.until(ExpectedConditions.elementToBeClickable(webElement));
			boolean value = webElement.isEnabled();
			logger.info("Ignored Exception and current element enability is: " + value);
			long time2 = System.currentTimeMillis();
			logger.info("Total time taken to Ignore Error is= " + (time2 - time1) / 1000 + " Seconds");
		}

	}

	public WebElement webElementByXpathText(String xpathText) {
		return driver.findElement(By.xpath(String.format("//*[text()='%s']", xpathText)));
	}

	public static void scrollToTheTopJS() {
		logger.info("Scrolling into top... ");
		js.executeScript("window.scrollBy(0,-500)", "");
	}

	public static void scrollVerticallyByPixelsJS(int pixels) {
		logger.info("Scrolling vertically...");
		js.executeScript("window.scrollBy(0,\"" + pixels + "\")", "");
	}

	public static void scrollByPixelsHorizontalJS(int pixels) {
		logger.info("Scrolling horizontally...");
		js.executeScript("window.scrollBy(\"" + pixels + "\", 0)", "");
	}

	public static String clickOnElemenByTextfromListElements(List<WebElement> webelements, String Text) {
		String value = null;

		List<WebElement> links = webelements;
		for (int i = 0; i < links.size(); i++) {

			try {
				links.get(i).wait();
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			if (links.get(i).getText().trim().equals(Text)) {
				value = links.get(i).getText().trim();

				scrollIntoViewJS(links.get(i));
				links.get(i).click();
				logger.info(value + " has been selected from the list");
				break;
			}
		}
		return value;
	}

	public static String clickOnElemenByIndexfromListElements(List<WebElement> webelements, int ElementIndex) {
		String value = null;
		List<WebElement> links = webelements;
		for (int i = 0; i < links.size(); i++) {
			links = webelements; // this step is must, because whenever you go
									// to other page all store webelements in a
									// list will washout
			if (links.size() != 0) {
				value = links.get(ElementIndex - 1).getText();
				links.get(ElementIndex - 1).click();
				break;
			} else if (links.size() == 0) {
				System.out.println("There is no Scan/Alarm is available to select at this moment");
			}
		}
		return value;
	}

	public static boolean stringContainsItemFromList(WebElement webElement, String[] items) {
		String inputStr = webElement.getText();
		for (int i = 0; i < items.length; i++) {
			if (!inputStr.contains(items[i].trim())) {
				return false;
			}
		}
		return true;
	}

	public static void waitInSeconds(int timeToWaitInSec) {
		try {
			Thread.sleep(timeToWaitInSec * 1000);
			logger.info("Hold Execution for " + timeToWaitInSec + " Secs");
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	public static void waitForElementToBeStable(WebElement webElement) {
		int count = 0;
		int maxTries = 20;
		while (true) {
			try {
				webElement.getSize();
			} catch (Throwable e) {
				waitInSeconds(1);
				logger.info("Retry for the Element");
				if (++count == maxTries)
					try {
						throw e;
					} catch (Throwable e1) {
						// TODO Auto-generated catch block
						e1.printStackTrace();
					}
			}
		}
	}

	// To handle NoSuch Element Exception
	public static void waitForVisibilityofElement(WebElement webelement) {

		webelement.isEnabled();
		new WebDriverWait(driver, 100).ignoring(RuntimeException.class)
				.until(ExpectedConditions.visibilityOf(webelement));

	}

	public static String getRandomNumber_Str(int end) {
		Random rand = new Random();
		int num = rand.nextInt(end);
		return Integer.toString(num); // Convert into String
	}

	// This function will return True if the ListElements contains Text
	// How to use it?
	public static boolean isTextExistInListElements(List<WebElement> webelements, String Text) {
		List<WebElement> links = webelements;
		for (int i = 0; i < links.size(); i++) {
			try {
				links.get(i).wait(200);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			// waitInSeconds(1);
			if (links.get(i).getText().trim().equals(Text)) {
				return true;
			}
		}
		return false;
	}

	// Enter text into web element
	public static void inputText(WebElement webElement, String inputtxt, String logmsg) {
		logger.info(logmsg + ":" + inputtxt);
		TestUtil.waitInSeconds(100);
		webElement.clear();
		webElement.sendKeys(inputtxt);
	}

	// Click a WebElement
	public static void clickElement(WebElement webElement, String logmsg) {
		logger.info(logmsg);
		webElement.click();
	}

	// Return Text for Attribute
	public static String verifyText(WebElement webElement) {
		return webElement.getText();

	}

	// Return Value for Attribute Specified
	public static String verifyAttribute(WebElement webElement, String attributename) {
		return webElement.getAttribute(attributename);

	}
}
