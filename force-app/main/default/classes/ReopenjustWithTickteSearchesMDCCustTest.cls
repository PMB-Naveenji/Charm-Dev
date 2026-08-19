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
* Admin                    18-JUN-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
class ReopenjustWithTickteSearchesMDCCustTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    private static void setup() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get('Complaint')
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId,
                Country_of_origin__c = 'USA'),
            true
        );

        insert new Re_Open_Justification__c(Complaint__c = complaint.id );

        TestUtil.setupMDC(
            ReopenjustWithTickteSearchesMDCCustom.class,
            Re_Open_Justification__c.getSObjectType(),
            Re_Open_Justification__c.Re_Open_Justification_Added__c
        );
    }

    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test() {
        Re_Open_Justification__c reOpenJustification = [SELECT Id FROM Re_Open_Justification__c LIMIT 1];

        Test.startTest();
        reOpenJustification.Re_Open_Justification_Added__c = 'Yes';
        TestDataFactory.updateSObject(reOpenJustification);

        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c =: reOpenJustification.Id
            AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);

        TicketQDNumMDCCustom.hasTicketSearch = true;
        reOpenJustification.Re_Open_Justification_Added__c = 'No';
        TestDataFactory.updateSObject(reOpenJustification);

        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c =: reOpenJustification.Id
            AND CMPL123__Action__c = 'Update'][1].CMPL123__Action__c);

        Test.stopTest();
    }
}