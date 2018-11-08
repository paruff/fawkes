package com.unisys.verfuture.stepdefinitions;

import static org.junit.Assert.assertTrue;

import org.junit.Assert;
import org.openqa.selenium.WebDriver;

import com.unisys.verfuture.base.TestBase;
import com.unisys.verfuture.cucumber.TestContext;
import com.unisys.verfuture.enums.Context;
import com.unisys.verfuture.pages.I9FormPage;
import com.unisys.verfuture.pages.ListAllI9FormsPage;
import com.unisys.verfuture.pages.PopUpPage;
import com.unisys.verfuture.pages.UpdateI9FormPage;
import com.unisys.verfuture.pages.FindI9FormPage;
import com.unisys.verfuture.pages.FormsPage;
//import com.unisys.verfuture.pages.ConfirmTipSubmissionPage;
//import com.unisys.verfuture.pages.FindTipPage;
//import com.unisys.verfuture.pages.FormsPage;
import com.unisys.verfuture.pages.HomePage;
import com.unisys.verfuture.pages.confirmationPage;
import com.unisys.verfuture.utilities.TestUtil;

import cucumber.api.java.After;
//import com.unisys.verfuture.pages.LoginPage;
//import com.unisys.myuscis.pages.LoginPage;
//import com.unisys.verfuture.pages.SubmitEB5TipPage;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.api.java.en.When;

/**
 * Step Definitions for Project
 * 
 * @author DONTHISR
 *
 */
public class UIStepDef extends TestBase {
	// static String id;
	WebDriver driver;
	String formId;
	static String Id;
	TestContext testContext;

	public UIStepDef(TestContext context) {
		TestBase.initialization();
		driver = TestBase.driver;
		testContext = context;

	}

	HomePage HP;
	FormsPage FP;
	I9FormPage IFP;
	FindI9FormPage FIFP;
	confirmationPage CP;
	


	@Given("^User  is on home page$")
	public void user_is_on_home_page() throws Throwable {
		HP = new HomePage(driver);
		String Homepagetitle = HP.verifyHomePageTitle();
		System.out.println("user is on homepage  " + Homepagetitle);

	}

	@When("^click on FormsPage$")
	public void click_on_FormsPage() throws Throwable {
		FP = new FormsPage(driver);
		FP = HP.clickOnFormsDropDwnLink();
	}

	@Then("^FormsPage gets opened$")
	public void formspage_gets_opened() throws Throwable {
		String fptitle = FP.verifyFormsPageTitle();
		System.out.println("forms page title is:" + fptitle);
	}

	@Then("^User clicks I(\\d+)FormLink$")
	public void user_clicks_I_FormLink(int arg1) throws Throwable {
		IFP = new I9FormPage(driver);
		IFP = FP.clickOni9FormLink();
	}

	// @Then("^user can fill the form with name \"([^\"]*)\",alias_Name(\\d+)
	// \"([^\"]*)\",date_of_birth \"([^\"]*)\" ,current_addr \"([^\"]*)\"and status
	// \"([^\"]*)\"$")
	// public void
	// user_can_fill_the_form_with_name_alias_Name_date_of_birth_current_addr_and_status(String
	// arg1, int arg2, String arg3, String arg4, String arg5, String arg6) throws
	// Throwable {
	// // Write code here that turns the phrase above into concrete actions

	@Then("^user can fill the form with name \"([^\"]*)\",alias_Name \"([^\"]*)\",date_of_birth \"([^\"]*)\" ,current_addr \"([^\"]*)\"and status \"([^\"]*)\"$")
	public void user_can_fill_the_form_with_name_alias_Name_date_of_birth_current_addr_and_status(String nm,
			String alias, String dob, String addr, String status) throws Throwable {

		IFP.fillformWithDetails(nm, alias, dob, addr, status);
	}

	@Then("^user should be able to enter alienno \"([^\"]*)\"$")
	public void user_should_be_able_to_enter_alienno(String alienno) throws Throwable {
		// IFP.inputAlienno(alienno);
	}

	@Then("^click on submit button$")
	public void click_on_submit_button() throws Throwable {
		CP = new confirmationPage(driver);
		CP = IFP.clickOnSubmit();
		Thread.sleep(1800);
		String confirmText = CP.getConfirmText();
		System.out.println("Confirmaton Page Title is:" + confirmText);
		Thread.sleep(500);
		String formId = CP.getFormId();
		// testContext.scenarioContext.setContext(Context.form_Id, formId);
		// Id = formId;
		// formId =
		// (String)testContext.scenarioContext.getContext(Context.PRODUCT_NAME);
		// // assertTrue(confirmText.contains("Your Form Has Been Submitted"));
		// formId = confirmText.substring(42);
		// System.out.println("Form Id is:" + formId);
	}

	@Then("^User clicks listallI(\\d+)FormsLink$")
	public void user_clicks_listallI_FormsLink(int arg1) throws Throwable {
		LIFP = new ListAllI9FormsPage(driver);
		LIFP = FP.clickOnlistAllI9FormsLink();
	}

	@Then("^all I(\\d+)forms get displayed$")
	public void all_I_forms_get_displayed(int arg1) throws Throwable {
		Thread.sleep(5000);
		String listallI9Title = LIFP.verifyListAllI9FormsPageTitle();
		System.out.println("List All I9forms Page Title is: " + listallI9Title);
	}

	@Then("^User clicks FindI(\\d+)FormPageLink$")
	public void user_clicks_FindI_FormPageLink(int arg1) throws Throwable {
		FIFP = new FindI9FormPage(driver);
		FIFP = FP.clickOnFindI9FormLink();
	}

	@Then("^User enters formid \"([^\"]*)\"$")
	public void user_enters_formid(String arg1) throws Throwable {
		// FIFP.refreshPage();
		// String id = (String) testContext.scenarioContext.getContext(Context.form_Id);
		// id = Id;
		FIFP.inputFindbyformId(arg1);

	}

	@Then("^form details get displayed$")
	public void form_details_get_displayed() throws Throwable {
		String foundTitle = FIFP.foundId();
		System.out.println("found title is:" + foundTitle);
	}

	@Then("^clicks on submit button$")
	public void clicks_on_submit_button() throws Throwable {
		Thread.sleep(1000);
		FIFP.clickOnSubmit();

	}

	@Then("^click on formid to edit I(\\d+)form$")
	public void click_on_formid_to_edit_I_form(int arg1) throws Throwable {
		FIFP.clickOnidLink();
		Thread.sleep(1000);
	}

	@Then("^modify I(\\d+)form and click on submit button$")
	public void modify_I_form_and_click_on_submit_button(int arg1) throws Throwable {
		UIFP = new UpdateI9FormPage(driver);
		UIFP.fillformWithDetails();
		CP = UIFP.clickOnSubmit();
		Thread.sleep(500);
		String confirmText = CP.getConfirmText();
		System.out.println("Confirmaton Page Title is:" + confirmText);
	}

	@When("^User clicks infoLink$")
	public void user_clicks_infoLink() throws Throwable {
		PP = new PopUpPage(driver);
		PP = HP.clickonInfoLink();
	}

	@Then("^information poup gets opened$")
	public void information_poup_gets_opened() throws Throwable {
		Thread.sleep(500);
		String popupTitle = PP.getConfirmText();
		System.out.println("popup page title is:" + popupTitle);
	}

	@Then("^close the popup$")
	public void close_the_popup() throws Throwable {
		Thread.sleep(500);
		PP.clickonCloseBtn();
	}

	@Then("^close the browser$")
	public void close_the_browser() throws Throwable {
		driver.close();
	}

}
