/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDTranslationTaskTriggerhandlerTest.
* @Why   : ADDTranslationTaskTriggerhandlerTest class for the ADDTranslationTaskTriggerhandler class.
* @When  : 04-SEP-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                04-SEP-2018            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                06-JUN-2020            N/A                           Updated code part, which is related to Users' insertion. This
*                                                                           change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                           deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                14-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDTranslationTaskTriggerhandlerTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){

        //Create User
        User u = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'lastname',
            Email = 'test1@test.com',
            Username = 'test1@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'CompanyXXX',
            Title = 'Title',
            Alias = 'Alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10'
        ), true);

        User u1 = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'lastname2',
            Email = 'test2@test.com',
            Username = 'test2@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'CompanyXXX2',
            Title = 'Title2',
            Alias = 'Alias2',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10'
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

        //Create  Workflow status with name = 'Opened'
        CMPL123__WF_Status__c  Wf = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Opened'),true);

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
            CMPL123__Is_Start_Step__c = false),true);

        //Create Workflow Step
        CMPL123__WF_Step__c statusInProgressWF = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusInProgress.Id,
            CMPL123__End_Status__c  = statusSentToVendor.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = compWFRule.Id,
            CMPL123__Is_Start_Step__c = false),true);

        CMPL123__WF_Step__c openWfStep = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = wf.Id,
            CMPL123__End_Status__c  = statusInProgress.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = compWFRule.Id,
            CMPL123__Is_Start_Step__c = true),true);


        //Query RecordType
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        String transTaskRecTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Text Translation').getRecordTypeId();
        Account account =   (Account) TestDataFactory.createSObject(new Account(Name = 'Accountname',Contact_Address_Line_1__c = '100 ABBOTT PK RD AP20',
                                                                                Contact_Address_Line_2__c = 'Abbott Park',
                                                                                City__c = 'NORTH CHICAGO',
                                                                                State__c = 'IL'),true );


        // Create Compliant record
        CMPL123CME__Complaint__c comp = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new
                                                                                                 CMPL123CME__Complaint__c(RecordTypeId = compRecTypeId,
                                                                                                                          CMSNext_Ticket_Number__c = '0600560C1333015',CMPL123CME__Customer__c = account.id), true);

        //Create Contact Record
        Contact__c conPrimary = new Contact__c();
        conPrimary.Ticket__c = comp.id;
        conPrimary.Primary__c = true;
        conPrimary.Delete_Flag__c = false;
        conPrimary.Name__c = 'ContactNAme';
        conPrimary.Occupation__c = 'Occupation';
        insert conPrimary;

        //Create T ranslationVendor Record
        Translation_Vendor__c translationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new
                                                                                                        Translation_Vendor__c(Name = 'TranslationVendor',
                                                                                                                              Division__c = 'ADD',Status__c = 'Active',
                                                                                                                              Vendor_Email__c = 'Name123@test.com'),true );
        //Create Translation Task Record
        Translation_Task__c translationTaskRecord = (Translation_Task__c) TestDataFactory.createSObject(new
                                                                                                        Translation_Task__c(CMPL123_WF_Status__c = 'Opened', Vendor_Name__c = translationVendor.id,
                                                                                                                            RecordTypeId = transTaskRecTypeId,urgency__c = 'Urgent',Assignee_Name__c = u.id,Adhoc_Fields__c = 'Contact Name;Customer Name;Customer State;Customer Address Line 1;Customer Address Line 2;Customer City',
                                                                                                                            Parent_Ticket__c = comp.id, Assigned_Date__c = system.today() - 1),
                                                                                                        true );
        //Create Country record
        Country__c objCountryIndia = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'INDIA',
            Division__c = 'ADD',
            Country_Code__c = 'IND',
            Language__c = 'English',
            Primary_Vigilance_Contact__c = u.id,
            Preferred_Translation_Vendor__c = translationVendor.id,
            Translations_Required_flag__c = true ), true);

        //Create Account Record
        Account acc =   (Account) TestDataFactory.createSObject(new Account(Name = 'Accountname'),true );

        CMPL123__AuditTrail_Config__c transItemAuditTrialConfig = (CMPL123__AuditTrail_Config__c)TestDataFactory.createSObject(new CMPL123__AuditTrail_Config__c(
            CMPL123__Fields__c = 'Field_Name__c',
            CMPL123__Is_Active__c = true,
            Name = 'Translation_Item__c'),true);

        //Create Translation Item Record
        Translation_Item__c translationItemRecord = (Translation_Item__c) TestDataFactory.createSObject(new
                                                                                                        Translation_Item__c( Translation_Task__c = translationTaskRecord.Id,Related_Record_Id__c = acc.id,Translated__c = 'Kurihara Hospital',Native__c = '栗原市立若柳病院\n',
                                                                                                                            Field_Name__c = 'Customer State'), true);

        //Create Translation Item Record
        Translation_Item__c transItemRecordEmpty = (Translation_Item__c) TestDataFactory.createSObject(new
                                                                                                       Translation_Item__c(Translation_Task__c = translationTaskRecord.Id,
                                                                                                                           Related_Record_Id__c = acc.id,Translated__c = 'Kurihara Hospital',Native__c = '栗原市立若柳病院\n',
                                                                                                                           Field_Name__c = ''),
                                                                                                       true);

    }

    /*
    * @Method       : testADDTranslationTaskTriggerHandlerTest.
    * @Description  : To test the ADDTranslationTaskTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void testADDTranslationTaskTriggerHandlerTest(){
        test.startTest();
        Translation_Item__c transItem = [SELECT ID,Translated__c,Field_Name__c  FROM Translation_Item__c WHERE Field_Name__c= 'Customer State' ];
        Translation_Task__c translationTaskRecord =  [SELECT id,CMPL123_WF_Action__c,CMPL123_WF_Status__c,Assigned_Date__c,(SELECT Field_Name__c,Translation_Task__r.CMPL123_WF_Status__c FROM  Translation_Items__r)urgency__c,Vendor_Name__r.name,Vendor_Name__r.Vendor_Email__c,
                                                      Parent_Ticket__r.CMPL123CME__Customer__c  FROM Translation_Task__c /*WHERE CMPL123_WF_Status__c = 'Opened'*/ LIMIT 1];

        CMPL123__WF_Step__c wfStep = [SELECT Id,CMPL123__Action__r.Name, CMPL123__End_Status__r.Name,
                                      CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c Where
                                      CMPL123__Start_Status__r.Name = 'Opened' AND CMPL123__End_Status__r.Name = 'In Process'
                                      AND CMPL123__WF_Rule__r.CMPL123__Record_Type__c = 'Translation_Task'];
        System.AssertEquals(translationTaskRecord.CMPL123_WF_Action__c,wfStep.CMPL123__Action__r.Name);
        String wfStatus = [SELECT CMPL123__Comment__c,CMPL123__Related_Id__c FROM CMPL123__WF_History__c  WHERE CMPL123__Related_Id__c = :translationTaskRecord.id LIMIT 1].CMPL123__Comment__c;
        //System.AssertEquals('Applied through task update',wfStatus);
        translationTaskRecord.CMPL123_WF_Status__c = 'Closed-Done';
        Update translationTaskRecord;
        translationTaskRecord.CMPL123_WF_Status__c = 'In Process' ;
        translationTaskRecord.CMPL123_WF_Action__c = 'Reopen';
        translationTaskRecord.CMPL123_WF_Action__c = 'Send Back to In Process';
        translationTaskRecord.Assigned_Date__c = system.today();
        translationTaskRecord.RecordTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Attachment Translation').getRecordTypeId();
        Update translationTaskRecord;
        translationTaskRecord.CMPL123_WF_Action__c = 'Send Back to In Process';
        update translationTaskRecord;
        translationTaskRecord.CMPL123_WF_Status__c = 'Opened';
        translationTaskRecord.Assignee_Name__c = [SELECT ID FROM User WHERE Username LIKE 'test2@test.com%'].id;
        update translationTaskRecord;
        translationTaskRecord.CMPL123_WF_Status__c = 'In Process';
        Contact__c con = [SELECT ID FROM Contact__c WHERE Primary__c = true];
        translationTaskRecord.Adhoc_Fields__c = 'Contact Occupation;Contact Name;Customer Name;Customer State;Customer Address Line 1;Customer Address Line 2;Customer City' ;
        Update translationTaskRecord;
        String transItemCusName  = [SELECT Field_Name__c, Native__c,Related_Record_Id__c FROM Translation_Item__c  WHERE Related_Record_Id__c = :translationTaskRecord.Parent_Ticket__r.CMPL123CME__Customer__c AND Field_Name__c = 'Customer Name'].Field_Name__c;
        System.assertEquals('Customer Name' , transItemCusName);
        String transItemConName  = [SELECT Field_Name__c, Native__c,Related_Record_Id__c FROM Translation_Item__c  WHERE Related_Record_Id__c = :con.id AND  Field_Name__c = 'Contact Name'].Field_Name__c;
        System.assertEquals('Contact Name' , transItemConName);
        String transItemConOcc  = [SELECT Field_Name__c, Native__c,Related_Record_Id__c FROM Translation_Item__c  WHERE Related_Record_Id__c = :con.id AND  Field_Name__c = 'Contact Occupation'].Field_Name__c;
        System.assertEquals('Contact Occupation' , transItemConOcc);
        String transItemCusAddL1  = [SELECT Field_Name__c, Native__c,Related_Record_Id__c FROM Translation_Item__c  WHERE Related_Record_Id__c = :translationTaskRecord.Parent_Ticket__r.CMPL123CME__Customer__c AND Field_Name__c = 'Customer Address Line 1'].Field_Name__c;
        System.assertEquals('Customer Address Line 1' , transItemCusAddL1);
        String transItemCusAddL2  =  [SELECT Field_Name__c, Native__c,Related_Record_Id__c FROM Translation_Item__c  WHERE Related_Record_Id__c = :translationTaskRecord.Parent_Ticket__r.CMPL123CME__Customer__c AND Field_Name__c = 'Customer Address Line 2'].Field_Name__c;
        System.assertEquals('Customer Address Line 2' , transItemCusAddL2);
        Delete translationTaskRecord;
        test.stopTest();
    }
}