/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @why  : To Test all scenarios on the class TranslationTaskWithTckMedEvalMDCCustom.
* @when : 25-OCT-2018.
* @what : TranslationTaskWithTckMedEvalMDCCusTest test class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    14-JAN-2021            Code Audit                Added fields to Complaint on insert.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class TranslationTaskWithTckMedEvalMDCCusTest {
    /*
    * @Method       : setupData.
    * @Description  : Create test data.
    */
    @testSetup static void setupData() {
        TestUtil.setupMDC(
                TranslationTaskWithTckMedEvalMDCCustom.class,
                Translation_Task__c.getSObjectType(),
                Translation_Task__c.CMPL123_WF_Status__c
        );
        TestUtil.setupMDC(
                TranslationTaskWithProdEvalMDCCustom.class,
                Translation_Task__c.getSObjectType(),
                Translation_Task__c.CMPL123_WF_Status__c
        );
        TestUtil.setupMDC(
                TranslationTaskWithOpenProdEvalMDCCustom.class,
                Translation_Task__c.getSObjectType(),
                Translation_Task__c.CMPL123_WF_Status__c
        );
        TestUtil.setupMDC(
                TranslationTaskWithINQProdEvalMDCCustom.class,
                Translation_Task__c.getSObjectType(),
                Translation_Task__c.CMPL123_WF_Status__c
        );

        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(),
                Ticket_Type__c = 'Complaint',

                //     Code Audit - FIX START.
                Customer_Reply_Required__c = false,
                CMSNext_Ticket_ID__c = '12346',
                CMSNext_Ticket_Number__c = '12346',
                pRE_Status__c = 'Yes'
                //     Code Audit - FIX END.
        ), true);

        insert new Translation_Task__c(
            Parent_Ticket__c = objComplaint.Id,
            RecordTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Text Translation').getRecordTypeId());
    }

    /*
    * @Method       : customValidation.
    * @Description  : Test method to cover customValidation method in TranslationTaskWithTckMedEvalMDCCustom class.
    */
    @isTest
    static void customValidation() {
        Translation_Task__c record = [SELECT Id,CMPL123_WF_Status__c FROM Translation_Task__c];

        Test.startTest();

        record.CMPL123_WF_Status__c = 'Closed-Done';

        TestDataFactory.updateSObject(record);
        Test.stopTest();

        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: record.Id AND CMPL123__Action__c = 'Insert']) {
             System.assertEquals('Insert', entry.CMPL123__Action__c);
        }
        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: record.Id AND CMPL123__Action__c = 'Update']) {
             System.assertEquals('Update', entry.CMPL123__Action__c);
        }
    }
}