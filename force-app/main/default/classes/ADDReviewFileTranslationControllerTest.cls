/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDReviewFileTranslationControllerTest.
* @Why   : ADDReviewFileTranslationControllerTest class for the ADDReviewFileTranslationController class.
* @When  : 04-JUN-2017.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                04-JUN-2017           Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                16-APR-2019           N/A                         Modified.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak    	           10-JUN-2020	         N/A                         Updated code part, which is related to Users' insertion.
*                                                                        This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                        deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                12-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid					27 Jan 2021			Fixed Erorr					Updated Wf step to fix workflow Key Value Erorr
*---------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDReviewFileTranslationControllerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){
        User u = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'lastname',
            Email = 'emailid@test.com',
            CompanyName = 'CompanyXXX',
            Title = 'Title',
            Alias = 'Alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10',
            Username = 'user123@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        //Create Workflow Action
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Promote'),true);

        //Create Workflow Rule
        CMPL123__WF_Rule__c  compWFRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            Name = 'Translation task workflow',
            CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
            CMPL123__Record_Type__c  = 'Translation_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);

        //Create  Workflow status with name = 'In Process'
        CMPL123__WF_Status__c  statusInProgress = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'In Process'),true);

        // Create   Workflow status with  Name = 'Translation Pending Review'
        CMPL123__WF_Status__c  statusTransPending = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Translation Pending Review'),true);

        // Create   Workflow status with  Name = 'Closed-Done'
        CMPL123__WF_Status__c  endstatus = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Closed-Done'),true);

         // Create  Workflow status with  Name = 'Task sent to vendor'
        CMPL123__WF_Status__c  statusSentToVendor = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Task sent to vendor'),true);

        //Create Workflow Step
        CMPL123__WF_Step__c statusPendingWF = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusTransPending.Id,
            CMPL123__End_Status__c  = endstatus.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = compWFRule.Id,
            CMPL123__Is_Start_Step__c = false),true);//Juneid 27 Jan 2020 , Updated CMPL123__Is_Start_Step__c = false to fix work flow error

        //Create Workflow Step
        CMPL123__WF_Step__c statusInProgressWF = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusInProgress.Id,
            CMPL123__End_Status__c  = statusSentToVendor.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = compWFRule.Id,
            CMPL123__Is_Start_Step__c = true),true);

        //Query RecordType
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        String transTaskRecTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Text Translation').getRecordTypeId();

        //Create Complaint Record
        CMPL123CME__Complaint__c comp = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new
                                                                                                 CMPL123CME__Complaint__c(RecordTypeId = compRecTypeId,
                                                                                                                          CMSNext_Ticket_Number__c = '0600560C1333015'), true);

        //Create Vendor Record
        Translation_Vendor__c translationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new
                                                                                                        Translation_Vendor__c(Name = 'TranslationVendor',
                                                                                                                              Division__c = 'ADD',Status__c = 'Active',
                                                                                                                              Vendor_Email__c = 'Name123@test.com'),true );
        //Create Translation Task Record
        Translation_Task__c translationTaskRecord = (Translation_Task__c) TestDataFactory.createSObject(new
                                                                                                        Translation_Task__c(CMPL123_WF_Status__c = 'In Process', Vendor_Name__c = translationVendor.id,
                                                                                                                            RecordTypeId = transTaskRecTypeId,urgency__c = 'Urgent',Assignee_Name__c = u.id,
                                                                                                                            Parent_Ticket__c = comp.id),
                                                                                                        true );
       
       //Create Attachment__c Task Record
        Attachment__c att = (Attachment__c) TestDataFactory.createSObject(new Attachment__c(Name = 'TranslationItemAttachment',
                                                                                            Translation_Task__c = translationTaskRecord.id,
                                                                                            Attachment_Type__c = 'Translation'

                                                                                           ),true );
        Attachment attach = (Attachment) TestDataFactory.createSObject(new Attachment(Name = 'Attachment-123',ParentId = att.id, Body = Blob.valueOf('Attachmentbody')) ,true);
        Attachment transTaskattachment = (Attachment) TestDataFactory.createSObject(new Attachment(Name = 'Attachment-123',ParentId = translationTaskRecord.id, Body = Blob.valueOf('Attachmentbody')) ,true);
    }

    /*
    * @Method       : addReviewFileTranslationControllerTest.
    * @Description  : To test the ADDReviewFileTranslationController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void addReviewFileTranslationControllerTest(){
        Test.startTest();
        //code coverage for ADDReviewFileTranslation controller
        PageReference translationPage = Page.ADDReviewFileTranslation;
        Translation_Task__c translationTask = [SELECT id,CMPL123_WF_Status__c,RecordTypeId,urgency__c,Vendor_Name__r.name,Vendor_Name__r.Vendor_Email__c,
                                               Email_Attachments__c,Vendor_Name__r.Division__c,Vendor_Name__r.Status__c,Task_Comments__c,
                                               Parent_Ticket__c FROM Translation_Task__c WHERE CMPL123_WF_Status__c = 'In Process' LIMIT 1 ];


        translationPage.getParameters().put('id', translationTask.id);
        Test.setCurrentPage(translationPage);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(translationTask);
        ADDReviewFileTranslationController pageController = new ADDReviewFileTranslationController(sc);

        List<ADDReviewFileTranslationController.attachmentInner> attachmentDetail = new List<ADDReviewFileTranslationController.attachmentInner>();
        attachmentDetail = pageController.attachmentDetails;

        for(ADDReviewFileTranslationController.attachmentInner att : attachmentDetail){
            att.isSelected = true;
        }
        pageController.sendForTranslation();
        Translation_Task__c transTaskSenttoVendor = [SELECT id,CMPL123_WF_Status__c,RecordTypeId,urgency__c,Vendor_Name__r.name,Vendor_Name__r.Vendor_Email__c,
                                               Email_Attachments__c,Vendor_Name__r.Division__c,Vendor_Name__r.Status__c,Task_Comments__c,
                                               Parent_Ticket__c FROM Translation_Task__c WHERE ID = :translationTask.id];
        System.assertEquals('Task sent to vendor', transTaskSenttoVendor.CMPL123_WF_Status__c);

        ApexPages.Standardcontroller scTaskSentToVendor = new ApexPages.Standardcontroller(transTaskSenttoVendor);
        ADDReviewFileTranslationController pageController1 = new ADDReviewFileTranslationController(scTaskSentToVendor);
        pageController.reviewTranslation();
        Translation_Task__c transTaskClosedDone = [SELECT CMPL123_WF_Status__c,CMPL123_WF_Action__c FROM Translation_Task__c WHERE ID = :translationTask.id];
        System.assertEquals('Closed-Done', transTaskClosedDone.CMPL123_WF_Status__c);
    }
}