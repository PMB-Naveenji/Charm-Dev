/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 14-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    12-NOV-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
class PTInquiryProductListMDCCustomTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @testSetup
    static void setupData() {
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
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
        TestUtil.setupMDC(
            PTInquiryProductListMDCCustom.class,
            Product_Ticket__c.getSObjectType(),
            Product_Ticket__c.Product_List_Number_Static__c
        );
    }

    /**
    * @Method       : setDefaultsTest
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    static void setDefaultsTest() {
        Product_Ticket__c objProductTicket = [SELECT ID, Product_List_Number_Static__c FROM Product_Ticket__c LIMIT 1];
        objProductTicket.Product_List_Number_Static__c = '1234';
        TestDataFactory.updateSObject(objProductTicket);
        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :objProductTicket.Id
            AND CMPL123__Action__c = 'Update'
        ][0].CMPL123__Action__c);
    }
}