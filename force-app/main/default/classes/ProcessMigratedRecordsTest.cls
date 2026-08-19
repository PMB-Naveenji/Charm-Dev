/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ProcessMigratedRecordsTest.
* @Why   : ProcessMigratedRecordsTest test class for the ProcessMigratedRecords class.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 18-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ProcessMigratedRecordsTest {

    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        insert new CMPL123CME__Complaint__c(
                Division__c  = 'ADD',
                pRE_Status__c  = 'Yes',
                Country_of_origin__c  = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c  = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
                CMSNext_Ticket_Number__c = '12345'
        );

        CMPL123__WF_Status__c  statusOpened = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'Opened'),
                true
        );
        CMPL123__WF_Status__c  statusRiskControlMeasureInProcess = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c (Name = 'CMPL123CME__CMPL123_WF_Status__c'),
                true
        );
        CMPL123__WF_Action__c actionPassThrough = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c  (Name = 'Pass-Through'),
                true
        );
        CMPL123__WF_Rule__c  assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'ADD Risk Managment Workflow',
                        CMPL123__Target_Object__c = 'Post_Market_Risk_Assessment_Risk_Contr__c(ADDRiskManagement)',
                        CMPL123__Record_Type__c  = 'CMPL123Rule_Key_Value__c',
                        CMPL123__Is_Active__c  = true,
                        CMPL123__Has_Multiple_Actions__c = true),
                true
        );
        insert new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = statusOpened.Id,
                CMPL123__End_Status__c  = statusRiskControlMeasureInProcess.Id,
                CMPL123__Action__c  = actionPassThrough.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__WF_Rule__c = assessProdRule.Id,
                CMPL123__Is_Start_Step__c = true
        );
    }

    /*
    * @Method       : test.
    * @Description  : To test the ProcessMigratedRecords functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        List<CMPL123CME__Complaint__c> complaints = [
                SELECT CMPL123CME__CMPL123_WF_Status__c, CMPL123Rule_Key_Value__c
                FROM CMPL123CME__Complaint__c
        ];
        ProcessMigratedRecords job = new ProcessMigratedRecords(
                CMPL123CME__Complaint__c.class.getName(),
                new Set<Id> {complaints.get(0).Id}
        );
        CMPL123__WF_Step__c step = [SELECT Id FROM CMPL123__WF_Step__c];
        CMPL123__WF_Rule__c  assessProdRule = [SELECT Name FROM CMPL123__WF_Rule__c];
        CMPL123__WF_Status__c  statusOpened = [SELECT Name FROM CMPL123__WF_Status__c WHERE Name = 'Opened' LIMIT 1];
        Map<String,CMPL123__WF_Step__c> mapWFStepWithRuleKey = new Map<String, CMPL123__WF_Step__c> {
                statusOpened.Name + '-' + assessProdRule.Name => step
        };

        Test.startTest();
        job.execute(null, complaints);
        job.createWFHistoryRecords(complaints, mapWFStepWithRuleKey);
        Test.stopTest();

        System.assertNotEquals(0, [SELECT COUNT() FROM CMPL123__Audit_Trail_Entry__c]);
    }

    /*
    * @Method       : testComplaint.
    * @Description  : To test the ProcessMigratedRecords functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testComplaint() {
        ProcessMigratedRecords job = new ProcessMigratedRecords(
                CMPL123CME__Complaint__c.class.getName(),
                new Set<Id> {[SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1].Id}
        );

        Test.startTest();
        Id jobId = Database.executeBatch(job);
        Test.stopTest();

        System.assertEquals(jobId, [SELECT Id FROM AsyncApexJob LIMIT 1].Id);
    }

    /*
    * @Method       : testEMR.
    * @Description  : To test the ProcessMigratedRecords functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testEMR() {
        ProcessMigratedRecords job = new ProcessMigratedRecords(CMPL123CME__EMDR__c.class.getName());

        Test.startTest();
        Id jobId = Database.executeBatch(job);
        Test.stopTest();

        System.assertEquals(jobId, [SELECT Id FROM AsyncApexJob LIMIT 1].Id);
    }

    /*
    * @Method       : testProductLot.
    * @Description  : To test the ProcessMigratedRecords functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testProductLot() {
        ProcessMigratedRecords job = new ProcessMigratedRecords(Product_Lot__c.class.getName());

        Test.startTest();
        Id jobId = Database.executeBatch(job);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE Id = :jobId]);
    }
}