package com.unisys.verfuture.base;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Properties;
import java.util.concurrent.TimeUnit;

import org.apache.log4j.Logger;
import org.apache.log4j.PropertyConfigurator;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.sl.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
//import org.openqa.selenium.firefox.FirefoxDriver;
import org.openqa.selenium.support.events.EventFiringWebDriver;
import org.openqa.selenium.support.ui.WebDriverWait;

import io.github.bonigarcia.wdm.ChromeDriverManager;
import io.github.bonigarcia.wdm.WebDriverManager;
import com.unisys.verfuture.utilities.*;

public class TestBase {

	public static WebDriver driver;
	public static Properties prop;
	public static Logger logger;
	public static String TESTDATA_SHEET_PATH = "/testdata/FreeCrmTestData.xlsx";
	public	static Workbook book;

	public TestBase() {
		try {
			prop = new Properties();
			FileInputStream ip = new FileInputStream(
					System.getProperty("user.dir") + "/src/test/java" + "/com/unisys/verfuture/config/config.properties");
			prop.load(ip);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		logger = Logger.getLogger("LogDemo");
		PropertyConfigurator.configure("log4j.properties");
		//js = (JavascriptExecutor) driver;

	}

	public static void initialization()  {
		String browserName = prop.getProperty("browser");
		logger.info("=====Browser Session Started=====");

		if (browserName.equals("chrome")) {
			//WebDriverManager.chromedriver().setup();
			//driver = new ChromeDriver();
			DesiredCapabilities capabilities = DesiredCapabilities.chrome();
			capabilities.setCapability("maxInstances", "10");
			capabilities.setCapability("maxSessions", 5);
			try {
				driver = new RemoteWebDriver(new URL("http://hub:4444/wd/hub"),
				        capabilities);
				logger.info("After remote web driver initialization");
			} catch (MalformedURLException e) {
				e.printStackTrace();
				throw new RuntimeException(e);
			}
		} else if (browserName.equals("FF")) {
			WebDriverManager.firefoxdriver().setup();
			driver = new FirefoxDriver(); 
		}

		//driver.manage().window().maximize();
		driver.manage().deleteAllCookies();
		driver.manage().timeouts().pageLoadTimeout(TestUtil.PAGE_LOAD_TIMEOUT, TimeUnit.SECONDS);
		driver.manage().timeouts().implicitlyWait(TestUtil.IMPLICIT_WAIT, TimeUnit.SECONDS);


		driver.get(prop.getProperty("url"));
		logger.info("=====Application Started=====");
	}
	



}
