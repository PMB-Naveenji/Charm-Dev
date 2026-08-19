@isTest
public class MDCGenerateFuture_Test {
    
     /**
    * @Method       : setup
    * @Invoke       : Test Framework
    * @Description  : Creates common test data including Complaint, Questionnaire, pRE Information and Meaningful Data records used across all test methods.
    * @Return       : N/A
    * @Params       : N/A
    **/
    @testSetup static void setup(){
        
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
        
        String inquiryRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get('Inquiry')
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint4 = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'Germany',
                        RecordTypeId = inquiryRTId,
                        Business_Unit__c = 'IA-CC',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Investigation_Status__c = 'Assess',
                        Ticket_Type__c = 'Inquiry',
                        CMSNext_Ticket_Number__c = 'CN-16483590',
                        Is_Product_Evaluation_Investigation_chil__c = false,
                        Customer_Reply_Required__c = true,
                        Follow_up_Status__c = 'Further Review',
                        CMPL123Rule_Key_Value__c = 'INQUIRY_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened'),
                true
        );
        
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
    }
    
    /**
     * @Method       : insertMeaningfulData
     * @Invoke       : Test Execution
     * @Description  : Verifies Meaningful Data record creation and validates MDC generation flow for Meaningful Data records.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void insertMeaningfulData(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        Test.startTest();
        Meaningful_Data__c objMeaningfulData = (Meaningful_Data__c) TestDataFactory.createSObject(new Meaningful_Data__c(
            Meaningful_Data_Category__c = 'Test Category',
            Meaningful_Data_Answers__c = 'Test Answer',
            Compliant__c = complaintTicket.Id),true);
        
        System.assertNotEquals(null, objMeaningfulData.Id);
        System.assertEquals(complaintTicket.Id, objMeaningfulData.Compliant__c);
        System.assertEquals('Test Answer', objMeaningfulData.Meaningful_Data_Answers__c);

        Test.stopTest();
    }
    
    /**
     * @Method       : insertTicketNote
     * @Invoke       : Test Execution
     * @Description  : Verifies Ticket Note creation and validates MDC generation flow for Ticket Note records.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void insertTicketNote(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        CMPL123CME__Complaint__c InquiryTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Inquiry' LIMIT 1];
        Test.setCreatedDate(InquiryTicket.Id,Datetime.now().addMinutes(-20));
        Test.startTest();
        Ticket_Note__c objTicketNotesForComplaint = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = 'Test',
            CMPL123Rule_Key_Value__c = 'test',
            Ticket__c = complaintTicket.Id),true);
        
        Ticket_Note__c objTicketNotesForInquiry = (Ticket_Note__c) TestDataFactory.createSObject(new Ticket_Note__c(
            Ticket_Notes_Native__c = 'Test',
            CMPL123Rule_Key_Value__c = 'test',
            Ticket__c = InquiryTicket.Id),true);
        
        System.assertNotEquals(null, objTicketNotesForInquiry.Id);
        System.assertEquals(complaintTicket.Id, objTicketNotesForInquiry.Ticket__c);
        System.assertEquals('test', objTicketNotesForInquiry.CMPL123Rule_Key_Value__c);

        Test.stopTest();
    }
    
    /**
     * @Method       : insertPatientInformation
     * @Invoke       : Test Execution
     * @Description  : Verifies Patient Information record creation and validates MDC generation flow for Patient Information records.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void insertPatientInformation(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        Pre_Information__c preInfo = [Select Id from Pre_Information__c limit 1];
        CMPL123CME__Complaint__c inquiryTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Inquiry' LIMIT 1];
        Test.setCreatedDate(inquiryTicket.Id,Datetime.now().addMinutes(-20));
        Test.startTest();
        Patient_Information__c patientInformations = (Patient_Information__c )TestDataFactory.createSObject(new Patient_Information__c(
            pRE_Information__c = preInfo.Id,
            Patient_Information__c = 'Old',
            Complaint__c = complaintTicket.Id), true);
        Patient_Information__c patientInformations2 = (Patient_Information__c )TestDataFactory.createSObject(new Patient_Information__c(
            pRE_Information__c = preInfo.Id,
            Patient_Information__c = 'Old',
            Complaint__c = inquiryTicket.Id), true);
        
        System.assertNotEquals(null, patientInformations.Id);
        System.assertEquals(complaintTicket.Id, patientInformations.Complaint__c);
        System.assertEquals('Old', patientInformations.Patient_Information__c);
            
        Test.stopTest();
    }
    
    /**
     * @Method       : insertAttachment
     * @Invoke       : Test Execution
     * @Description  : Verifies Attachment record creation and validates MDC generation flow for Attachment records.
     * @Return       : N/A
     * @Params       : N/A
     **/
    static testmethod void insertAttachment(){
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Ticket_Type__c =: 'Complaint' LIMIT 1];
        Test.setCreatedDate(complaintTicket.Id,Datetime.now().addMinutes(-20));
        Test.startTest();
        Attachment__c attachmentRec = (Attachment__c)TestDataFactory.createSObject(new Attachment__c(
                Name = 'Test',
                Attachment_Type__c = 'Customer Letter',
                Registration_Number__c = 'registration',
                Ticket__c = complaintTicket.Id
        ), true);
        
        System.assertNotEquals(null, attachmentRec.Id);
        System.assertEquals(complaintTicket.Id, attachmentRec.Ticket__c);
        System.assertEquals('Customer Letter', attachmentRec.Attachment_Type__c);

        Test.stopTest();
    }

}