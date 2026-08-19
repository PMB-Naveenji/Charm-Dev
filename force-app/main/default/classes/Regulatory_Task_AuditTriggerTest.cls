@isTest
class Regulatory_Task_AuditTriggerTest {
    @isTest
    static void testTrigger() {

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId,
                        Country_of_origin__c = 'USA'
                ), true);

        List< Regulatory_Task__c > newRegTasks = new List< Regulatory_Task__c>();
        String assmntRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__Questionnaire__c questionnaireRecord = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(
                new CMPL123CME__Questionnaire__c(
                        RecordTypeId = assmntRTId,
                        CMPL123CME__Complaint__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Regulatory',
                        Reportability_Rationale__c = 'Regulatory',
                        Reportability__c = 'Reportable',
                        Reportability_Category__c = 'Always Reportable',
                        Follow_Up_Awareness_Date__c = Date.newInstance(2018, 12, 8)
                ), true);

      //Code changes start for sprint 4
     
      //  Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;
       // User aspenUser = TestUtil.insertTestUser(aspenInteg, 'aspenUserInteg@test.com', 'aspenUserInteg@test.com.test');
     
     //code changes end for sprint 4   
        
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(
                new Country__c(
                        Primary_Vigilance_Contact__c = UserInfo.getUserId()
                ), true);

        CMPL123__Product__c product = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                Name = 'PATH Vysion',
                CMPL123__Lot_No__c = '123',
                List_Number__c = '12345'
        ), true);

        Product_Ticket__c prodTckt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Product__c = product.Id,
                Event_Ticket__c = complaint.Id,
                Batch_Lot_Serial__c = '1235'
        ), true);

        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days', Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);

        CMPL123CME__MEDDEV__c meddevRecord = (CMPL123CME__MEDDEV__c) TestDataFactory.createSObject(new CMPL123CME__MEDDEV__c(
                Medical_Evaluation__c = questionnaireRecord.Id,
                Product__c = prodTckt.id,
                Country__c = objCountry.Id,
                CMPL123CME__Complaint__c = complaint.Id,
                Regulatory_Evaluator__c = [SELECT id FROM User LIMIT 1].id,
                Submission_Type__c = objCountrySubmissionType.Id,
                Submission_Due_Date__c = Date.newInstance(2018, 12, 8),
                CMPL123_WF_Status__c = 'Opened'), true);

        meddevRecord.CMPL123_WF_Status__c = 'Pending Regulatory Decision';
        UpdateParentUtility.flag = true;
        Id competentAuthorityRegulatoryResponseRTID = Schema.SObjectType.Regulatory_Task__c.getRecordTypeInfosByName().get('Competent Authority Regulatory Response').getRecordTypeId();
        Regulatory_Task__c regulatoryTaskRecord = (Regulatory_Task__c) TestDataFactory.createSObject(
                new Regulatory_Task__c(
                        RecordTypeId = competentAuthorityRegulatoryResponseRTID,
                        MDI__c = meddevRecord.Id
                ), true);

        Test.startTest();
        UpdateParentUtility.flag = true;
        update regulatoryTaskRecord;
        delete regulatoryTaskRecord;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Regulatory_Task__c]);
    }

}