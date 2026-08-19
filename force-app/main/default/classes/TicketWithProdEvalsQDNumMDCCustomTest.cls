/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketWithProdEvalsQDNumMDCCustomTest.
* @Why   : TicketWithProdEvalsQDNumMDCCustomTest test class for the TicketWithProdEvalsQDNumMDCCustom class.
* @When  : 09-JUL-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 13-JUL-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 14-JAN-2021         TWD Upgrade                       Modify setup method. Add new test method. TWD Upgrade
*                                                                             issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TicketWithProdEvalsQDNumMDCCustomTest {

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        //Create Complaint
        insert new CMPL123CME__Complaint__c(
                    	RecordTypeId = compRecTypeId,
                        Ticket_Type__c = 'Complaint',
                        Overall_Reportable_Status__c = 'Not Reportable',
                        Issue_code__c = 'TBDD',
                        pRE_Status__c = 'No');
    }

    /*
    * @Method       : customValidationTest.
    * @Description  : To test the TicketWithProdEvalsQDNumMDCCustom functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void customValidationTest() {
        TestUtil.setupMDC(
                TicketWithProdEvalsQDNumMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Quality_Directive_Number__c
        );

        CMPL123CME__Complaint__c record = [SELECT Id, Quality_Directive_Number__c FROM CMPL123CME__Complaint__c];

        Test.startTest();

        record.Quality_Directive_Number__c = 'test';
        TestDataFactory.updateSObject(record);

        TicketQDNumMDCCustom.hasProdEval = false;
        record.Quality_Directive_Number__c = 'test1';
        TestDataFactory.updateSObject(record);

        Test.stopTest();

        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: record.Id AND CMPL123__Action__c = 'Insert']) {
             System.assertEquals('Insert', entry.CMPL123__Action__c);
        }
        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: record.Id AND CMPL123__Action__c = 'Update']) {
             System.assertEquals('Update', entry.CMPL123__Action__c);
        }
    }

    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test () {
        TicketWithProdEvalspREStatusMDCCustom mdcTrigger = new TicketWithProdEvalspREStatusMDCCustom();
        CMPL123CME__Complaint__c newRecord = new CMPL123CME__Complaint__c(pRE_Status__c = 'No');
        CMPL123CME__Complaint__c oldRecord = new CMPL123CME__Complaint__c(pRE_Status__c = 'Yes');
        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}