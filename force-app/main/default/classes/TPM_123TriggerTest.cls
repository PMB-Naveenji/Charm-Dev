/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : TPM_123TriggerTest.
 * @Why   : TPM_123TriggerTest class is for TPM_123Trigger.
 * @When  : 16-APR-2020.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer               Date                   Modification ID       Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                   15-APR-2020            CHARM-2400            (67 - General - Critical /Audit Trail Pick List) Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                   15-MAY-2020            CHARM-2586            (Migrated process issue) Modified. Added new unit test
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oober                   10-JUN-2020            N/A                   Updated code part, which is related to Users' insertion.
 *                                                                         This change designed to prevent a 'DUPLICATE_USERNAME'
 *                                                                         error during deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                   09-JUL-2020            Code Audit            Updated header comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik            05-JUL-2023            CHaRM R3.1            Fixed tpmTriggerTest crash.
 * Not related to an IPDR. Set isParallel.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@isTest(isParallel=true)
public class TPM_123TriggerTest {
    private static final String PROFILE_NAME_DATALOADER = 'System Administrator Data Loader';

    /**
     * @Method       : init.
     * @Description  : To insert test data.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Now handles creation of ADD App Settings
     */
    @TestSetup
    public static void init(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_DATALOADER].Id;

        ADD_App_Settings__c restrictionSettings = (ADD_App_Settings__c)TestDataFactory.createSObject(new ADD_App_Settings__c(
            SetupOwnerId = profileId,
            Restrict_Process_Builders__c = true,
            Restrict_Triggers__c = true,
            Restrict_Validation_Rules__c = true,
            Restrict_Workflow_Updates__c = true
        ), true);

        TPM__c tpm = (TPM__c) TestDataFactory.createSObject(
        new TPM__c(Name = 'Test',
            TPM_Contact_Email__c = 'test@contact.email',
            TPM_Contact_Name__c = 'Test name'),
        true);
        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
        new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = 'TPM_Contact_Name__c',
            CMPL123__Is_Active__c = true,
            Name = 'TPM__c'),
        true);
    }

    /**
     * @Method       : tpmTriggerTest.
     * @Description  : To test the TPM_123Trigger.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: Now verifies that undelete is prevented since the managed
     * package now rejects that. Also removed start/stopTest for full code coverage.
     */
    @isTest
    public static void tpmTriggerTest(){
        TPM__c tpm = [SELECT Id, TPM_Contact_Name__c FROM TPM__c];
        tpm.TPM_Contact_Name__c = 'Test name 2';
        update tpm;
        System.assertEquals(1, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c],
            'Audit trail entry record should be created');
        delete tpm;
        try {
            undelete tpm;
            Assert.fail('The managed package is expected to reject this operation');
        } catch(DmlException ex) {
            Assert.isTrue(ex.getMessage().toLowerCase().contains('permission'),
                'Error message should be related to a lack of permissions');
        }
    }

    /**
     * @Method       : tpmTriggerTestForDataloaderUser.
     * @Description  : To test the TPM_123Trigger for dataloader user.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : R3.1, Larry: User is now IsParallel-friendly
     */
    @isTest
    public static void tpmTriggerTestForDataloaderUser(){
        Id profileId = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_DATALOADER].Id;
        User dataloaderUser = [SELECT Id FROM User
            WHERE ProfileId = :profileId AND IsActive = true LIMIT 1];
        System.runAs(dataloaderUser){
            TPM__c tpm =  (TPM__c) TestDataFactory.createSObject(
                new TPM__c(Name = 'Test',
                    TPM_Contact_Email__c = 'test@contact.email',
                    TPM_Contact_Name__c = 'Test name'), true);
            tpm.TPM_Contact_Name__c = 'Test name 2';
            update tpm;
        }
        System.assertEquals(0, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c],
            'Audit trail entry record should not be created');
    }
}