/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3_LeveragedTicketListControllerTest.
* @Why   : ADDS3_LeveragedTicketListControllerTest class for the ADDS3_LeveragedTicketListController class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak    	       10-JUN-2020	     N/A                         Updated code part, which is related to Users' insertion.
*                                                                        This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                        deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                12-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ADDS3_LeveragedTicketListControllerTest {
    /*
    * @Method       : addReviewFileTranslationControllerTest.
    * @Description  : To test the ADDS3_LeveragedTicketListController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;

        User user1 = (User) TestDataFactory.createSObject(new User(
                ProfileId = aspenUserProfileId,
                LastName = 'test',
                Email = 'test@test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'PEI3',
                Username = 'test@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        User user2 = (User) TestDataFactory.createSObject(new User(
                ProfileId = aspenUserProfileId,
                LastName = 'last',
                Email = 'test@test.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'PEA2,PEA4',
                Username = 'test@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        Id complaintRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(RecordTypeId = complaintRecTypeId),
                true
        );
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        Name = 'Test',
                        CMPL123_WF_Status__c = 'Opened',
                        Product_Evaluation_Type__c = 'FUF',
                        Additional_Action_Taken__c = 'No',
                        Approver__c = user2.Id,
                        Assessor__c = user2.Id,
                        Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                        Conclusion_Summary__c = 'Test',
                        Evaluator_Investigator__c = user1.Id,
                        CMPL123CME__Complaint__c = complaint.Id),
                true
        );
        Ticket_Product_Evaluation_Investigation__c ticketProductEvaluationInvestigation = new Ticket_Product_Evaluation_Investigation__c(
                Investigation_Evaluation__c = investigation.Id,
                Ticket__c = complaint.Id
        );
        insert ticketProductEvaluationInvestigation;
        ApexPages.currentPage().getParameters().put('Id', investigation.Id);

        Test.startTest();
        ADDS3_LeveragedTicketListController controller = new ADDS3_LeveragedTicketListController(
                new ApexPages.StandardController(investigation)
        );
        Test.stopTest();

        System.assertNotEquals(null, controller.investigationChildren);
        Map<Id, Ticket_Product_Evaluation_Investigation__c> results = new Map<Id, Ticket_Product_Evaluation_Investigation__c>(controller.investigationChildren);
        System.assert(results.containsKey(ticketProductEvaluationInvestigation.Id));
    }
}