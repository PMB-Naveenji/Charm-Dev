/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : PTMDCCustomTest.
* @Why   : PTMDCCustomTest test class for the PTMDCCustom classes.
* @When  : 30-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 30-MAY-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 19-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public with sharing class PTMDCCustomTest {
    private static Boolean hasMedEval;

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setupData() {

        TestUtil.setupMDC(
                PTWithMedEvalBatchLotNumberMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Batch_Lot_Serial__c
        );
        TestUtil.setupMDC(
                PTWithTktSearcheBatchLotNumberMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Batch_Lot_Serial__c
        );
        TestUtil.setupMDC(
                PTBatchLotNumberMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Batch_Lot_Serial__c
        );
        TestUtil.setupMDC(
                PTWithMedEvalFeildsMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Bactch_Likely_List__c
        );
        TestUtil.setupMDC(
                PTWithPTAddedFeildsMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Bactch_Likely_List__c
        );
        TestUtil.setupMDC(
                PTWithMedEvalListNumberMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Product_List_Number_Text__c
        );
        TestUtil.setupMDC(
                PTWithMedEvalProductListMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Product_List_Number_Static__c
        );
        TestUtil.setupMDC(
                PTWithProdEvalFeildsMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Product_List_Number_Static__c
        );
        TestUtil.setupMDC(
                PTWithMedEvalLikelyCauseMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Likely_Cause__c
        );
        TestUtil.setupMDC(
                PTLikelyCauseMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Likely_Cause__c
        );
        TestUtil.setupMDC(
                ProductTicketLikelyCauseMDCCustom.class,
                Product_Ticket__c.getSObjectType(),
                Product_Ticket__c.Likely_Cause__c
        );

        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        //Create Complaint
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                    	RecordTypeId = compRecTypeId,
                        Ticket_Type__c = 'Complaint'),
                true
        );

        insert new Product_Ticket__c(
            Event_Ticket__c = objComplaint.Id,
            Likely_Cause__c = 'Yes',
            Batch_Lot_Serial__c = '123 Lot Serial Number');
    }

    /*
    * @Method       : setDefaultsTest.
    * @Description  : Test method to cover CustomValidation method in PTMDCCustom Classes.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void setDefaultsTest() {

        Product_Ticket__c record = [SELECT Id, Batch_Lot_Serial__c, Bactch_Likely_List__c, Product_List_Number_Text__c, Product_List_Number_Static__c FROM Product_Ticket__c];
        TestDataFactory.updateSObject(record);
        Test.startTest();
        TicketQDNumMDCCustom.hasMedEval = false;
        TestDataFactory.updateSObject(record);


        record.Batch_Lot_Serial__c = '1 Lot Serial Number';
        record.Bactch_Likely_List__c = 'TBD';
        record.Likely_Cause__c = 'No';
        record.Product_List_Number_Text__c = 'TBD';
        record.Product_List_Number_Static__c = 'TBD';

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