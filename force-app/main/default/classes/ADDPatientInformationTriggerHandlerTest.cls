/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDPatientInformationTriggerHandlerTest.
* @Why   : ADDPatientInformationTriggerHandlerTest class for the ADDPatientInformationTriggerHandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
 *  CHaRM COE          20-JUL-2026          CHaRM R9.0/IPDR-409     	Created "seup", "createPatientInformation_test1" & "createPatientInformation_test2" methods
 * 																		to cover the MDC creation fucntionality when PatientInformation record creates.
 * --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class ADDPatientInformationTriggerHandlerTest {
    
    @testSetup static void setup(){
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        appConfig.MDC_Generation_Prevention_Minutes__c=10.0;
        update appConfig;
        // Create Complaint Ticket record used as parent record
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'No',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Complaint',
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), true);
        
        setupMDC(
            PatientInformationMDCLogic.class,
            Patient_Information__c.getSObjectType(),
            Patient_Information__c.Patient_Information__c
        );
        
    }
    
    public static void setupMDC(Type classForTesting, SObjectType objectToTrack, SObjectField fieldToTrack) {
        String sObjectName = objectToTrack.getDescribe().getName();
        String fieldApiName = fieldToTrack.getDescribe().getName();
        String fieldLabel = fieldToTrack.getDescribe().getLabel();
        String classUnderTestName = classForTesting.getName();
        
        TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = fieldApiName,
            CMPL123__Is_Active__c = true,
            Name = sObjectName
        ), true);
        
        CMPL123__MDC_Trigger__c mdcTrigger = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(new CMPL123__MDC_Trigger__c(
            CMPL123__Select_Target_Object__c = sObjectName,
            CMPL123__Criteria__c = 'Changed',
            CMPL123__Logic__c = '1',
            CMPL123__Active__c = true,
            Name = 'Patient Information Change'
        ), true);
        
        TestDataFactory.createSObject(new CMPL123__MDC_Field_Mapping__c(
            CMPL123__Field_Name__c = fieldLabel,
            CMPL123__Index__c = 1,
            CMPL123__Field_API__c = fieldApiName,
            CMPL123__Condition__c = 'Custom',
            CMPL123__Selected_object__c = sObjectName,
            CMPL123__Parent_object__c = mdcTrigger.Id,
            CMPL123__Parameters__c = classUnderTestName
        ), true);
        
        TestDataFactory.createSObject(new CMPL123__AcknowledgementMapping__c(
            CMPL123__SelectObject__c = sObjectName,
            CMPL123__AckNumber__c = 1,
            CMPL123__PublicGroupAcknowledgment__c = 'Medical Evaluator',
            CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
            CMPL123__Index__c = 1
        ), true);
    }

    /*
    * @Method       : triggerEventsTest.
    * @Description  : To test the ADDPatientInformationTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void triggerEventsTest() {
        Patient_Information__c patientInformation = (Patient_Information__c) TestDataFactory.createSObject(
                new Patient_Information__c(), true);
        update patientInformation;
        delete patientInformation;
        System.assert(0 == [SELECT COUNT() FROM Patient_Information__c WHERE Id = :patientInformation.Id]);
    }
	
	 /**
     * @Method       : createPatientInformation_test1
     * @Description  : Verifies MDC generation for Ticket Notes when the parent Ticket creation time exceeds the 
     * 				   configured MDC prevention interval.
     * @Return       : N/A
     * @Params       : N/A
     **/    
    @isTest
    static void createPatientInformation_test1() { 
        ADD_App_Settings__c appConfig = [SELECT Id, Enable_MDC_Prevention_Logic__c FROM ADD_App_Settings__c LIMIT 1];
        appConfig.Enable_MDC_Prevention_Logic__c = true;
        update appConfig;
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        // Create Medical Evaluation record
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaintTicket.Id
        ), true);
        // Create pRE Information record associated with the Complaint.
        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(
            new pRE_Information__c(
                External_ID__c = 'CHaRM 24102018 - 01',
                Complaint__c = complaintTicket.Id),
            true
        );
        Test.startTest();
        Patient_Information__c patientInformations = (Patient_Information__c )TestDataFactory.createSObject(new Patient_Information__c(
            pRE_Information__c = preInfo.Id,
            Patient_Information__c = 'Old',
            Complaint__c = complaintTicket.Id), true);
		Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(1, mdcCount);
            
        Test.stopTest();
    }
    /**
     * @Method       : createPatientInformation_test2
     * @Description  : Verifies Ticket Note processing and MDC generation when MDC prevention validation is enabled 
     * 				   through application settings.
     * @Return       : N/A
     * @Params       : N/A
     **/
    @isTest
    static void createPatientInformation_test2() { 
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        // Create Medical Evaluation record
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
            RecordTypeId = questionnaireRTId,
            CMPL123CME__Complaint__c = complaintTicket.Id
        ), true);
        // Create pRE Information record associated with the Complaint.
        pRE_Information__c preInfo = (pRE_Information__c) TestDataFactory.createSObject(
            new pRE_Information__c(
                External_ID__c = 'CHaRM 24102018 - 01',
                Complaint__c = complaintTicket.Id),
            true
        );
        Test.startTest();
        Patient_Information__c patientInformations = (Patient_Information__c )TestDataFactory.createSObject(new Patient_Information__c(
            pRE_Information__c = preInfo.Id,
            Patient_Information__c = 'Old',
            Complaint__c = complaintTicket.Id), true);        
        Integer mdcCount = [SELECT COUNT() FROM CMPL123__MDC_Ticket__c WHERE Related_Ticket_Id__c =: complaintTicket.Id];         
        system.assertEquals(1, mdcCount);
        Test.stopTest();
    }
}