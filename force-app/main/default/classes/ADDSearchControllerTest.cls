/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDSearchControllerTest.
* @Why   : ADDSearchControllerTest class for the ADDSearchController class.
* @When  : 23-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                23-OCT-2018            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oober                10-JUN-2020            N/A                           Updated code part, which is related to Users' insertion.
*                                                                           This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                           error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                13-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                07-SEP-2020           PMD report fixes          Added System.assert's.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
Private class ADDSearchControllerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){

        // Create Application Setup data
        CMPL123__CMPL_App_Config__c appConfig = (CMPL123__CMPL_App_Config__c)TestDataFactory.createSObject(new CMPL123__CMPL_App_Config__c(), true);
        //Create Meaningful Data Request records
        Meaningful_Data_Request__c meaningfulDataRequestobj = (Meaningful_Data_Request__c) TestDataFactory.createSObject(new Meaningful_Data_Request__c(), true);

        //Create User
        User u = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'test',
            Email = 'test@test.com',
            Username = 'test@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10'
        ), true);




    }

    /*
    * @Method       : searchMeaningfulDataRequest.
    * @Description  : To test search a record with criteria from MeaningfulDataRequest object.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void searchMeaningfulDataRequest(){
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