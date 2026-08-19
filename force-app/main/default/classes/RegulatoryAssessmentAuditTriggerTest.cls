/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @why  : Test class for the Regulatory_Assessment_AuditTrigger.
* @when : CreatedDate : 25-OCT-2018.
* @what : Handles different scenarios from Regulatory_Assessment_AuditTrigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID         Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                28-DEC-2020            TWD Upgrade issue       Added 'executeLogicFromWFRulesTest()' method to test moved logic from
*                                                                       Workflow Rules with Field Updates on Regulatory Assessment to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class RegulatoryAssessmentAuditTriggerTest {
    @TestSetup
    static void setup() {
        TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = 'CMPL123_WF_Action__c',
            Name = 'Regulatory_Assessment__c'
         ), true);

        TestDataFactory.createSObject(new Regulatory_Assessment__c(
           CMPL123Rule_Key_Value__c = 'REGULATORY_ASSESSMENT_WORKFLOW'
        ), true);
    }

    /*
    * @Method       : testADDRegulatoryAssessmentTriggerHandler
    * @Description  : To test the Regulatory_Assessment_AuditTrigger functionality.
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    public static void testADDRegulatoryAssessmentTriggerHandler(){
        Regulatory_Assessment__c regulatoryAssessment = [SELECT Id
                                                            FROM Regulatory_Assessment__c
                                                            WHERE CMPL123Rule_Key_Value__c = 'REGULATORY_ASSESSMENT_WORKFLOW'];

        regulatoryAssessment.CMPL123_WF_Action__c = 'Reopen';
        update regulatoryAssessment;

        System.assertEquals(Database.countQuery('SELECT count() FROM CMPL123__Audit_Trail_Entry__c'), 1);

        regulatoryAssessment.CMPL123_WF_Action__c = 'Void';
        update regulatoryAssessment;

        System.assertEquals(Database.countQuery('SELECT count() FROM CMPL123__Audit_Trail_Entry__c'), 2);

        delete regulatoryAssessment;
    }

    /*
    * @Method       : executeLogicFromWFRulesTest.
    * @Description  : To test 'executeLogicFromWFRules()' method.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void executeLogicFromWFRulesTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c pmra = (Post_Market_Risk_Assessment_Risk_Contr__c) TestDataFactory.createSObject(
            new Post_Market_Risk_Assessment_Risk_Contr__c(
                Source__c = 'Nonconformance',
                Source_Reference_Number__c = 'BSQ008417',
                Short_Description_of_Issue__c = 'Low RLU',
                Quality_Assessor__c = UserInfo.getUserId(),
                Division__c = 'ADD',
                Description_of_Issue__c = 'test',
                CMPL123_WF_Status__c = 'Opened',
                Version_Number__c = 0,
                Is_Cloned__c = false,
                Business_Unit__c = 'LC – Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Biohazard',
                Recognition_Date__c = System.today() - 1,
                Notification_Date__c = System.today() - 1,
                Risk_Control_Management_Decision_Date__c = System.today() - 1,
                Closure_Date__c = System.today() - 1,
                Site_Owner_New__c = 'Milan'
        ), true);

        Test.startTest();

        Regulatory_Assessment__c regulatoryAssessment = (Regulatory_Assessment__c) TestDataFactory.createSObject(new Regulatory_Assessment__c(
            CMPL123_WF_Status__c = 'In Process',
            CMPL123_WF_Action__c = 'Promote',
            Post_Market_Risk_Assessment_Risk_Contr__c = pmra.Id,
            Approver__c = UserInfo.getUserId(),
            Impact_to_Design_Reqs_Specs__c = 'Yes',
            Extent_of_Regulatory_Impact__c = 'Worldwide',
            Impact_to_an_International_Submission__c = 'Yes',
            Impact_to_Labeling__c = 'Yes',
            Is_there_a_Regulatory_Impact__c = 'Yes',
            Impact_to_Product_Performance__c = 'Yes',
            Impact_to_Product_s_Intended_Use__c = 'Yes',
            Impact_to_Claims__c = 'Yes',
            Impact_to_a_US_Submission__c = 'Yes'
        ), true);

        Regulatory_Assessment__c newRA = [SELECT Id, Assigned_Date__c, CMPL123Rule_Key_Value__c
                                            FROM Regulatory_Assessment__c
                                            WHERE Id = :regulatoryAssessment.Id];

        System.assertEquals(DateTime.now().day(), newRA.Assigned_Date__c.day());
        System.assertEquals('REGULATORY_ASSESSMENT_WORKFLOW', newRA.CMPL123Rule_Key_Value__c);

        Regulatory_Assessment__c regulatoryAssessment2 = (Regulatory_Assessment__c) TestDataFactory.createSObject(new Regulatory_Assessment__c(
            CMPL123_WF_Status__c = 'Pending Approval',
            CMPL123_WF_Action__c = 'Complete - Regulatory Impact',
            Post_Market_Risk_Assessment_Risk_Contr__c = pmra.Id,
            Approver__c = UserInfo.getUserId(),
            Impact_to_Design_Reqs_Specs__c = 'No',
            Impact_to_an_International_Submission__c = 'No',
            Impact_to_Labeling__c = 'No',
            Is_there_a_Regulatory_Impact__c = 'No',
            Impact_to_Product_Performance__c = 'No',
            Impact_to_Product_s_Intended_Use__c = 'No',
            Impact_to_Claims__c = 'No',
            Impact_to_a_US_Submission__c = 'No',
            No_Regulatory_Impact_Rationale__c = 'test'
        ), true);

        newRA = [SELECT Id, Submitted_On__c, Reject_Rationale__c
                    FROM Regulatory_Assessment__c
                    WHERE Id = :regulatoryAssessment2.Id];

        System.assertEquals(DateTime.now().day(), newRA.Submitted_On__c.day());
        System.assertEquals(null, newRA.Reject_Rationale__c);

        regulatoryAssessment.CMPL123_WF_Status__c = 'Closed-Done';
        regulatoryAssessment.CMPL123_WF_Action__c = 'Approve';
        update regulatoryAssessment;

        newRA = [SELECT Id, Approved_On__c
                    FROM Regulatory_Assessment__c
                    WHERE Id = :regulatoryAssessment.Id];

        System.assertEquals(DateTime.now().day(), newRA.Approved_On__c.day());

        regulatoryAssessment2.CMPL123_WF_Status__c = 'Closed-Done';
        regulatoryAssessment2.CMPL123_WF_Action__c = 'Complete - No Regulatory Impact';
        update regulatoryAssessment2;

        newRA = [SELECT Id, Completed_Date__c
                    FROM Regulatory_Assessment__c
                    WHERE Id = :regulatoryAssessment2.Id];

        System.assertEquals(DateTime.now().day(), newRA.Completed_Date__c.day());

        Test.stopTest();
    }
}