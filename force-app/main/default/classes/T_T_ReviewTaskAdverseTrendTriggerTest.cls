/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
 * @What  : Test Class for trigger.
 * @Why   : T_T_ReviewTaskAdverseTrendTriggerTest class for the T_T_Review_Task_Adverse_Trend_123Trigger.
 * @When  : 15-MAY-2020.
 * @Where : N/A.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer               Date                   Modification ID                                Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oivan                   15-MAY-2020            CHARM-2586(Migrated process issue)             Modified. Added new unit test.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * oober                   10-JUN-2020            N/A                                            Updated code part, which is related to Users' insertion.
 *                                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME'
 *                                                                                                   error during deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                   09-JUL-2020            Code Audit                                     Updated class comments.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik            20-JUL-2023            CHaRM R3.1                                     Moved testTriggerOperations into this class.
 * (Previously called testPackageClass). Fixed crash in that function caused by a TWD package upgrade. Not related to any IPDR.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

@IsTest
public class T_T_ReviewTaskAdverseTrendTriggerTest {
    /**
     * @Method       : setup.
     * @Description  : To create data for tests.
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Revision     : JUL-2020 or earlier?: Renamed from "init".
     */
    @TestSetup
    public static void setup() {
        TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = 'Action_Taken__c,Adverse_Trend__c,Process__c,Task_ID__c,Task_Name__c,Trend_Item_Type__c',
            CMPL123__Is_Active__c = true,
            Name = 'T_T_Review_Task_Adverse_Trend__c'
        ), true);
    }

    /**
     * @Method       : testAuditTrailForDataloaderUser.
     * @Description  : To test the audit configuration for dataloader user. No audit trail entries should be created.
     *                   Method added for CHARM-2586(Migrated process issue).
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     */
    @IsTest
    public static void testAuditTrailForDataloaderUser() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator Data Loader'].Id;

        TestDataFactory.createSObject(new ADD_App_Settings__c(
            SetupOwnerId = profileId,
            Restrict_Process_Builders__c = true,
            Restrict_Triggers__c = true,
            Restrict_Validation_Rules__c = true,
            Restrict_Workflow_Updates__c = true
        ), true);

        User dataloaderUser = (User) TestDataFactory.createSObject(new User(
            ProfileId = profileId,
            LastName = 'MainContact',
            Email = 'test@test.com',
            Username = 'test@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        ), true);

        System.runAs(dataloaderUser) {
            TestDataFactory.createSObject(new T_T_Review_Task_Adverse_Trend__c(Action_Taken__c = 'No Action Required'), true);
        }

        System.assertEquals(0, [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit trail entry record should not be created');
    }

    /**
     * Tests basic trigger operations for the T&T Review Task object
     * @revision R3.1, Larry: Moved this whole function from TicketUtilTest.
     * Old function name was testPackageClass. Now verifies that undelete
     * is prevented since the managed package now rejects that. Also removed
     * start/stopTest for full code coverage.
     */
    @IsTest
    static void testTriggerOperations() {
        T_T_Review_Task_Adverse_Trend__c ttrt = new T_T_Review_Task_Adverse_Trend__c();
        insert ttrt;
        System.assertEquals(1, [SELECT COUNT() FROM T_T_Review_Task_Adverse_Trend__c],
            'TT Review Task should be created');
        update ttrt;
        delete ttrt;
        System.assertEquals(0, [SELECT COUNT() FROM T_T_Review_Task_Adverse_Trend__c],
            'TT Review Task should be deleted');
        try {
            undelete ttrt;
            Assert.fail('The managed package is expected to reject this operation');
        } catch(DmlException ex) {
            Assert.isTrue(ex.getMessage().toLowerCase().contains('permission'),
                'Error message should be related to a lack of permissions');
        }
    }
}