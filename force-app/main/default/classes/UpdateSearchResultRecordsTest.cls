/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateSearchResultRecordsTest.
* @Why   : To test functionality of UpdateSearchResultRecords class.
* @When  : 27-DEC-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  27-DEC-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                                   deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class UpdateSearchResultRecordsTest {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup static void setupData() {
        //Setting default custom settings
        ADD_App_Settings__c appSetting = new ADD_App_Settings__c();
        appSetting.Restrict_Workflow_Updates__c = false;
        appSetting.Name = 'User';
        appSetting.Restrict_Triggers__c = false;
        appSetting.Restrict_Validation_Rules__c = true;
        insert appSetting;

        // Create User
        TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id ,
            Alias = 'add' ,
            Email = 'standarduser@test.com' ,
            EmailEncodingKey = 'UTF-8' ,
            LastName = 'add translation_coordinator123' ,
            LanguageLocaleKey = 'en_US' ,
            LocaleSidKey = 'en_US' ,
            TimeZoneSidKey = 'America/Los_Angeles' ,
            Username = 'testaspen@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10),
            Belongs_to_Text__c = 'RA16',
            Is_ooo__c = false
        ), true);
    }


    /*
    * @Method       : updateSearchResultRecords.
    * @Description  : To test UpdateSearchResultRecords.updateSearchResultRecords method functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void updateSearchResultRecords() {
        Test.startTest();
        Ticket_Review__c objTicketReview = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        Status__c = 'Active'
                ), true);
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Ticket_Type__c = 'Inquiry',
                        Customer_Reply_Required__c = true
                ), true);

        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                new Ticket_Search_Result__c(
                        Ticket_Review__c = objTicketReview.Id,
                        Unique_Identifier__c = objTicketReview.Id + '-' + objComplaint.Id,
                        Ticket_Review_Status__c = 'Related with no Malfunction',
                        Ticket__c = objComplaint.Id
                ), false);
        UpdateSearchResultRecords updateSearchResRecs = new UpdateSearchResultRecords(new List<Ticket_Search_Result__c>{
                objTicketSearchResult
        });
        System.enqueueJob(updateSearchResRecs);
        Test.stopTest();
        Ticket_Search_Result__c objTicketSearchResultUpdated = [
                SELECT Ticket_Review_Status__c
                FROM Ticket_Search_Result__c
                WHERE Ticket_Review__c =: objTicketReview.Id
        ];
        System.assertEquals('Related with no Malfunction', objTicketSearchResultUpdated.Ticket_Review_Status__c);
    }
}