Feature: Employee shall be able submit and view information online 
	Description: The purpose of this feature is to submit a form for identification
Background: User is on Home Page 
	Given User  is on home page 
	When click on FormsPage 
	Then  FormsPage gets opened 
Scenario: Employee should be able to submit a form 
	Then User clicks I9FormLink 
	Then  user can fill the form with name "sample_nm",alias_Name "aliasNm",date_of_birth "20071989" ,current_addr "1234"and status "Visa" 
	And user should be able to enter alienno "a1234" 
	Then click on submit button 

	
Scenario: Employee should be able to list all I9 Forms 
	Then User clicks listallI9FormsLink 
	Then all I9forms get displayed 

	
	
Scenario: Employee should be able to edit the form 
	Then User clicks FindI9FormPageLink 
	Then User enters formid "140" 
	And clicks on submit button 
	Then form details get displayed 
	Then click on formid to edit I9form 
	Then modify I9form and click on submit button 

	
Scenario: Employee should be able to view information 
	When User clicks infoLink 
	Then information poup gets opened 
	Then close the popup 
	Then close the browser 
		