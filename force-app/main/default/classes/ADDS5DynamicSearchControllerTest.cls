/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS5DynamicSearchControllerTest.
* @Why   : ADDS5DynamicSearchControllerTest class for the ADDS5DynamicSearchController class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                13-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                07-SEP-2020           PMD report fixes          Added System.assert's.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class ADDS5DynamicSearchControllerTest{

static testmethod void dynamicSearchControllerTestMethod(){    
  	Test.startTest();
    Ticket_Review__c ticketReview = (Ticket_Review__c) TestDataFactory.createSObject(new Ticket_Review__c(
            Status__c = 'Active'), true);
	ApexPages.currentPage().getParameters().put('Id',ticketReview.Id);
	Search__c search = (Search__c) TestDataFactory.createSObject(new Search__c(
    Ticket_Review__c = ticketReview.Id,
    Criteria__c ='(Product-Ticket: Product List / Part Number equals %)',
    Search_Criteria__c = ''), false);
	search.Ticket_Review__c = ticketReview.Id;
	insert search;

	ADDS5DynamicSearchController.fetchQueryResults();
    Test.stopTest();
}
static testmethod void dynamicSearchControllerTest(){
Test.startTest();
ADDS5DynamicSearchController.fetchQueryResults();
//Ticket_Review__c ticketReview = ADDTestDataCreation.returnTicketReview();
//insert ticketReview;
Ticket_Review__c ticketReview = (Ticket_Review__c) TestDataFactory.createSObject(new Ticket_Review__c(
            Status__c = 'Active'), true);
ApexPages.currentPage().getParameters().put('Id',ticketReview.Id);
//Search__c search = ADDTestDataCreation.returnSearch();
Search__c search = (Search__c) TestDataFactory.createSObject(new Search__c(
    Ticket_Review__c = ticketReview.Id,
    Criteria__c ='(Product - Ticket: Product List Number contains in 01L86-01) AND (Ticket: Ticket Type contains in Inquiry)',
    Search_Criteria__c = '{"Product_Ticket__c":[{"fieldLabel":"Product List Number","fieldAPIName":"Product_List_Number__c ","datatype":"STRING","operator":"contains in","operatorSign":"IN","value":"01L86-01","sequenceNumber":"1"},{"objectAPIName":"Product_Ticket__c","objectLabel":"Product - Ticket","relationshipName":"Products_Events__r","relatedTicketFieldAPI":"Event_Ticket__c","logic":"1"}],"CMPL123CME__Complaint__c":[{"fieldLabel":"Ticket Type","fieldAPIName":"Ticket_Type__c","datatype":"PICKLIST","operator":"contains in","operatorSign":"IN","value":"Inquiry","sequenceNumber":"1"},{"objectAPIName":"CMPL123CME__Complaint__c","objectLabel":"Ticket","relationshipName":"null","relatedTicketFieldAPI":"null","logic":"1"}]}'), false);
search.Ticket_Review__c = ticketReview.Id;
insert search;
ADDS5DynamicSearchController.fetchQueryResults();
Test.StopTest();
}

    /*
    * @Method       : setupData.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup static void setupData() {

        // Create Application Setup data
        CMPL123__CMPL_App_Config__c appConfig = (CMPL123__CMPL_App_Config__c) TestDataFactory.createSObject(new CMPL123__CMPL_App_Config__c(), true);

        //Create Complaint
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',Customer_Reply_Required__c = true), true);


        //Create Customer Response
        Ticket_Review__c objTicketReview = (Ticket_Review__c) TestDataFactory.createSObject(new Ticket_Review__c(
            Status__c = 'Active'), true);

        //Create Search Record
        Search__c objSearch = (Search__c) TestDataFactory.createSObject(new Search__c(
                                Ticket_Review__c = objTicketReview.Id,
                                Criteria__c ='(Product - Ticket: Product List Number contains in 01L86-01) AND (Ticket: Ticket Type contains in Inquiry)',
                                Search_Criteria__c = '{"Product_Ticket__c":[{"fieldLabel":"Product List Number","fieldAPIName":"Product_List_Number__c ","datatype":"STRING","operator":"contains in","operatorSign":"IN","value":"01L86-01","sequenceNumber":"1"},{"objectAPIName":"Product_Ticket__c","objectLabel":"Product - Ticket","relationshipName":"Products_Events__r","relatedTicketFieldAPI":"Event_Ticket__c","logic":"1"}],"CMPL123CME__Complaint__c":[{"fieldLabel":"Ticket Type","fieldAPIName":"Ticket_Type__c","datatype":"PICKLIST","operator":"contains in","operatorSign":"IN","value":"Inquiry","sequenceNumber":"1"},{"objectAPIName":"CMPL123CME__Complaint__c","objectLabel":"Ticket","relationshipName":"null","relatedTicketFieldAPI":"null","logic":"1"}]}'),true);

        Ticket_Review__c objTicketReview1 = (Ticket_Review__c) TestDataFactory.createSObject(new Ticket_Review__c(
            Status__c = 'Active'), true);

        //Create Search Record
        Search__c objSearch1 = (Search__c) TestDataFactory.createSObject(new Search__c(
                                Ticket_Review__c = objTicketReview1.Id),true);



        // Create Ticket Search Result
        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(new Ticket_Search_Result__c(
            Ticket_Review__c = objTicketReview.Id,Unique_Identifier__c = objTicketReview.Id+'-'+objComplaint.Id, Ticket_Review_Status__c = 'Related with Malfunction', Ticket__c = objComplaint.Id), true);
        
        
        //Lakshman-start
        //Create Country
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(), true);
        //Create Submission Type
        Country_Submission_Type__c submissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
            Name = '30 Days', 
            Calendar_Days__c = 30, 
            Country__c = objCountry.Id
        ), true);
        //Create Registered Site
        CMPL123CME__Registered_Site__c regSite = (CMPL123CME__Registered_Site__c) TestDataFactory.createSObject(new CMPL123CME__Registered_Site__c(
            CMPL123CME__G1_Contact_Office_Region_State__c = 'NA', 
            Division__c = 'ADD'
        ),true);

        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdrTest = new CMPL123CME__EMDR__c(
            RecordTypeId = initialRTId,
            CMPL123CME__CMPL123_WF_Action__c = 'Open',
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id,
            CMPL123CME__MDR_Due_Date__c = Date.newInstance(2016, 12, 8),
            CMPL123CME__Registered_Site__c = [SELECT Id FROM CMPL123CME__Registered_Site__c LIMIT 1].Id,
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
            CMPL123CME__D10_Concomitant_Product_Null__c = 'NI',
            Ticket_Review__c = objTicketReview.id,
            CMPL123CME__G3_Date_received_by_Mfg__c = System.today()
            //CMPL123CME__Complaint__c = objComplaint.id
        );
        insert emdrTest;
        //Create MDI
        CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c = '123',
                List_Number__c = '12345'
            ), true);

            Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = product.Id,
                Event_Ticket__c = objComplaint.Id,
                Batch_Lot_Serial__c = '1235'
            ), true);

            CMPL123CME__Questionnaire__c assessment = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                CMPL123CME__Complaint__c = objComplaint.Id,
                RecordTypeId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId(),
                CMPL123_WF_Status__c = 'Regulatory',
                Reportability_Rationale__c = 'Test',
                Reportability__c = 'Non-Reportable',
                Reportability_Category__c = 'Adverse Event',
                Initial_Awareness_Date__c = Date.newInstance(2018, 05, 07),
                Submitted_Date__c = Date.newInstance(2018, 05, 07)
            ), true);

            Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(new Country_Submission_Type__c(
                Name = '30 Days',
                Calendar_Days__c = 30,
                Country__c = objCountry.Id
            ), true);

            TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
                Medical_Evaluation__c = assessment.Id,
                Country__c = objCountry.Id,
                Product__c = prodTckt.Id,
                CMPL123CME__Complaint__c = objComplaint.Id,
                CMPL123_WF_Status__c = 'Opened',
                Action_on_Follow_Up_Awareness_Date__c = 'Set to Blank',
                CMPL123CME__Manufacturer_Device_Analysis_Results__c = 'test',
                Submission_Type__c = objCountrySubmissionType.Id
            ), true);
        //Lakshman-End
        
    }

    /*
    * @Method       : customValidationTest.
    * @Description  : To test CustomValidation method in CustomerResponseCustExpectMDCCustom class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void customValidationTest() {

        Ticket_Review__c objCustomerResponse = [SELECT Id FROM Ticket_Review__c LIMIT 1];
        //Update Customer_Expectation__c field
        //     objCustomerResponse. = 'CustomerExpectation New';
        TestDataFactory.updateSObject(objCustomerResponse);
        //PMD report fix for System assert start.
        objCustomerResponse = [SELECT Id, CreatedDate, LastModifiedDate FROM Ticket_Review__c LIMIT 1];
        System.assertNotEquals(objCustomerResponse.CreatedDate, objCustomerResponse.LastModifiedDate);
        //PMD report fix for System assert end.
    }

    /*
    * @Method       : checkInactiveTicketReview.
    * @Description  : To test the ADDS5DynamicSearchController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod void checkInactiveTicketReview(){

        Test.startTest();
        //Get Ticket Review
        List<Ticket_Review__c> objTicketReview = [SELECT Id,Status__c FROM Ticket_Review__c WHERE Status__c = 'Active'];

        PageReference searchPage = Page.ADDS5DynamicSearch;
        searchPage.getParameters().put('id', objTicketReview[0].id);
        Test.setCurrentPage(searchPage);
        ADDS5DynamicSearchController.fetchQueryResults();

        PageReference searchPage1 = Page.ADDS5DynamicSearch;
        searchPage1.getParameters().put('id', objTicketReview[1].id);
        Test.setCurrentPage(searchPage1);
        ADDS5DynamicSearchController.fetchQueryResults();
        ADDS5DynamicSearchController.inClausify(New List<String>{'Ticket_Review__c !=null'});
        //Query Search
        Search__c searchQ = [SELECT Id, Criteria__c FROM Search__c LIMIT 1];
        searchQ.Criteria__c = '(Product - Ticket: Product List Number contains in 01L86-01)';
        TestDataFactory.updateSObject(searchQ);
        //Get Ticket Review
        List<Ticket_Review__c> objTicketR = [SELECT Id,Status__c FROM Ticket_Review__c WHERE Status__c = 'Active'];

        PageReference searchPg = Page.ADDS5DynamicSearch;
        searchPg.getParameters().put('id', objTicketR[0].id);
        Test.setCurrentPage(searchPg);
        ADDS5DynamicSearchController.fetchQueryResults();

        PageReference searchPg1 = Page.ADDS5DynamicSearch;
        searchPg1.getParameters().put('id', objTicketR[1].id);
        Test.setCurrentPage(searchPg1);
        ADDS5DynamicSearchController.fetchQueryResults();

        //Get Search Results


        //Query Ticket Search Result
       Ticket_Search_Result__c ticketSearchResult = [SELECT Id, Ticket_Review__c, Ticket_Review_Status__c
                                                      FROM Ticket_Search_Result__c WHERE Ticket_Review_Status__c = 'Related with Malfunction' LIMIT 1];
        Ticket_Search_Result__c res = ADDS5DynamicSearchController.processComplaintAndChildsData(
            [SELECT Id, Was_an_Adverse_Event_Identified__c,Ticket_Type__c,(SELECT Id, Name FROM Products_Events__r) FROM CMPL123CME__Complaint__c LIMIT 1]);
            Ticket_Search_Result__c res1 = ADDS5DynamicSearchController.createTicketSearchResult(
            [SELECT Id, Was_an_Adverse_Event_Identified__c,Ticket_Type__c,(SELECT Id, Name FROM Products_Events__r) FROM CMPL123CME__Complaint__c LIMIT 1]);
            string str = ADDS5DynamicSearchController.createComplaintAndChildsQuery(new Map<Id, CMPL123CME__Complaint__c>([SELECT Id FROM CMPL123CME__Complaint__c]).keySet());
       
        objTicketReview[0].Status__c = 'Inactive';
        UPDATE objTicketReview[0];

        objTicketReview[1].Status__c = 'Inactive';
        UPDATE objTicketReview[1];

        PageReference searchPage2 = Page.ADDS5DynamicSearch;
        searchPage2.getParameters().put('id', objTicketReview[0].id);
        Test.setCurrentPage(searchPage2);
        ADDS5DynamicSearchController.fetchQueryResults();

        searchPage2.getParameters().put('id', objTicketReview[1].id);
        Test.setCurrentPage(searchPage2);
        ADDS5DynamicSearchController.fetchQueryResults();

        //Lakshman-Start
        ApexPages.currentPage().getParameters().put('id', objTicketReview[0].Id);
        ADDS5DynamicSearchController controller = new ADDS5DynamicSearchController();
        ADDS5DynamicSearchController.childQueriesSet = new Set<String> {'SELECT Id FROM Ticket_Review__c'};
        ADDS5DynamicSearchController.childObjectAPINameAndQueryMap = new Map<String, String>();
        ADDS5DynamicSearchController.childObjectAPIAndTicketFieldMap = new Map<String, String>();
        //Lakshman-End

        Test.stopTest();
        //PMD report fix for System assert start.
        System.assertEquals(2, [SELECT count() FROM Search_Log__c], 'Should be created on fetchQueryResult method');
        //PMD report fix for System assert end.
        
    }

    /*
    * @Method       : searchMeaningfulDataRequest.
    * @Description  : To test the record search with criteria from Meaningful Data Request object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod void searchMeaningfulDataRequest(){
        ADDSearchController addSearchControllerObj = new ADDSearchController();
        addSearchControllerObj.selectedFields = 'Ad_hoc_Evaluator_Investigator_MDC__c;Ad hoc Evaluator/Investigator MDC,';
        addSearchControllerObj.fieldDetailJSON = '{"Meaningful_Data_Request__c":[{"fieldLabel":"Request Type","fieldAPIName":"Request_Type__c","datatype":"PICKLIST","operator":"contains in","operatorSign":"IN","value":"Customer Request","sequenceNumber":"1"},{"objectAPIName":"Meaningful_Data_Request__c","objectLabel":"Meaningful Data Request","relationshipName":"Meaningful_Data_Requests__r","relatedTicketFieldAPI":"Ticket__c","logic":"1"}]}';
        addSearchControllerObj.objectDetailJSON = '{"Meaningful_Data_Request__c":"Ticket__c"}';
        ADDSearchController.getFieldDetails('Meaningful_Data_Request__c');
        addSearchControllerObj.fetchResults();
        
        //PMD report fix for System assert start. This method should be refactored.
        System.assertEquals(0, addSearchControllerObj.complaints.size(), 'Should return 0 complaints on fetch');
        //PMD report fix for System assert end.
    }

}