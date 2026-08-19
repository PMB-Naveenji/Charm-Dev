/*
* @why  : Test class for the ADDAdditionalApprovalHandler.
* @when : 31-AUG-2018.
* @what : Class to handle different scenarios from ADDAdditionalApprovalHandler.
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    10-JUN-2020            N/A                           Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME'
*                                                                                   error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue             Added 'executeLogicFromWFRulesTest()' method to test moved
*                                                                                   logic from Workflow Rules with Field Updates
*                                                                                   on Additional Approval to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class AdditionalApprovalhandlerTest {
    @TestSetup
    static void setup() {
        User aspenUser = TestUtil.insertTestUser(
            [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            'test@test.com',
            'test@test.com',
            'RM13'
        );

        insert new Post_Market_Risk_Assessment_Risk_Contr__c(
            Source__c = 'Problem',
            Source_Reference_Number__c = '124',
            Short_Description_of_Issue__c = 'Test',
            Quality_Assessor__c = aspenUser.Id,
            Description_of_Issue__c = 'Test',
            Division__c = 'ADD',
            Recognition_Date__c = System.today(),
            CMPL123_WF_Status__c = 'Hazard Assessment In Process',
            Business_Unit__c = 'IA-CC',
            Event_which_could_lead_to_a_hazard__c ='Test',
            Notification_Date__c = System.today(),
            Site_Owner_New__c = 'Dallas',Initial_Hazard_Assessment_By__c = aspenUser.Id
        );
    }

    @IsTest
    public static void addAdditionalApprovalHandlerTest(){
        Test.startTest();

        Additional_Approval__c ap = new Additional_Approval__c(
            Post_Market_ID__c = [SELECT Id FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1].Id
        );
        insert ap;

        ap.Voided_On__c = System.today();
        update ap;

        delete ap;

        Test.stopTest();
    }

    @IsTest
    static void executeLogicFromWFRulesTest() {
        String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        Id pmraId = [SELECT Id FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1].Id;

        Test.startTest();

        Additional_Approval__c additionalApproval = new Additional_Approval__c(
            CMPL123_WF_Status__c = 'Pending Approval',
            CMPL123_WF_Action__c = 'Promote',
            CMPL123Rule_Key_Value__c = 'ADD_AdditionalApproval',
            Approver__c = UserInfo.getUserId(),
            Post_Market_ID__c = pmraId
        );
        insert additionalApproval;

        Additional_Approval__c newAA = [SELECT Id, Submit_for_Approval_By__c
                                            FROM Additional_Approval__c
                                            WHERE Id = :additionalApproval.Id];

        System.assertEquals(actionPerformedBy, newAA.Submit_for_Approval_By__c);

        Additional_Approval__c additionalApproval2 = new Additional_Approval__c(
            CMPL123_WF_Status__c = 'Opened',
            CMPL123_WF_Action__c = 'Reject',
            CMPL123Rule_Key_Value__c = 'ADD_AdditionalApproval',
            Post_Market_ID__c = pmraId,
            Reject_Rationale__c = 'test'
        );
        insert additionalApproval2;

        newAA = [SELECT Id, Reject_By__c
                    FROM Additional_Approval__c
                    WHERE Id = :additionalApproval2.Id];

        System.assertEquals(actionPerformedBy, newAA.Reject_By__c);

        Additional_Approval__c additionalApproval3 = new Additional_Approval__c(
            CMPL123_WF_Status__c = 'Closed-Done',
            CMPL123_WF_Action__c = 'Approve',
            CMPL123Rule_Key_Value__c = 'ADD_AdditionalApproval',
            Post_Market_ID__c = pmraId
        );
        insert additionalApproval3;

        newAA = [SELECT Id, Approve_By__c
                    FROM Additional_Approval__c
                    WHERE Id = :additionalApproval3.Id];

        System.assertEquals(actionPerformedBy, newAA.Approve_By__c);

        Additional_Approval__c additionalApproval4 = new Additional_Approval__c(
            CMPL123_WF_Status__c = 'Closed-Voided',
            CMPL123_WF_Action__c = 'Void',
            CMPL123Rule_Key_Value__c = 'ADD_AdditionalApproval',
            Post_Market_ID__c = pmraId,
            Void_Rationale__c = 'test'
        );
        insert additionalApproval4;

        newAA = [SELECT Id, Vioded_By__c
                    FROM Additional_Approval__c
                    WHERE Id = :additionalApproval4.Id];

        System.assertEquals(actionPerformedBy, newAA.Vioded_By__c);

        Test.stopTest();
    }
}