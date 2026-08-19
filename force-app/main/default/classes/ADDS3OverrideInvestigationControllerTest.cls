/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3OverrideInvestigationControllerTest.
* @Why   : ADDS3OverrideInvestigationControllerTest class for the ADDS3OverrideInvestigationController class.
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
private class ADDS3OverrideInvestigationControllerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
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
                        CMPL123_WF_Status__c = 'Open',
                        Product_Evaluation_Type__c = 'FUF',
                        Additional_Action_Taken__c = 'No',
                        Approver__c = user2.Id,
                        Assessor__c = user2.Id,
                        Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                        Conclusion_Summary__c = 'Test',
                        Evaluator_Investigator__c = user1.Id,
                        CMPL123CME__Complaint__c = complaint.Id
                ),
                true
        );
        Task__c investigationEvaluationTaskRecord = (Task__c) TestDataFactory.createSObject(
                new Task__c(
                        Related_Investigation_Evaluation__c = investigation.Id,
                        CMPL123Rule_Key_Value__c = 'Prod_Eval_Task',
                        Source_Leveraged__c = 'Leveraged'),
                true
        );
        insert new Task_Product_Evaluation_Investigation__c(
                Investigation_Evaluation__c = investigation.Id,
                Task__c = investigationEvaluationTaskRecord.Id
        );

    }

    /*
    * @Method       : test.
    * @Description  : To test the ADDS3OverrideInvestigationController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        Task_Product_Evaluation_Investigation__c taskProductEvaluationInvestigation = [
                SELECT Id
                FROM Task_Product_Evaluation_Investigation__c
                LIMIT 1
        ];
        ApexPages.currentPage().getParameters().put('ids', taskProductEvaluationInvestigation.Id);
        ApexPages.currentPage().getParameters().put('lksrch', 'Test');

        Test.startTest();
        ADDS3OverrideInvestigationController controller = new ADDS3OverrideInvestigationController();
        PageReference searchRef = controller.search();
        System.assertNotEquals(null, controller.results);
        PageReference overrideRef = controller.overrideInvestigation();
        Test.stopTest();

        System.assert(controller.isSuccess);
        System.assertEquals(null, searchRef);
        System.assertEquals(null, overrideRef);
    }
}