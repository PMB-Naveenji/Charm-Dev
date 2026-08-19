/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : PTWithMedEvalFeildsMDCCustomTest.
* @Why   : PTWithMedEvalFeildsMDCCustomTest test class for the PTWithMedEvalFeildsMDCCustom class.
* @When  : 14-JAN-2021.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                    09-JUL-2020            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class PTWithMedEvalFeildsMDCCustomTest {
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {

        TestUtil.setupMDC(
            PTWithMedEvalFeildsMDCCustom.class,
            Product_Ticket__c.getSObjectType(),
            Product_Ticket__c.Bactch_Likely_List__c
        );

        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        //Create Complaint
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                RecordTypeId = compRecTypeId,
                Ticket_Type__c = 'Complaint'),
            true
        );

        insert new Product_Ticket__c (
            Event_Ticket__c = objComplaint.Id,
            Likely_Cause__c = 'Yes',
            Batch_Lot_Serial__c = '123 Lot Serial Number'
        );
    }

    /*
    * @Method       : customValidationTest.
    * @Description  : To test the PTWithMedEvalFeildsMDCCustom functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    private static void customValidationTest() {

        Product_Ticket__c record = [SELECT Id, Bactch_Likely_List__c FROM Product_Ticket__c];

        Test.startTest();

        TicketQDNumMDCCustom.hasMedEval = null;
        record.Bactch_Likely_List__c = 'test';
        TestDataFactory.updateSObject(record);

        TicketQDNumMDCCustom.hasMedEval = true;
        record.Bactch_Likely_List__c = 'test1';
        TestDataFactory.updateSObject(record);

        Test.stopTest();

        List <CMPL123__MDC_Trigger__c> triggers = [Select Id, Name from CMPL123__MDC_Trigger__c];
        System.assertEquals(1, triggers.size());

    }
}