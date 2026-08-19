/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketFileTranslationControllerTest.
* @Why   : To test functionality of 'TicketFileTranslationController' class.
* @When  : 29-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  29-MAY-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                                   deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      	Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid                 02-FEB-2021            Error Fix                    		Fix Work flow key value , updat the workflow steo
* --------------------------------------------------------------------------------------------------------------------------------------
* Lakshman               09-FEB-2021             Error Fix                         	Error Fix
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
class TicketFileTranslationControllerTest {
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setupData() {
        User u = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id, //DCoffey 04-FEB-2021 Changed from 'Aspen User' because they do not have create permissions on Attachment__c obj
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

        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c) TestDataFactory.createSObject(new CMPL123__WF_Action__c(
            Name = 'Promote'
        ), true);

        CMPL123__WF_Rule__c compWFRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            Name = 'Translation task workflow',
            CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
            CMPL123__Record_Type__c = 'Translation_Task',
            CMPL123__Is_Active__c = true,
            CMPL123__Has_Multiple_Actions__c = true
        ), true);

        CMPL123__WF_Status__c statusInProgress = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'In Process'
        ), true);

        CMPL123__WF_Status__c statusTransPending = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'Translation Pending Review'
        ), true);

        CMPL123__WF_Status__c endstatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'Closed-Done'
        ), true);

        CMPL123__WF_Status__c statusSentToVendor = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
            Name = 'Task sent to vendor'
        ), true);

        CMPL123__WF_Step__c statusPendingWF = (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusTransPending.Id,
            CMPL123__End_Status__c = endstatus.Id,
            CMPL123__Action__c = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = compWFRule.Id,
            CMPL123__Is_Start_Step__c = false // update true to false
        ), true);

        CMPL123__WF_Step__c statusInProgressWF = (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusInProgress.Id,
            CMPL123__End_Status__c = statusSentToVendor.Id,
            CMPL123__Action__c = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = compWFRule.Id,
            CMPL123__Is_Start_Step__c = True//@Juneid 02 Feb 2021, Set to false
        ), true);

        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Ticket_Type__c = 'Complaint',
            CMPL123CME__CMPL123_WF_Status__c = 'Registration Closed'
        ), true);

        Translation_Vendor__c translationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new Translation_Vendor__c(
            Name = 'TranslationVendor',
            Division__c = 'ADD',
            Status__c = 'Active',
            Vendor_Email__c = 'name123@test.com'
        ), true);
        
        
        Translation_Task__c objTranslation = (Translation_Task__c) TestDataFactory.createSObject(new Translation_Task__c(
            Parent_Ticket__c = objComplaint.Id,
            Vendor_Name__c = translationVendor.id,
            Urgency__c = 'Urgent',
            Adhoc_Fields__c = 'Contact Name;Customer Name',
            Assignee_Name__c = u.id,
            Task_Comments__c = 'Comments',
            CMPL123_WF_Status__c = 'Closed-Done'
        ), true);
       

       
        Attachment__c objAttachment = (Attachment__c) TestDataFactory.createSObject(new Attachment__c(
          
            Name = 'Test',
            Attachment_Type__c = 'Customer Letter',
            Translation_Task__c = objTranslation.Id
        ), true);
       
  
        TestDataFactory.createSObject(new Attachment(
            Body = Blob.valueOf('AttBody'),
            Name = 'ManualAttachment.csv',
            ParentId = objAttachment.Id,
            ContentType = 'text/csv; charset=UTF-8'
        ), true);
  }
    /*
    * @Method       : customReportTest.
    * @Description  : To test 'TicketFileTranslationController' class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void customReportTest() {
        Test.startTest();

        Translation_Task__c translationTask = [SELECT Id FROM Translation_Task__c LIMIT 1];
        Attachment__c attachment = [SELECT Id, Translation_Task__c, Translation_Task__r.Ticket_Number__c, Translation_Task__r.Vendor_Name__r.Vendor_Email__c,
                                            Translation_Task__r.CMPL123_WF_Status__c, Name, Division__c, Translation_Task__r.Vendor_Name__c,
                                            Ticket_Number__c, Related_Ticket_Id__c, (SELECT Id, Name, BodyLength FROM Attachments)
                                        FROM Attachment__c
                                        WHERE Translation_Task__c = :translationTask.Id
                                        LIMIT 1];

        PageReference pageReference = Page.TicketFileTranslation;
        Test.setCurrentPage(pageReference);
        ApexPages.currentPage().getParameters().put('ids', translationTask.Id);
        TicketFileTranslationController controller = new TicketFileTranslationController();

        // Add inner attachment with isSelected = true
        controller.attachmentDetails.add(new ADDReviewFileTranslationController.attachmentInner(
            attachment.Name,
            attachment.Translation_Task__r.Ticket_Number__c, attachment.Id,
            attachment.attachments[0].Id, attachment.attachments[0].BodyLength,
            true, attachment.Translation_Task__c,
            attachment.attachments[0].Name, attachment.Translation_Task__c, 'Translation Task'
        ));

        controller.sendForTranslation();
        Translation_Task__c transTaskSenttoVendor = [SELECT CMPL123_WF_Status__c FROM Translation_Task__c WHERE ID = :translationTask.id];
        System.assertEquals('Task sent to vendor', transTaskSenttoVendor.CMPL123_WF_Status__c);

        // Run page for Translation_Task__c with  CMPL123_WF_Status__c = 'Task sent to vendor'
        ApexPages.currentPage().getParameters().put('ids', transTaskSenttoVendor.Id);
        controller = new TicketFileTranslationController();
        controller.sendForTranslation();
        System.assert(controller.isSentToVendor);

        // Run page with no ids
        ApexPages.currentPage().getParameters().put('ids', null);
        controller = new TicketFileTranslationController();
        controller.sendForTranslation();
        System.assert(controller.attachmentDetails.isEmpty());
        Test.stopTest();
    }
}