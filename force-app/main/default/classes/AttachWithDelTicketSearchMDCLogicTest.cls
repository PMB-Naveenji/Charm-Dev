/**
 * --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : ADDMDCTicketTriggerHandler
 * @Why   : Handles all the customization involved on custom MDC Ticket object
 * @When  : 13-JAN-2021
 * @Where : From AttachmentsWithProdEvalDeletionMDCLogic
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID      Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Admin                    14-JUN-2019            Work ID / Case ID    Created.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * RSlob                    13-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik             01-FEB-2023            CHaRM R3.0, IPDR 411 Fixed test() by adding a Ticket on testSetup's Attachment
 * --------------------------------------------------------------------------------------------------------------------------------------
 **/
@IsTest
private class AttachWithDelTicketSearchMDCLogicTest {
    /**
     * @Method       : setup
     * @Description  : Create records needed in a test methods
     * @Return       : N/A
     * @Params       : N/A
     * @Revision     : 01-FEB-2023 Larry: Added a Ticket for the Attachment
     **/
    @TestSetup
    private static void setup() {
        // 31-JAN-2023 Larry: Inserted a Ticket for the Attachment to be affiliated with
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c)
            TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId,
                Ticket_Type__c = AspenConstants.STR_Complaint),
            true
        );

        Attachment__c att = (Attachment__c)
            TestDataFactory.createSObject(new Attachment__c(
                Name = 'TranslationTaskAttachment',
                Ticket__c = complaintTicket.Id,
                Attachment_Type__c = 'Registration',
                Deletion_Justification__c = 'Old'),
            true
        );

        String sObjectName = Attachment__c.getSObjectType().getDescribe().getName();
        String fieldApiName = Attachment__c.Deletion_Justification__c.getDescribe().getName();
        String fieldLabel = Attachment__c.Deletion_Justification__c.getDescribe().getLabel();

        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
            new CMPL123__AuditTrail_Config__c(
                CMPL123__Fields__c = fieldApiName,
                CMPL123__Is_Active__c = true,
                Name = sObjectName),
            true
        );

        //Create MDC_Trigger
        CMPL123__MDC_Trigger__c mdcTrigger = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(
            new CMPL123__MDC_Trigger__c(
                CMPL123__Select_Target_Object__c = sObjectName,
                CMPL123__Criteria__c = 'Changed',
                CMPL123__Logic__c = '1',
                CMPL123__Active__c = true),
            true
        );

        CMPL123__MDC_Field_Mapping__c fieldMapping = (CMPL123__MDC_Field_Mapping__c) TestDataFactory.createSObject (
            new CMPL123__MDC_Field_Mapping__c(
                CMPL123__Field_Name__c = fieldLabel,
                CMPL123__Index__c = 1,
                CMPL123__Field_API__c = fieldApiName,
                CMPL123__Condition__c = 'Custom',
                CMPL123__Selected_object__c = sObjectName,
                CMPL123__Parent_object__c = mdcTrigger.Id,
                CMPL123__Parameters__c = 'AttachmentsWithDelTicketSearchMDCLogic'),
            true
        );

        CMPL123__AcknowledgementMapping__c ackMapping = (CMPL123__AcknowledgementMapping__c) TestDataFactory.createSObject(
            new CMPL123__AcknowledgementMapping__c(
                CMPL123__SelectObject__c = sObjectName,
                CMPL123__AckNumber__c = 1,
                CMPL123__PublicGroupAcknowledgment__c = 'Medical Evaluator',
                CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
                CMPL123__Index__c = 1),
            true
        );
    }

    /**
     * @Method       : test
     * @Description  : Contains verification logic
     * @Return       : N/A
     * @Params       : N/A
     * @Revision     : 01-FEB-2023 Larry: Added an assert to verify that
     * this test method bug does not resurface
     **/
    @IsTest
    private static void test() {
        Attachment__c attachment = [SELECT Deletion_Justification__c, Ticket__c FROM Attachment__c LIMIT 1];
        System.assertNotEquals(null, attachment.Ticket__c, 'Bad setup data');

        Test.startTest();
        attachment.Deletion_Justification__c = 'New';
        TestDataFactory.updateSObject(attachment);
        Test.stopTest();

        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :attachment.Id AND
            CMPL123__Action__c = 'Update'].CMPL123__Action__c);
    }
}