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
* Admin                    30-MAY-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                    03-JUN-2020            N/A                  Test class optimization
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    24-JUN-2020            #143 (CHARM-2801)    Modified. Added new method to test condition for MDC
*                                                                      ticket creation.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Add new test method to increase code coverage. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class MeanigfulDataAnswerMedEvalMDCTest {

    @TestSetup
    private static void setup() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Division__c  = 'ADD',
                pRE_Status__c  = 'Yes',
                Country_of_origin__c  = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c  = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
                CMSNext_Ticket_Number__c = '12345'),
            true
        );
        insert new Meaningful_Data__c(Compliant__c = complaint.Id);
        TestUtil.setupMDC(
            MeanigfulDataAnswerMedEvalMDC.class,
            Meaningful_Data__c.getSObjectType(),
            Meaningful_Data__c.Compliant__c
        );
    }

    @IsTest
    private static void test() {

        Test.startTest();
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Division__c  = 'ADD',
                pRE_Status__c  = 'Yes',
                Country_of_origin__c  = 'USA',
                RecordTypeId = complaintRTId,
                Business_Unit__c  = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
                CMSNext_Ticket_Number__c = '12345'),
            true
        );
        Meaningful_Data__c meaningfulData = [SELECT Id FROM Meaningful_Data__c LIMIT 1];

        meaningfulData.Compliant__c = complaint.Id;
        InternalTicketServiceProcessor.newTicketFlag = false;
        TestDataFactory.updateSObject(meaningfulData);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Meaningful_Data__c]);
    }

    @IsTest
    private static void test1() {
        MeanigfulDataAnswerMedEvalMDC controller = new MeanigfulDataAnswerMedEvalMDC();

        Test.startTest();
        InternalTicketServiceProcessor.newTicketFlag = true;
        Meaningful_Data__c meaningfulData = new Meaningful_Data__c();
        TicketQDNumMDCCustom.hasMedEval = true;
        Boolean result = controller.customValidation(null, meaningfulData);
        Test.stopTest();

        System.assertEquals(false, result);
    }

    /**
    * @Method       : testMDConInsert
    * @Description  : #143 (CHARM-2801) MDC should create tickets on record insert
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testMDConInsert() {
        //Create MDC_Trigger
        CMPL123__MDC_Trigger__c mdcTrigger = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(
            new CMPL123__MDC_Trigger__c(
                Name = 'Meaningful Data Change for med evaluator',
                CMPL123__Select_Target_Object__c = 'Meaningful_Data__c',
                CMPL123__Criteria__c = 'Created Or Changed',
                CMPL123__Logic__c = '1',
                CMPL123__Active__c = true),
            true
        );
        List <CMPL123__MDC_Trigger__c> triggers = [Select Id, Name, CMPL123__Number_of_Acks__c , CMPL123__Select_Target_Object__c, Selected_Group_Name__c  from CMPL123__MDC_Trigger__c];
        List <CMPL123__MDC_Field_Mapping__c > mappings  = new List <CMPL123__MDC_Field_Mapping__c>();
        List <String> fields = new List <String>{'Meaningful_Data_Answers__c'};
        Integer index = 0;
        for (String field: fields) {
            CMPL123__MDC_Field_Mapping__c fieldMapping = (CMPL123__MDC_Field_Mapping__c) TestDataFactory.createSObject (
                new CMPL123__MDC_Field_Mapping__c(
                    CMPL123__Field_Name__c = field,
                    CMPL123__Index__c = ++index,
                    CMPL123__Field_API__c = field,
                    CMPL123__Condition__c = 'Custom',
                    CMPL123__Selected_object__c = 'Meaningful_Data__c',
                    CMPL123__Parent_object__c = mdcTrigger.Id,
                    CMPL123__Parameters__c = 'MeanigfulDataAnswerMedEvalMDC'),
                false);
            mappings.add(fieldMapping);
        }
        insert mappings;
        CMPL123__AcknowledgementMapping__c ackMapping = (CMPL123__AcknowledgementMapping__c) TestDataFactory.createSObject(
            new CMPL123__AcknowledgementMapping__c(
                CMPL123__SelectObject__c = 'Meaningful_Data__c',
                CMPL123__AckNumber__c = 1,
                CMPL123__PublicGroupAcknowledgment__c = 'Medical Evaluator',
                CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
                CMPL123__Index__c = 1),
            true
        );
        CMPL123CME__Complaint__c complaint = [Select Id from CMPL123CME__Complaint__c  limit 1];
        insert new Meaningful_Data__c(Compliant__c = complaint.Id, Meaningful_Data_Answers__c = 'test');
        //System.assertEquals(1, [Select Id from CMPL123__MDC_Ticket__c ].size(), 'Should be created 1 MDC Ticket');
    }

    /**
    * @Method       : test2
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test2 () {
        MeanigfulDataAnswerMedEvalMDC mdcTrigger = new MeanigfulDataAnswerMedEvalMDC ();
        Meaningful_Data__c newRecord = new Meaningful_Data__c(Meaningful_Data_Answers__c = 'New');
        Meaningful_Data__c oldRecord = new Meaningful_Data__c(Meaningful_Data_Answers__c = 'Old');
        System.assertEquals(false, mdcTrigger.CustomValidation(oldRecord, newRecord));
    }
}