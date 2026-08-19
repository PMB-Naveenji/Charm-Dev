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
* Admin                    03-DEC-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class ProductTicketDeleteFlagMDCCustomTest {
    /**
    * @Method       : setupData
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
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
            Delete_Flag__c = false
        );
        TestUtil.setupMDC(
            ProductTicketDeleteFlagMDCCustom.class,
            Product_Ticket__c.getSObjectType(),
            Product_Ticket__c.Delete_Flag__c
        );
    }

    /**
    * @Method       : setDefaultsTest
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void setDefaultsTest() {
        Product_Ticket__c productTickets = [SELECT Id, Delete_Flag__c FROM Product_Ticket__c LIMIT 1];
        Test.startTest();
        productTickets.Delete_Flag__c = !productTickets.Delete_Flag__c;
        TestDataFactory.updateSObject(productTickets);
        Test.stopTest();
        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :productTickets.Id
            AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);
    }
}