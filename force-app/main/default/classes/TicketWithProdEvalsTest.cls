/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketWithProdEvalsTest.
* @Why   : To test all scenarios of TicketWithProdEvalsMDCCustom classes.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID                                Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                   30-MAY-2019            Work ID / Case ID                              Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   09-JUL-2020            Code Audit                                     Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public with sharing class TicketWithProdEvalsTest {
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {
        TestUtil.setupMDC(
                TicketWithProdEvalsORtatusMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Overall_Reportable_Status__c
        );
        TestUtil.setupMDC(
                TicketWithProdEvalspREStatusMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.pRE_Status__c
        );
        TestUtil.setupMDC(
                TicketWithProdEvalsQDNumMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Quality_Directive_Number__c
        );
        TestUtil.setupMDC(
                TicketWithProdEvalsReceiptDateMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Receipt_Date__c
        );
        TestUtil.setupMDC(
                TicketWithSearchesReceiptDateMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Receipt_Date__c
        );
        TestUtil.setupMDC(
                TicketWithSearchesDescMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Ticket_Description__c
        );
        TestUtil.setupMDC(
                TicketWithSearchesICMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Issue_code__c
        );
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
    * @Method       : customValidation.
    * @Description  : To test customValidation method.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void customValidation() {
        CMPL123CME__Complaint__c record = [SELECT Id,Overall_Reportable_Status__c,pRE_Status__c,
        Quality_Directive_Number__c,Receipt_Date__c,Ticket_Description__c,Issue_code__c
         FROM CMPL123CME__Complaint__c];

        Test.startTest();

        record.Overall_Reportable_Status__c = 'TPM Responsible';
        record.pRE_Status__c = 'Yes';
        record.Quality_Directive_Number__c = 'TBD';
        record.Receipt_Date__c = Date.today();
        record.Ticket_Description__c = 'TBD';
        record.Issue_code__c = 'TBD';

        TestDataFactory.updateSObject(record);
        Test.stopTest();

        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: record.Id AND CMPL123__Action__c = 'Insert']) {
             System.assertEquals('Insert', entry.CMPL123__Action__c);
        }
        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: record.Id AND CMPL123__Action__c = 'Update']) {
             System.assertEquals('Update', entry.CMPL123__Action__c);
        }

        // Test.startTest();
        // new TicketWithProdEvalsORtatusMDCCustom().CustomValidation();
        // new TicketWithProdEvalspREStatusMDCCustom().customValidation();
        // new TicketWithProdEvalsQDNumMDCCustom().customValidation();
        // new TicketWithProdEvalsReceiptDateMDCCustom().customValidation();
        // Test.stopTest();

    }
}