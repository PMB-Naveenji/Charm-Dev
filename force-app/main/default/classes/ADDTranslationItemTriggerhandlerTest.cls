/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDTranslationItemTriggerhandlerTest.
* @Why   : ADDTranslationItemTriggerhandlerTest class for the ADDTranslationItemTriggerhandler class.
* @When  : N/A.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                N/A                    Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                06-JUN-2020            N/A                           Updated code part, which is related to Users' insertion. This
*                                                                           change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                           deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                14-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*  Juneid             27-Jan-2021            Error Fix                   	Updated the code to fix Workflow Key value Error
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
class ADDTranslationItemTriggerhandlerTest {
    /*
    * @Method       : testTranslationItemTriggerhandler.
    * @Description  : To test the ADDTranslationItemTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void testTranslationItemTriggerhandler() {
        User u = (User) TestDataFactory.createSObject(new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
                LastName = 'lastname',
                Email = 'test@test.com',
                Username = 'test@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10),
                CompanyName = 'CompanyXXX',
                Title = 'Title',
                Alias = 'Alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                Belongs_to_Text__c = 'Tran10'
        ), true);

        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
                Name = 'Promote'),true);

        CMPL123__WF_Rule__c  compWFRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
                Name = 'Translation task workflow',
                CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
                CMPL123__Record_Type__c  = 'Translation_Task',
                CMPL123__Is_Active__c  = true,
                CMPL123__Has_Multiple_Actions__c = true),true);

        CMPL123__WF_Status__c  Wf = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
                Name = 'Opened'),true);

        CMPL123__WF_Status__c  statusInProgress = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
                Name = 'In Process'),true);

        CMPL123__WF_Status__c  statusTransPending = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
                Name = 'Translation Pending Review'),true);

        CMPL123__WF_Status__c  endstatus = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
                Name = 'Closed-Done'),true);

        CMPL123__WF_Status__c  statusSentToVendor = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
                Name = 'Task sent to vendor'),true);

        CMPL123__WF_Step__c statusPendingWF = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = statusTransPending.Id,
                CMPL123__End_Status__c  = endstatus.Id,
                CMPL123__Action__c  = action.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__WF_Rule__c = compWFRule.Id,
                CMPL123__Is_Start_Step__c = false),true);//Juneid 27 Jan 2021, Set Step to false to fix Workflow key value Error

        CMPL123__WF_Step__c statusInProgressWF = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = statusInProgress.Id,
                CMPL123__End_Status__c  = statusSentToVendor.Id,
                CMPL123__Action__c  = action.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__WF_Rule__c = compWFRule.Id,
                CMPL123__Is_Start_Step__c = false),true);//Juneid 27 Jan 2021, Set Step to false to fix Workflow key value Error

        CMPL123__WF_Step__c openWfStep = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = wf.Id,
                CMPL123__End_Status__c  = statusInProgress.Id,
                CMPL123__Action__c  = action.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__WF_Rule__c = compWFRule.Id,
                CMPL123__Is_Start_Step__c = true),true);

        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        String transTaskRecTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Text Translation').getRecordTypeId();
        Account account = (Account) TestDataFactory.createSObject(new Account(Name = 'Accountname', Contact_Address_Line_1__c = '100 ABBOTT PK RD AP20',
                Contact_Address_Line_2__c = 'Abbott Park',
                City__c = 'NORTH CHICAGO',
                State__c = 'IL'), true);

        CMPL123CME__Complaint__c comp = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new
                CMPL123CME__Complaint__c(RecordTypeId = compRecTypeId,
                        CMSNext_Ticket_Number__c = '0600560C1333015', CMPL123CME__Customer__c = account.id), true);

        Translation_Vendor__c translationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new
                Translation_Vendor__c(Name = 'TranslationVendor',
                        Division__c = 'ADD', Status__c = 'Active',
                        Vendor_Email__c = 'test@test.com'), true);

        Translation_Task__c translationTaskRecord = (Translation_Task__c) TestDataFactory.createSObject(new
                Translation_Task__c(CMPL123_WF_Status__c = 'Opened', Vendor_Name__c = translationVendor.id,
                        RecordTypeId = transTaskRecTypeId,
                        urgency__c = 'Urgent',
                        Assignee_Name__c = u.id,
                        Adhoc_Fields__c = 'Contact Name;Customer Name;Customer State;Customer Address Line 1;Customer Address Line 2;Customer City',
                        Parent_Ticket__c = comp.id
                ), true);

        Account acc = (Account) TestDataFactory.createSObject(new Account(Name = 'Accountname'), true);

        Translation_Item__c translationItemRecord = (Translation_Item__c) TestDataFactory.createSObject(
                new Translation_Item__c(
                        Translation_Task__c = translationTaskRecord.Id,
                        Related_Record_Id__c = acc.id,
                        Translated__c = 'Kurihara Hospital',
                        Native__c = '栗原市立若柳病院\n',
                        Field_Name__c = 'Customer State'
                ), true);
        update translationItemRecord;
        delete translationItemRecord;
        System.assert(0 == [SELECT COUNT() FROM Translation_Item__c WHERE Id = : translationItemRecord.Id]);
    }

}