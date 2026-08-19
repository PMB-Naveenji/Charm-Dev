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
* Admin                    12-OCT-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class TicketAdhocMedicalEvaluatorMDCCustomTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @testSetup static void setupData() {
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(Ticket_Type__c = 'Inquiry',
                Complaint_Quality_Closure_Date__c = system.now(),
                Overall_Reportable_Status__c = 'Reportable'), true);

        TestUtil.setupMDC(
            TicketAdhocMedicalEvaluatorMDCCustom.class,
            CMPL123CME__Complaint__c.getSObjectType(),
            CMPL123CME__Complaint__c.Ad_hoc_Medical_Evaluator_MDC__c
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
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];

        Test.startTest();
        complaint.Ad_hoc_Medical_Evaluator_MDC__c = 'Test';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c =: complaint.Id
            AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);

        TicketQDNumMDCCustom.hasMedEval = true;
        complaint.Ad_hoc_Medical_Evaluator_MDC__c = 'Test Updated';
        TestDataFactory.updateSObject(complaint);

        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c =: complaint.Id
            AND CMPL123__Action__c = 'Update'][1].CMPL123__Action__c);

        Test.stopTest();
    }
}