/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CustomerResponseTriggerTempHandlerTest.
* @Why   : CustomerResponseTriggerTempHandlerTest class for the CustomerResponseTriggerTempHandler.
* @When  : 24-AUG-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                24-AUG-2018            Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                30-APR-2020            Hotfix for IQ             Modified.
*                                             for defects deployment
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                10-JUN-2020            N/A                       Updated code part, which is related to Users' insertion.
*                                                                       This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                       error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                25-AUG-2020            Code Audit                Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class CustomerResponseTriggerTempHandlerTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup () {

        Id AspenUserProfileId = [SELECT Id
                                 FROM Profile
                                 WHERE Name = 'Aspen User'
                                 LIMIT 1].Id;

        List <Group> groups = [SELECT DeveloperName
                               FROM Group
                               WHERE DeveloperName = 'Quality_Complaint'
                               OR DeveloperName = 'Quality_non_Complaint'];

        //Create Users
        User usr1 = TestUtil.insertTestUser(
            AspenUserProfileId,
            'test@test.com',
            'testUsr1@test.com',
            'PEI3'
        );

        User usr2 = TestUtil.insertTestUser(
            AspenUserProfileId,
            'test@test.com',
            'testUsr2@test.com',
            'PEA2,PEA4'
        );

        //Adding groups membership
        List <GroupMember> usersGroupsMembership = new List <GroupMember> ();

        for (Group g : groups) {
            usersGroupsMembership.add(new GroupMember(
                GroupId = g.Id,
                UserOrGroupId = usr1.Id
            ));
            usersGroupsMembership.add(new GroupMember(
                GroupId = g.Id,
                UserOrGroupId = usr2.Id
            ));
        }

        insert usersGroupsMembership;

        insertData();
    }

    /*
    * @Method       : insertData.
    * @Description  : Asynchronously inserts data which will be used during testing.
    * @Invoke       : From setup method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @future
    public static void insertData () {

        //Get 'Complaint' record type of Ticket
        Id complaintRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName()
                                                                           .get('Complaint')
                                                                           .getRecordTypeId();

        //Get Users
        User usr1 = [SELECT Id
                     FROM User
                     WHERE UserName LIKE 'testUsr1@test.com%'
                     LIMIT 1];

        User usr2 = [SELECT Id
                     FROM User
                     WHERE UserName LIKE 'testUsr2@test.com%'
                     LIMIT 1];

        insert new ADD_App_Settings__c(Restrict_Validation_Rules__c = true);

        //Create Complaint
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(RecordTypeId = complaintRecTypeId),
            true);

        // Create Product Evaluation Investigation
        CMPL123CME__Investigation__c objInvestigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
            new CMPL123CME__Investigation__c(Name = 'Test',
                                             Product_Evaluation_Type__c = 'FUF',
                                             Additional_Action_Taken__c = 'No',
                                             Approver__c = usr1.Id,
                                             Assessor__c = usr1.Id,
                                             Conclusion_Disposition__c = '80068 Non-Medical Device, NO Product Problem',
                                             Conclusion_Summary__c = 'Test',
                                             Evaluator_Investigator__c = usr1.Id,
                                             CMPL123CME__Complaint__c =  objComplaint.Id),
            true);

        //Create Customer Responses
        Customer_Response__c objCustomerResponse = (Customer_Response__c) TestDataFactory.createSObject(
            new Customer_Response__c(Event__c = objComplaint.id,
                                     Customer_Reply__c = 'Test',
                                     Assign_To__c = usr1.Id,
                                     CMPL123_WF_Status__c = 'Opened'),
            true);

        Customer_Response__c objCustomerResponse1 = (Customer_Response__c) TestDataFactory.createSObject(
            new Customer_Response__c(Event__c = objComplaint.id,
                                     Customer_Reply__c = 'Test',
                                     Assign_To__c = usr2.Id,
                                     CMPL123_WF_Status__c = 'Opened'),
            true);

        //Create Attachments
        Attachment__c objAttachment = (Attachment__c) TestDataFactory.createSObject(
            new Attachment__c(Name = 'Test',
                              Attachment_Type__c = 'Customer Complaint Response',
                              Customer_Response__c = objCustomerResponse.id),
            true);

        //Create Workflow Statuses
        CMPL123__WF_Status__c  startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
            new CMPL123__WF_Status__c (Name = 'Pending Quality Approval'),
            true);

        CMPL123__WF_Status__c  endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
            new CMPL123__WF_Status__c (Name = 'Pending Quality Approval'),
            true);

        //Create Workflow Action
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
            new CMPL123__WF_Action__c  (Name = 'Process Team Approval'),
            true);

        //Create Workflow rule for Customer Response
        CMPL123__WF_Rule__c  responseProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
            new CMPL123__WF_Rule__c(CMPL123__Target_Object__c = 'Customer_Response__c(Inquiry_Customer_Response )',
                                    CMPL123__Record_Type__c  = 'Inquiry_Customer_Response',
                                    CMPL123__Is_Active__c  = true,
                                    CMPL123__Has_Multiple_Actions__c = true),
            true);

        //Create workflow step for Customer Response
        CMPL123__WF_Step__c assessProdStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
            new CMPL123__WF_Step__c(CMPL123__Start_Status__c = startStatus.Id,
                                    CMPL123__End_Status__c  = endStatus.Id,
                                    CMPL123__Action__c  = action.Id,
                                    CMPL123__Order__c = 1.0,
                                    CMPL123__WF_Rule__c = responseProdRule.Id),
            true);
    }

    /*
    * @Method       : afterUpdateEventHandler.
    * @Description  : Tests auto update of Send_to_CMSNext__c.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static testMethod void afterUpdateEventHandler () {

        //Get Users
        User usr1 = [SELECT Id
                     FROM User
                     WHERE UserName LIKE 'testUsr1@test.com%'
                     LIMIT 1];

        User usr2 = [SELECT Id
                     FROM User
                     WHERE UserName LIKE 'testUsr2@test.com%'
                     LIMIT 1];

        //Get CR for Usr1
        Customer_Response__c updateCustomerAction = [SELECT Id, CMPL123_WF_Status__c, Customer_Reply__c, Attachements__c
                                                     FROM Customer_Response__c
                                                     WHERE Assign_To__c =: usr1.Id
                                                     LIMIT 1];

        //Update CR for Usr2 as Usr2
        System.runAs(usr1) {
            updateCustomerAction.CMPL123_WF_Status__c = 'Closed-Done';
            update updateCustomerAction;
        }

        //Get CR for Usr2
        Customer_Response__c updateCustomerAction1 = [SELECT Id, CMPL123Task_Key_Value__c, CMPL123_WF_Status__c, Customer_Reply__c, Attachements__c
                                                      FROM Customer_Response__c
                                                      WHERE Assign_To__c =: usr2.Id
                                                      LIMIT 1];

        //Update CR for Usr2 as Usr2
        System.runAs(usr2) {
            updateCustomerAction1.CMPL123_WF_Status__c = 'Pending Quality Approval';
            updateCustomerAction1.Quality_Approver__c = usr1.Id;
            updateCustomerAction1.Additional_Approvals__c = 'Tech Approval';
            updateCustomerAction1.Additional_Approvals__c = 'Regulatory Approval';
            update updateCustomerAction1;
        }

        //Checking auto update
        Attachment__c attUpdateRec = [SELECT Id, Send_to_CMSNext__c
                                      FROM Attachment__c
                                      WHERE Name = 'Test'
                                      LIMIT 1];

        System.assertNotEquals(true, attUpdateRec.Send_to_CMSNext__c);
    }
}