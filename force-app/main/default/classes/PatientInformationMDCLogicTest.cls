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
* Admin                    13-MAY-2020            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    27-MAY-2020            #124 (CHARM-2724)    Modified. Added new method to test condition for MDC ticket creation.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Add missing data. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class PatientInformationMDCLogicTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    private static void setup () {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get('Complaint')
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMSNext_Ticket_Number__c = '12345',
                //TWD Upgrade BEGIN
                CMSNext_Ticket_ID__c = '12345'
                //TWD Upgrade END
            ),
            true
        );
        
        //#124 (CHARM-2724) start. Create med eval to meet criteria.
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaint.Id
        ), true);
        //#124 (CHARM-2724) end.
        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(
            new pRE_Information__c(
                External_ID__c = 'CHaRM 24102018 - 01',
                Complaint__c = complaint.Id),
            true
        );
        //#124 (CHARM-2724) start. Create audit trail config and mdc trigger
        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
            new CMPL123__AuditTrail_Config__c(
                CMPL123__Fields__c = 'Patient_Information__c,Patient_Information_Translated__c,External_Id__c',
                CMPL123__Is_Active__c = true,
                Name = 'Patient_Information__c'),
            true
        );

        //Create MDC_Trigger
        CMPL123__MDC_Trigger__c mdcTrigger = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(
            new CMPL123__MDC_Trigger__c(
                Name = 'Patient Information Change',
                CMPL123__Select_Target_Object__c = 'Patient_Information__c',
                CMPL123__Criteria__c = 'Created Or Changed',
                CMPL123__Logic__c = '1 OR 2 OR 3',
                CMPL123__Active__c = true),
            true
        );
        List <CMPL123__MDC_Trigger__c> triggers = [Select Id, Name, CMPL123__Number_of_Acks__c , CMPL123__Select_Target_Object__c, Selected_Group_Name__c  from CMPL123__MDC_Trigger__c];
        List <CMPL123__MDC_Field_Mapping__c > mappings  = new List <CMPL123__MDC_Field_Mapping__c>();
        List <String> fields = new List <String>{'Patient_Information__c', 'Patient_Information_Translated__c',  'External_Id__c'};
        Integer index = 0;
        for (String field: fields) {
            CMPL123__MDC_Field_Mapping__c fieldMapping = (CMPL123__MDC_Field_Mapping__c) TestDataFactory.createSObject (
                new CMPL123__MDC_Field_Mapping__c(
                    CMPL123__Field_Name__c = field,
                    CMPL123__Index__c = ++index,
                    CMPL123__Field_API__c = field,
                    CMPL123__Condition__c = 'Custom',
                    CMPL123__Selected_object__c = 'Patient_Information__c',
                    CMPL123__Parent_object__c = mdcTrigger.Id,
                    CMPL123__Parameters__c = 'PatientInformationMDCLogic'),
                false);
            mappings.add(fieldMapping);
        }
        insert mappings;
        CMPL123__AcknowledgementMapping__c ackMapping = (CMPL123__AcknowledgementMapping__c) TestDataFactory.createSObject(
            new CMPL123__AcknowledgementMapping__c(
                CMPL123__SelectObject__c = 'Patient_Information__c',
                CMPL123__AckNumber__c = 1,
                CMPL123__PublicGroupAcknowledgment__c = 'Medical Evaluator',
                CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
                CMPL123__Index__c = 1),
            true
        );
        //#124 (CHARM-2724) end.
    }

    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test() {
        //TWD Upgrade BEGIN
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        //TWD Upgrade END
        //#124 (CHARM-2724) start. Create Patient information on the record that meets criterias
        Pre_Information__c preInfo = [Select Id from Pre_Information__c limit 1];
        Patient_Information__c patientInformations = (Patient_Information__c )TestDataFactory.createSObject(new Patient_Information__c(
            pRE_Information__c = preInfo.Id,
            Patient_Information__c = 'Old',
            //TWD Upgrade BEGIN
            Complaint__c = complaint.Id
            //TWD Upgrade END
        ), true);
        //#124 (CHARM-2724) end.

        Test.startTest();
        patientInformations.Patient_Information__c = 'Closed-Done';
        TestDataFactory.updateSObject(patientInformations);
        Test.stopTest();

        System.assertEquals('Update', [
            SELECT CMPL123__Action__c
            FROM CMPL123__Audit_Trail_Entry__c
            WHERE CMPL123__ParentId__c = :patientInformations.Id
                AND CMPL123__Action__c = 'Update'
        ].CMPL123__Action__c);

    }
    /**
    * @Method       : testMDCTrigger
    * @Description  : #124 (CHARM-2724) MDC should create tickets on all field change
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void testMDCTrigger () {
        Test.startTest();
        //TWD Upgrade BEGIN
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c LIMIT 1];
        //TWD Upgrade END
        Pre_Information__c preInfo = [Select Id from Pre_Information__c limit 1];
        Patient_Information__c patientInformations = (Patient_Information__c )TestDataFactory.createSObject(new Patient_Information__c(
            pRE_Information__c = preInfo.Id,
            Patient_Information__c = 'Old',
            //TWD Upgrade BEGIN
            Complaint__c = complaint.Id
            //TWD Upgrade END
        ), true);
        //System.assertEquals(1, [Select Id from CMPL123__MDC_Ticket__c ].size(), 'Should be created 1 MDC Ticket after insert');
        patientInformations.Patient_Information__c = 'Closed-Done';
        patientInformations.CMPL123Rule_Key_Value__c = 'rulekeyvalue';
        patientInformations.CMPL123Task_Key_Value__c= 'taskkeyvalue';
        patientInformations.Patient_Information_Translated__c= 'translated text';
        patientInformations.External_Id__c= 'some test id';
        TestDataFactory.updateSObject(patientInformations);
        Test.stopTest();
        System.assertEquals(2, [Select Id from CMPL123__MDC_Ticket__c ].size(), 'Should be created 2 MDC Tickets');
        System.assertEquals('Patient Information,Patient Information (Translated),External Id', [Select Id, CMPL123__Field_Name__c  From CMPL123__MDC_Ticket__c where CMPL123__Field_Name__c != 'Patient_Information__c'].CMPL123__Field_Name__c  );
        patientInformations.Patient_Information_Translated__c= 'translated text1';
        TestDataFactory.updateSObject(patientInformations);
        System.assertEquals(3, [Select Id from CMPL123__MDC_Ticket__c ].size(), 'Should be created 3 MDC Tickets');
        patientInformations.External_Id__c= 'some test id 1';
        TestDataFactory.updateSObject(patientInformations);
        System.assertEquals(4, [Select Id from CMPL123__MDC_Ticket__c ].size(), 'Should be created 4 MDC Tickets');
        patientInformations.Patient_Information__c = 'test information';
        TestDataFactory.updateSObject(patientInformations);
        System.assertEquals(5, [Select Id from CMPL123__MDC_Ticket__c ].size(), 'Should be created 5 MDC Tickets');
    }
}