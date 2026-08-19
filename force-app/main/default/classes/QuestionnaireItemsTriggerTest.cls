/* 
* @why  : QuestionnaireItemsTriggerTest class for the CMPL123CME_Questionnaire_Items_123Trigger,
* @when : CreatedDate : 3-JUN-2019   
* @what : Test Class for trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
    *  Modification Log:  
    *  --------------------------------------------------------------------------------------------------------------------------------------
    *   Developer                Date                   Modification ID                                                Description 
    *  --------------------------------------------------------------------------------------------------------------------------------------
    *      oivan                15-MAY-2020             CHARM-2586(Migrated process issue)                            Modified. Added new unit test
    *  --------------------------------------------------------------------------------------------------------------------------------------
    *   oivan                    10-Jun-2020            N/A                                              Updated code part, which is related to Users' insertion. 
    *                                                                                                    This change designed to prevent a 'DUPLICATE_USERNAME' error during 
    *                                                                                                    deployment to Production environment
    *  --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
class QuestionnaireItemsTriggerTest {
    @IsTest
    private static void triggerTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'USA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                        CMSNext_Ticket_Number__c = '12345'),
                true
        );
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(CMPL123CME__Complaint__c = complaint.Id),
                true
        );
        List<CMPL123CME__Questionnaire_Items__c> questionnaireItems = new List<CMPL123CME__Questionnaire_Items__c>{
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q1,
                        CMPL123CME__Answer__c = 'No'
                ),
                new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q1,
                        CMPL123CME__Answer__c = 'Yes'
                )
        };

        Test.startTest();
        ComplaintTriggerHandler.systemMedEval = false;
        insert questionnaireItems;
        update questionnaireItems;
        delete questionnaireItems;
        Test.stopTest();

        System.assert(0 == [SELECT COUNT() FROM CMPL123CME__Questionnaire_Items__c WHERE Id IN :questionnaireItems]);
    }
    /**
    * @Method       : testAuditTrailForDataloaderUser
    * @Description  : To test the audit configuration for dataloader user. No audit trail entries should be created.
    *                 Method added for CHARM-2586(Migrated process issue)
    * @Return       : N/A
    * @Params       : N/A
    **/

    @isTest
    public static void testAuditTrailForDataloaderUser(){
         CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
                new CMPL123__AuditTrail_Config__c(
                        CMPL123__Fields__c = 'CMPL123CME__Assessment_Comment_Required_Options__c,CMPL123CME__Comments__c,CMPL123CME__Decision_Level__c,CMPL123CME__Parent_Key_Value__c,CMPL123CME__Weight__c',
                        CMPL123__Is_Active__c = true,
                        Name = 'CMPL123CME__Questionnaire_Items__c'),
                true);
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator Data Loader'].Id;
            
        ADD_App_Settings__c restrictionSettings = (ADD_App_Settings__c)TestDataFactory.createSObject(new ADD_App_Settings__c(
                SetupOwnerId = profileId, 
                Restrict_Process_Builders__c = true, 
                Restrict_Triggers__c = true, 
                Restrict_Validation_Rules__c = true, 
                Restrict_Workflow_Updates__c = true
            ), true);
        
        User dataloaderUser = TestUtil.insertTestUser(profileId, 'dataloaderTestQI@test.com', 'dataloaderTestQI@test.com');
        System.runAs(dataloaderUser){
            String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'USA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                        CMSNext_Ticket_Number__c = '12345'),
                true
        );
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(CMPL123CME__Complaint__c = complaint.Id),
                true
        );
        
        CMPL123CME__Questionnaire_Items__c item = (CMPL123CME__Questionnaire_Items__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire_Items__c(
                        CMPL123CME__Questionnaire__c = questionnaire.Id,
                        CMPL123CME__Question__c = SYSTEM.Label.ADDS3_pRE_DT_Q1,
                        CMPL123CME__Answer__c = 'Yes', 
						CMPL123CME__Comments__c = 'test'
                ), true);
        
        }
        System.assertEquals(0, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit trail entry record should not be created');
    }

}