/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateTaskActionRelatedFieldsTest.
* @Why   : To test functionality of Task__c object.
* @When  : 28-SEP-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  28-SEP-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  10-JUN-2020            Code Audit                      Updated code part, which is related to Users' insertion.
*                                                                               This change designed to prevent a 'DUPLICATE_USERNAME' 
*                                                                               error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                  07-SEP-2020            Code Audit                      Added assertEquals to updateTaskActionRelatedFieldsTestMethod.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class UpdateTaskActionRelatedFieldsTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Aspen User'];

        User u = (User) TestDataFactory.createSObject(new User(
                Alias = 'standt',
                Email = 'raj@test.com',
                Belongs_to_Text__c = 'PEA2',
                Is_ooo__c = False,
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing1234231',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'hiii12@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        User u1 = (User) TestDataFactory.createSObject(new User(
                Alias = 'standt',
                Email = 'raj@test.com',
                Belongs_to_Text__c = 'PEI3',
                Is_ooo__c = False,
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing1234',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'hiii@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        User u2 = (User) TestDataFactory.createSObject(new User(
                Alias = 'standt',
                Email = 'raj@test.com',
                Belongs_to_Text__c = 'PEA4',
                Is_ooo__c = False,
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing123477',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'hiii23@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                Ticket_Type__c = 'Complaint',
                Is_Product_Evaluation_Investigation_chil__c = false,
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMSNext_Ticket_Number__c = '123456'
        ), true);

        CMPL123CME__Investigation__c objInvestigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        Assessor__c = u.Id,
                        Evaluator_Investigator__c = u1.Id,
                        Conclusion_Summary__c = 'Test',
                        //objInvestigation.Conclusion_Disposition__c = '80064 NO Deficiency, Malfunction';
                        Product_Evaluation_Type__c = 'Lot to lot variability',
                        Approver__c = u2.Id,
                        Additional_Action_Taken__c = 'No',
                        Close_to_Threshold__c = 'Yes',
                        Prod_Eval_Returns_to_be_Requested__c = 'No',
                        Not_Requested_Rationale__c = 'Test'
                ), true);

        Task__c task = (Task__c) TestDataFactory.createSObject(new Task__c(
                Assignee_Name__c = UserInfo.getUserId(),
                Task_Item_Approved_By__c = 'Test 123',
                Comments__c = 'Testing',
                Related_Investigation_Evaluation__c = objInvestigation.Id
        ), true);
    }

    /*
    * @Method       : updateTaskActionRelatedFieldsTestMethod.
    * @Description  : To test the ComplaintReport Vf page functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    private static void updateTaskActionRelatedFieldsTestMethod() {
        Task__c tasks = [SELECT Task_Item_Approved_By__c, CMPL123_WF_Action__c, Comments__c FROM Task__c LIMIT 1];
        tasks.Comments__c = 'Testing';
        upsert tasks;

        System.assertEquals('Testing', tasks.Comments__c, 'Task comment should be updated');
    }
}