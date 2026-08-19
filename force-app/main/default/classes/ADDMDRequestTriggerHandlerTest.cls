/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDMDRequestTriggerHandlerTest.
* @Why   : ADDMDRequestTriggerHandlerTest class for the ADDMDRequestTriggerHandler class.
* @When  : 31-AUG-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                31-AUG-2018           Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                10-JUN-2020           N/A                       Updated code part, which is related to Users' insertion.
*                                                                      This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                      error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                30-JUL-2020           Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class ADDMDRequestTriggerHandlerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup static void setup() {
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        TestDataFactory.createSObject(new Meaningful_Data_Request__c(
            Request_Type__c = 'CSS Request',
            Question_Action__c = 'test?'
        ), true);
    }

    /*
    * @Method       : testADDHazardAssessmentTriggerHandler.
    * @Description  : To test the ADDMDRequestTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void testADDHazardAssessmentTriggerHandler() {
        Meaningful_Data_Request__c mdr = [SELECT Id FROM Meaningful_Data_Request__c WHERE Request_Type__c = 'CSS Request'];

        mdr.Attempt_1_Date__c = System.today();

        upsert mdr;

        System.assertEquals(
            System.today(),
            [SELECT Id, Attempt_1_Date__c FROM Meaningful_Data_Request__c WHERE Request_Type__c = 'CSS Request'].Attempt_1_Date__c
        );

        delete mdr;

        System.assertEquals(
            new List<Meaningful_Data_Request__c>(),
            [SELECT Id, Attempt_1_Date__c FROM Meaningful_Data_Request__c WHERE Request_Type__c = 'CSS Request']
        );
    }

    /*
    * @Method       : completeMRDTest.
    * @Description  : To test [CR] 1668.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void completeMRDTest() {
        List<User> users = new List<User>();
        Id AspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;

        for (Integer i = 0; i < 6; i++) {
            users.add(new User(
                ProfileId = AspenUserProfileId,
                LastName = 'user',
                Email = 'test' + i + '@' + i + 'te' + i + 'st.com',
                Username = 'test' + i + '@' + i + 'te' + i + 'st.com'
                + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'TEST',
                Title = 'test',
                Alias = 'test',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
            ));
        }

        insert users;

        List<PermissionSet> permSets = [SELECT Id FROM PermissionSet
                                            WHERE Name = 'Complaint_Assessor'
                                                OR Name = 'Quality_non_Complaint'
                                                OR Name = 'Evaluation_Investigation_Task_Assignee'
                                                OR Name = 'Return_Coordinator'
                                                OR Name = 'Ticket_Review_Medical_Assignee'
                                                OR Name = 'Ticket_Review_Quality_Assignee'];

        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();

        for (Integer i = 0; i < 6; i++) {
            permSetAssignments.add(new PermissionSetAssignment(
                PermissionSetId = permSets[i].Id,
                AssigneeId = users[i].Id
            ));
        }

        insert permSetAssignments;

        User validUser = TestUtil.insertTestUser(
            AspenUserProfileId,
            'aspenValidUserTest@test.com',
            'aspenValidUserTest@test.com'
        );

        insert new PermissionSetAssignment(
            PermissionSetId = permSets[0].Id,
            AssigneeId = validUser.Id
        );

        Meaningful_Data_Request__c mdr = null;

        System.runAs(users[0]) {
            mdr = new Meaningful_Data_Request__c(
                Request_Type__c = 'CSS Request',
                Question_Action__c = 'test?2'
            );

            insert mdr;
        }

        System.runAs(validUser) {
            mdr.Request_Status__c = 'Opened';
            mdr.Answer_No_Answer_Rationale__c = 'test1';

            update mdr;

            System.assertEquals(
                mdr.Request_Status__c,
                [SELECT Request_Status__c FROM Meaningful_Data_Request__c WHERE Id =: mdr.Id].Request_Status__c
            );
        }

        System.runAs(users[1]) {
            mdr.Request_Status__c = 'Completed';
            mdr.Answer_No_Answer_Rationale__c = 'test';

            try {
            	update mdr;
            } catch (DMLException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
                System.assertEquals(System.Label.Status_Is_Not_Changeable , e.getDmlMessage(0));
            }
        }

        System.runAs(users[2]) {
            mdr.Request_Status__c = 'Voided';

            try {
                update mdr;
            } catch (DMLException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
                System.assertEquals(System.Label.Status_Is_Not_Changeable , e.getDmlMessage(0));
            }
        }

        System.runAs(users[3]) {
            mdr.Request_Status__c = 'Opened';

            try {
                update mdr;
            } catch (DMLException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
                System.assertEquals(System.Label.Status_Is_Not_Changeable , e.getDmlMessage(0));
            }
        }

        System.runAs(users[4]) {
            mdr.Request_Status__c = 'Completed';

            try {
                update mdr;
            } catch (DMLException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
                System.assertEquals(System.Label.Status_Is_Not_Changeable , e.getDmlMessage(0));
            }
        }

        System.runAs(users[5]) {
            mdr.Request_Status__c = 'Voided';

            try {
                update mdr;
            } catch (DMLException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
                System.assertEquals(System.Label.Status_Is_Not_Changeable , e.getDmlMessage(0));
            }
        }
    }

    /*
    * @Method       : checkUserPermSetTest.
    * @Description  : To test users' permission sets.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void checkUserPermSetTest() {
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

        User adminUser = TestUtil.insertTestUser(
            adminProfileId,
            'admin_test73@test.com',
            'admin_test73@test.com'
        );

        User userToCreate = TestUtil.insertTestUser(
            AspenUserProfileId,
            'creator93Test@test.com',
            'creator93Test@test.com'
        );

        User userWithPermSet = TestUtil.insertTestUser(
            AspenUserProfileId,
            'aspen97_user@test.com',
            'aspen97_user@test.com'
        );

        User userWithoutPermSet = TestUtil.insertTestUser(
            AspenUserProfileId,
            'aspen9_User@test.com',
            'aspen9_User@test.com'
        );

        System.runAs(adminUser) {
            Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Complaint_Evaluator_Investigator'].Id;

            insert new PermissionSetAssignment(AssigneeId = userToCreate.Id, PermissionSetId = permSetId);
            insert new PermissionSetAssignment(AssigneeId = userWithPermSet.Id, PermissionSetId = permSetId);
        }

        System.runAs(userToCreate) {
            insert new Meaningful_Data_Request__c(
                Request_Type__c = 'CSS Request',
                Question_Action__c = 'test?',
                Request_Status__c = 'Opened',
                Answer_No_Answer_Rationale__c = 'test'
            );
        }

        Meaningful_Data_Request__c mdr;

        System.runAs(userWithPermSet) {
            mdr = [SELECT Id, Request_Status__c FROM Meaningful_Data_Request__c WHERE CreatedBy.Id =: userToCreate.Id];

            mdr.Request_Status__c = 'Completed';

            update mdr;
        }

        System.assertEquals(mdr.Request_Status__c, 'Completed');

        System.runAs(userWithoutPermSet) {
            mdr = [SELECT Id, Request_Status__c FROM Meaningful_Data_Request__c WHERE CreatedBy.Id =: userToCreate.Id];

            mdr.Request_Status__c = 'Opened';

            try {
                update mdr;
            } catch (DMLException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
                System.assertEquals(System.Label.Status_Is_Not_Changeable, e.getDmlMessage(0));
            }
        }
    }
}