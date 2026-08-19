/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Search_Log_AuditTriggerTest.
* @Why   : Test class to handle different scenarios from Risk_Assessment_123Trigger.
* @When  : 15-MAY-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                  15-MAY-2020            CHARM-2586                      Created. Added new unit test
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME' error
*                                                                                   during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class Risk_Assessment_123TriggerTest {
    /*
    * @Method       : init.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    public static void init(){
        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
            new CMPL123__AuditTrail_Config__c(
                    CMPL123__Fields__c = 'Batch_Lot_Serial__c,Expiration_Date__c',
                    CMPL123__Is_Active__c = true,
                    Name = 'Risk_Assessment__c'),
            true);
    }

    /*
    * @Method       : testAuditTrailForDataloaderUser.
    * @Description  : To test the audit configuration for dataloader user. No audit trail entries should be created.
    *                   Method added for CHARM-2586(Migrated process issue).
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testAuditTrailForDataloaderUser(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator Data Loader'].Id;

        ADD_App_Settings__c restrictionSettings = (ADD_App_Settings__c)TestDataFactory.createSObject(new ADD_App_Settings__c(
                SetupOwnerId = profileId,
                Restrict_Process_Builders__c = true,
                Restrict_Triggers__c = true,
                Restrict_Validation_Rules__c = true,
                Restrict_Workflow_Updates__c = true
            ), true);

        User dataloaderUser = TestUtil.insertTestUser(
            profileId,
            'test2@test.com',
            'aspenUserTest@test.com'
        );

        System.runAs(dataloaderUser){
            Risk_Assessment__c sObj = (Risk_Assessment__c)TestDataFactory.createSObject(
                new Risk_Assessment__c(
                        Batch_Lot_Serial__c= 'test'
                        ),
                true);
        }
        System.assertEquals(0, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit trail entry record should not be created');
    }
}