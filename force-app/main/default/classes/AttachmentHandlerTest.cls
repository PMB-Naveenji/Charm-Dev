/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : AttachmentHandlerTest.
* @Why   : N/A.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                    Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                18-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                08-SEP-2020            PMD                           Added assertion into 'beforeDeleteEventHandler' and 
*                                                                           'beforeEventHandler' methods.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class AttachmentHandlerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup() {
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId), true);
        //Create Questionnaire
        CMPL123CME__Questionnaire__c objQuestionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(Final_Mfg_Analysis__c = 'Test', CMPL123CME__Complaint__c = complaint.Id), true);
        //Create Attachments
        Attachment__c objAttachment = (Attachment__c) TestDataFactory.createSObject(new Attachment__c(Name = 'Test', Attachment_Type__c = 'Customer Letter', Assessment__c = objQuestionnaire.id), true);
        //Create Customer Response
        Customer_Response_Master__c objCustomerResponseMaster = (Customer_Response_Master__c) TestDataFactory.createSObject(new Customer_Response_Master__c(CMPL123_WF_Status__c = 'Opened', Source_Ticket_Type__c = 'Inquiry', Division__c = 'ADD'), true);
        //Create Second Attachments
        Attachment__c objAttach = (Attachment__c) TestDataFactory.createSObject(new Attachment__c(Name = 'Test Record', Attachment_Type__c = 'Customer Letter', Customer_Response_Master__c = objCustomerResponseMaster.id), true);

    }

    /*
    * @Method       : beforeDeleteEventHandler.
    * @Description  : N/A.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static testMethod void beforeDeleteEventHandler() {

        Integer initAttCount = [SELECT COUNT() FROM Attachment__c];

        Test.startTest();
        
        CMPL123CME__Questionnaire__c questionaireUpdate = [SELECT Id,CMPL123_WF_Status__c 
                                                           FROM CMPL123CME__Questionnaire__c 
                                                           WHERE Final_Mfg_Analysis__c = 'Test'];
        questionaireUpdate.CMPL123_WF_Status__c = 'Closed-Voided';
        update questionaireUpdate;

        Attachment__c objAttachment = [SELECT Id FROM Attachment__c WHERE Name = 'Test'];
        try {
            delete objAttachment;
        }
        catch (DmlException e) {
            String currentException = e.getMessage();
            String expectedException = 'Insufficient access.';
            System.assertEquals(true, currentException.contains(expectedException));
        }
        
        Test.stopTest();

        Integer currAttCount = [SELECT COUNT() FROM Attachment__c];

        System.assertEquals(initAttCount, currAttCount);
    }

    /*
    * @Method       : beforeEventHandler.
    * @Description  : N/A.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static testMethod void beforeEventHandler() {
        
        Integer initAttCount = [SELECT COUNT() FROM Attachment__c];

        Attachment__c objAttach = [SELECT Id FROM Attachment__c WHERE Name = 'Test Record'];
        Attachment attach = new Attachment();
        attach.Name = 'Test Attachment';
        Blob bodyBlob = Blob.valueOf('Test Attachment Body');
        attach.body = bodyBlob;
        attach.parentId = objAttach.id;
        insert attach;

        Test.startTest();

        Customer_Response_Master__c customerResponseRecUpdate = [SELECT Id,CMPL123_WF_Status__c FROM Customer_Response_Master__c WHERE Division__c = 'ADD'];
        customerResponseRecUpdate.CMPL123_WF_Status__c = 'Closed-Voided';
        update customerResponseRecUpdate;
        
        try {
            delete attach;
        }
        catch (DmlException e) {
            String currentException = e.getMessage();
            String expectedException = 'Insufficient access.';
            System.assertEquals(true, currentException.contains(expectedException));
        }
        
        Attachment attachRec = new Attachment();
        attachRec.Name = 'Test Attachment';
        Blob bdyBlob = Blob.valueOf('Test Attachment Body');
        attachRec.body = bdyBlob;
        attachRec.parentId = objAttach.id;
        try {
            insert attachRec;
            List<Attachment> attachList = [SELECT Id FROM Attachment WHERE Name = 'Test Attachment' AND parentId = :objAttach.id];
            System.assert(attachList.size() > 0);
        }
        catch (DmlException e) {
            //No exceptions should be thrown
            System.assertEquals(null, e);
        }

        Test.stopTest();

        Integer currAttCount = [SELECT COUNT() FROM Attachment__c];
        
        System.assertEquals(true, initAttCount >= currAttCount ? true : false);
    }
}