/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDDefineSearchController_Test.
* @Why   : ADDDefineSearchController_Test class for the ADDDefineSearchController class.
* @When  : 30-AUG-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                  Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-AUG-2018           Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 27-JUL-2020           Code Audit                      Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDDefineSearchController_Test {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){

        //String ticketReviewRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('RecurrenceSearch').getRecordTypeId();
        Ticket_Review__c tr = (Ticket_Review__c)TestDataFactory.createSObject(new Ticket_Review__c(FA_CAPA_Short_Description__c='test', CAPA_Number__c='test',Quality_Assignee_Name__c= UserInfo.getUserId(),
                                                   Search_Frequency__c ='Two Weeks (14 days)',Division__c='ADD',Status__c='Active', Medical_Assignee_Name__c = Userinfo.getUserId()), true);


        // Create Serach Criteria
        Search__c srch = (Search__c) TestDataFactory.createSObject(new Search__c(
        										Criteria__c  = 'Test',
        										Search_Criteria__c  = 'Ticket: pRE Status not equal to i',
        										Search_Description__c  = 'test',
            									Ticket_Review__c = tr.Id
        										), true);

    }

    /*
    * @Method       : testADDDefineSearchController.
    * @Description  : To test the ADDDefineSearchController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDDefineSearchController(){
        Ticket_Review__c tr = [SELECT id FROM Ticket_Review__c WHERE FA_CAPA_Short_Description__c='test' LIMIT 1];
        Search__c srch = [SELECT id FROM Search__c WHERE Ticket_Review__c = :tr.Id ];
        Test.startTest();
        PageReference statusReport = Page.ADDDefineSearch;
        statusReport.getParameters().put('id', srch.Id);
        statusReport.getParameters().put('tid', tr.Id);
        Test.setCurrentPage(statusReport);
        ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(srch);
        ADDDefineSearchController aDefine = new ADDDefineSearchController(sc1);
        System.assertEquals(true, aDefine.search!= null);

        Test.stopTest();

    }

    /*
    * @Method       : testADDDefineSearchController1.
    * @Description  : To test the ADDDefineSearchController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDDefineSearchController1(){
        Ticket_Review__c tr = [SELECT id FROM Ticket_Review__c WHERE FA_CAPA_Short_Description__c='test' LIMIT 1];
        Search__c srch = [SELECT id FROM Search__c WHERE Ticket_Review__c = :tr.Id ];
        Test.startTest();
        PageReference statusReport = Page.ADDDefineSearch;
        statusReport.getParameters().put('id', null);
        statusReport.getParameters().put('tid', tr.Id);
        Test.setCurrentPage(statusReport);
        ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(srch);
        ADDDefineSearchController aDefine = new ADDDefineSearchController(sc1);
        System.assertEquals(true, aDefine.search!= null);

        aDefine.save();
        aDefine.cancel();
        Test.stopTest();

    }
}