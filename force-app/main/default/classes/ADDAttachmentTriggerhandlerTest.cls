/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDAttachmentTriggerhandlerTest.
* @Why   : ADDAttachmentTriggerhandlerTest class for the ADDAttachmentTriggerhandler class.
* @When  : 15-DEC-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                  Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 15-DEC-2018           Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                 03-JUN-2020           N/A                             Test class optimization
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 27-JUL-2020           Code Audit                      Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ADDAttachmentTriggerhandlerTest {
    /*
    * @Method       : setupData.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setupData() {
        insertData();
    }

    /*
    * @Method       : insertData.
    * @Description  : To insert test data asynchronously.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @future
    public static void insertData () {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        String questionnaireRTId = Schema.SObjectType.CMPL123CME__Questionnaire__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();

        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        TestDataFactory.createSObject(new Country_Submission_Type__c(
                Name = '30 Days',
                Calendar_Days__c = 30,
                Country__c = objCountry.Id
        ), true);

        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                RecordTypeId = complaintRTId), true);

        CMPL123CME__Questionnaire__c questionnaire = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                RecordTypeId = questionnaireRTId,
                CMPL123CME__Complaint__c = complaint.Id
        ), true);

        CMPL123CME__EMDR__c EMDRInitialRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
        new CMPL123CME__EMDR__c(
                RecordTypeId = EMDRInitial,
                Medical_Evaluation__c = questionnaire.Id
        ), true);

        // Create Post Market Risk Assessment Risk Contr
        TestDataFactory.createSObject(new Post_Market_Risk_Assessment_Risk_Contr__c(
                Division__c = 'ADD',
                CMPL123_WF_Status__c = 'Opened',
                Rationale_if_No_Hazards_Are_Identified__c = 'Test',
                Potential_Hazard_Types_Associated_with_I__c = 'Chemical',
                Business_Unit__c = 'Transfusion',
                Event_which_could_lead_to_a_hazard__c = 'Test',
                Notification_Date__c = System.today(),
                Site_Owner_New__c = 'Dallas'
        ), true);

        //Create Attachments
        TestDataFactory.createSObject(new Attachment__c(
                Name = 'Test',
                Attachment_Type__c = 'Customer Letter',
                Registration_Number__c = 'registration',
                EMDR__c = EMDRInitialRecord.Id
        ), true);

        //Create Attachments
        TestDataFactory.createSObject(new Attachment(
                ParentId = EMDRInitialRecord.Id,
                Body = Blob.valueOf('Customer Letter'),
                Name = 'Test.txt'
        ), true);
    }

    /*
    * @Method       : testADDAttachmentTriggerhandler.
    * @Description  : To test the ADDAttachmentTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testADDAttachmentTriggerhandler() {
        Test.startTest();
        Attachment objAttachment2 = [SELECT Id, ParentId FROM Attachment WHERE Name = 'Test.txt' LIMIT 1];
        objAttachment2.Name = 'TestUpdated.txt';
        update objAttachment2;
        Attachment__c customAttachment = [
                SELECT Id,Name,Attachment_Title__c,EMDR__c
                FROM Attachment__c
                WHERE EMDR__c = :objAttachment2.ParentId
                LIMIT 1
        ];
        System.assert(customAttachment.Attachment_Title__c == objAttachment2.Name);
        delete objAttachment2;
        Test.stopTest();
    }

    /*
    * @Method       : stripExtensionTest.
    * @Description  : To test the ADDAttachmentTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void stripExtensionTest() {
        Test.startTest();
        String result = ADDAttachmentTriggerhandler.stripExtension('test.subextension.extension');
        System.assertEquals('test.subextension', result);
        Test.stopTest();
    }

    /*
    * @Method       : addParentCustomAttachmentTest.
    * @Description  : To test the ADDAttachmentTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void addParentCustomAttachmentTest() {
        Test.startTest();
        Attachment__c customAttachment = [SELECT Id FROM Attachment__c WHERE Name = 'Test' LIMIT 1];
        TestDataFactory.createSObject(new Attachment(
                ParentId = customAttachment.Id,
                Body = Blob.valueOf('Customer Letter'),
                Name = 'Test.txt'
        ), true);
        System.assert([SELECT COUNT() FROM Attachment WHERE ParentId = :customAttachment.Id] > 0);
        Test.stopTest();
    }

    /*
    * @Method       : preventCreatingDeletingIfParentIsSpecificTest.
    * @Description  : To test the ADDAttachmentTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void preventCreatingDeletingIfParentIsSpecificTest() {
        Post_Market_Risk_Assessment_Risk_Contr__c pmra = [SELECT Id FROM Post_Market_Risk_Assessment_Risk_Contr__c LIMIT 1];

        Test.startTest();

        Attachment__c cusAttachment = (Attachment__c) TestDataFactory.createSObject(new Attachment__c(
                Attachment_Type__c = 'Medical Evaluation',
                Post_Market_Risk_Asst_Risk_Ctrl__c = pmra.Id
        ), true);

        pmra.CMPL123_WF_Status__c = 'Pending Closure of Related Child Records and Tasks';

        update pmra;

        try {
            insert new Attachment(
                    ParentId = cusAttachment.Id,
                    Body = Blob.valueOf('Customer Letter'),
                    Name = 'Test.txt'
            );
        } catch (DmlException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
            System.assertEquals(System.Label.Custom_Attachment_Error_Message, e.getDmlMessage(0));
        }

        Test.stopTest();

        Integer result = [SELECT Id FROM Attachment WHERE ParentId =: cusAttachment.Id].size();

        System.assertEquals(0, result);
    }

}