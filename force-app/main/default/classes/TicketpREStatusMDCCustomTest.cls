@IsTest
private class TicketpREStatusMDCCustomTest {
    private static Boolean hasMedEval;
    @TestSetup
    static void setupData() {

        CMPL123__AuditTrail_Config__c objAuditTrialConfig = (CMPL123__AuditTrail_Config__c) TestDataFactory.createSObject(
                new CMPL123__AuditTrail_Config__c(
                        CMPL123__Fields__c = 'pRE_Status__c',
                        CMPL123__Is_Active__c = true,
                        Name = 'CMPL123CME__Complaint__c'),
                true
        );

        //Create MDC_Trigger
        CMPL123__MDC_Trigger__c mdcTrigger = (CMPL123__MDC_Trigger__c) TestDataFactory.createSObject(
                new CMPL123__MDC_Trigger__c(
                        CMPL123__Select_Target_Object__c = 'CMPL123CME__Complaint__c',
                        CMPL123__Criteria__c = 'Created or Changed',
                        CMPL123__Logic__c = '1',
                        CMPL123__Active__c = true,
                        CMPL123__Record_Detail_Field__c = 'Registration_Ticket__c'),
                true
        );

        CMPL123__MDC_Field_Mapping__c fieldMapping = (CMPL123__MDC_Field_Mapping__c) TestDataFactory.createSObject (
                new CMPL123__MDC_Field_Mapping__c(
                        CMPL123__Field_Name__c = 'pRE Status',
                        CMPL123__Index__c = 1,
                        CMPL123__Field_API__c = 'pRE_Status__c',
                        CMPL123__Condition__c = 'Custom',
                        CMPL123__Selected_object__c = 'CMPL123CME__Complaint__c',
                        CMPL123__Parent_object__c = mdcTrigger.Id,
                        CMPL123__Parameters__c = 'TicketpREStatusMDCCustom'),
                true);

        CMPL123__AcknowledgementMapping__c ackMapping = (CMPL123__AcknowledgementMapping__c) TestDataFactory.createSObject(
                new CMPL123__AcknowledgementMapping__c(
                        CMPL123__SelectObject__c = 'CMPL123CME__Complaint__c',
                        CMPL123__AckNumber__c = 1,
                        CMPL123__PublicGroupAcknowledgment__c = 'Medical Evaluator',
                        CMPL123__MDC_Trigger_Acknowledgment__c = mdcTrigger.Id,
                        CMPL123__Index__c = 1),
                true
        );
        
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(); 
        //Create Complaint
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                    	RecordTypeId = compRecTypeId,
                        Ticket_Type__c = 'Complaint',
                        pRE_Status__c = 'Yes'),
                true
        );

    }


    @IsTest
    private static void setDefaultsTest() {
       
        CMPL123CME__Complaint__c complaintRecord = [SELECT Id, pRE_Status__c FROM CMPL123CME__Complaint__c];
        complaintRecord.pRE_Status__c = 'No';
       
        Test.startTest();
        TestDataFactory.updateSObject(complaintRecord);
        Test.stopTest();
        
        System.assertEquals('Insert', [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: complaintRecord.Id AND CMPL123__Action__c = 'Insert'].CMPL123__Action__c);
        
        System.assertEquals('Update', [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: complaintRecord.Id AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);

		
    }

}