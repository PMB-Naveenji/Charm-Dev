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
* Admin                    25-JAN-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
public class PTLikelyCauseMDCCustomTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Ticket_Type__c = 'Complaint',
                Overall_Reportable_Status__c='Reportable'),
            true
        );
        insert new Product_Ticket__c(
            Likely_Cause__c = 'No',
            Event_Ticket__c = objComplaint.Id
        );

        TestUtil.setupMDC(
            PTLikelyCauseMDCCustom.class,
            Product_Ticket__c.getSObjectType(),
            Product_Ticket__c.Likely_Cause__c
        );
    }

    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void setDefaultsTest() {
        Product_Ticket__c productTicket = [SELECT Likely_Cause__c FROM Product_Ticket__c LIMIT 1];

        Test.startTest();
        productTicket.Likely_Cause__c = 'Yes';
        TestDataFactory.updateSObject(productTicket);
        Test.stopTest();

        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c =: productTicket.Id
                AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);
    }
}