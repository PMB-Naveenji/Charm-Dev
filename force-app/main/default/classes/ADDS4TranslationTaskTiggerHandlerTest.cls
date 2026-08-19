/*
* @why  : To Test all scenarios on the class ADDS4TranslationTaskTiggerHandler.
* @when : 06-AUG-2018.
* @what : ADDS4TranslationTaskTiggerHandlerTest test class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                    Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* oober                    10-JUN-2020            N/A                           Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME'
*	                                                                                error during deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                    Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue             Added 'executeLogicFromWFRulesTest()' method to test moved
*                                                                                   logic from Workflow Rules with Field Updates
*                                                                                   on Translation Task to Apex.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    15-JAN-2020            Code Audit                    Rewrote 'createTranslationTaskTestForComplaint()' and
*                                                                               'updateTranslationTaskTestForComplaint()' methods.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    05-FEB-2021            TWD Upgrade issue             Updated 'executeLogicFromWFRulesTest()' method.
* --------------------------------------------------------------------------------------------------------------------------------------
* Dinesh Kumar             16-SEP-2024            CHaRM R5/IPDR 620               Created 'createTranslationTaskTestForComplaint1'
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class ADDS4TranslationTaskTiggerHandlerTest {
    /*
    * @Method       : setup
    * @Description  : Creating records for Ticket object
    * @Return       : N/A
    * @Params       : N/A
    */
    @TestSetup
    static void setup() {
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

        User u = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'last',
            Email = 'test@test.com',
            Username = 'test@test.com' + '+' + Organization.Id + DateTime.now().millisecondGMT() + (Math.random() * 10),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10'
        ), true);

        Account objAccount = (Account) TestDataFactory.createSObject(new Account(
           Name = 'Test Account',
           Contact_Address_Line_1__c = 'Test Contact1',
           Contact_Address_Line_2__c = 'Test Contact2',
           City__c = 'Test City',
           State__c = 'Test State'
        ),true);

        //Create Workflow Status
        CMPL123__WF_Status__c  statusOpened = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Opened'),true);

        CMPL123__WF_Status__c  statusInProcess = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'In Process'),true);

        CMPL123__WF_Status__c  statusTaskSentToVendor = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Task sent to vendor'),true);

        CMPL123__WF_Status__c  statusClosedDone = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Closed-Done'),true);

        //Create Workflow Action
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Promote'),true);

        CMPL123__WF_Action__c actionPopulateTranslation = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
           Name = 'Populate Translations'),true);

        CMPL123__WF_Action__c actionSendToVendor = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
           Name = 'Send to Vendor'),true);

        CMPL123__WF_Status__c  actionReopen = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
           Name = 'Reopen'),true);

        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c  assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            Name = 'Translation task workflow',
            CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
            CMPL123__Record_Type__c  = 'Translation_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step for Prod Eval Assess
        CMPL123__WF_Step__c assessProdStep = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusOpened.Id,
            CMPL123__End_Status__c  = statusInProcess.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = assessProdRule.Id,
            CMPL123__Is_Start_Step__c = true),true);

        //Create Translation Vendor
        Translation_Vendor__c objTranslationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new Translation_Vendor__c(
            Name = 'Do Not Use',
        	Division__c = 'ADD',
        	Status__c = 'Active',
        	Vendor_Email__c = 'test@test.com'),
        	true);

        //Create Country
        Country__c objCountryIndia = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'INDIA',
            Division__c = 'ADD',
            Country_Code__c = 'IND',
            Language__c = 'English',
            Primary_Vigilance_Contact__c = u.id,
            Preferred_Translation_Vendor__c = objTranslationVendor.id,
            Translations_Required_flag__c = true ),
        	true);

        // Create Complaint of Ticket RecordType
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
            CMPL123CME__Customer__c = objAccount.Id,
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), true);

        // Create Attachment
        Attachment__c objAttachment = (Attachment__c) TestDataFactory.createSObject(new Attachment__c(Ticket__c = complaintTicket.Id , Attachment_Type__c = 'Translation'), true);
    }

    /*
    * @Method       : createTranslationTaskTestForComplaint
    * @Description  : Check whether Translation Task created or not and update Ticket
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void createTranslationTaskTestForComplaint(){
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(),
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Complaint',
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'INDIA',
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            CMSNext__c = 'Open',
            Registration_Ticket_Status__c = 'Open',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), true);

        Translation_Task__c objTranslationTask = [SELECT Id FROM Translation_Task__c WHERE Parent_Ticket__c = :complaintTicket.id AND (CMPL123_WF_Status__c = 'Opened') LIMIT 1];

        System.assertEquals(1, [SELECT count() FROM Translation_Task__c WHERE Parent_Ticket__c =: complaintTicket.id AND (CMPL123_WF_Status__c = 'Opened')]);
        System.assertEquals(2, [SELECT count() FROM Translation_Item__c WHERE Translation_Task__c = :objTranslationTask.id]);

        objTranslationTask.Vendor_Name__c = [SELECT Id, Name FROM Translation_Vendor__c WHERE Name = 'Do Not Use' LIMIT 1].Id;
        objTranslationTask.Urgency__c = 'Rush';
        objTranslationTask.Language__c = 'English';
        objTranslationTask.Assignee_Name__c = [SELECT Id FROM User WHERE LastName = 'last' LIMIT 1].Id;
        objTranslationTask.CMPL123_WF_Status__c = 'In Process';
        objTranslationTask.Adhoc_Fields__c = 'Customer Name';
        update objTranslationTask;

        Test.startTest();

        complaintTicket.Translation_Required_flag__c = false;
        update complaintTicket;

        System.assertEquals(1, [SELECT count() FROM Translation_Task__c WHERE Parent_Ticket__c = :complaintTicket.id]);

        delete [SELECT Id FROM CMPL123CME__Complaint__c WHERE Id = :complaintTicket.Id];

        Test.stopTest();
    }

    /*
    * @Method       : updateTranslationTaskTestForComplaint
    * @Description  : update Translation Task to 'Closed-Done'
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void updateTranslationTaskTestForComplaint(){
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(),
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Complaint',
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'INDIA',
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            CMSNext__c = 'Open',
            Registration_Ticket_Status__c = 'Open',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), true);

        Test.startTest();

        Translation_Task__c objTranslationTask = [SELECT Id
                                                    FROM Translation_Task__c
                                                    WHERE Parent_Ticket__c = :complaintTicket.Id
                                                        AND (CMPL123_WF_Status__c = 'Opened')
                                                    LIMIT 1];

        objTranslationTask.CMPL123_WF_Status__c = 'Closed-Done';
        update objTranslationTask;

        System.assertEquals(
            'Closed-Done',
            [SELECT CMPL123_WF_Status__c FROM Translation_Task__c WHERE Id = :objTranslationTask.Id].CMPL123_WF_Status__c
        );

        Test.stopTest();
    }
//CHaRM R5: Start
   /*
    * @Method       : createTranslationTaskTestForComplaint1
    * @Description  : Check the assert for language and vendor name auto-population in vendar task
    * @Return       : N/A
    * @Params       : N/A
    */
   
    @IsTest
    static void createTranslationTaskTestForComplaint1(){
        
        User usr = [SELECT Id FROM User WHERE LastName = 'last'];
        //Test case with Mixed cases for Country of Origin field from Complaint object
        CMPL123CME__Complaint__c complaintTicket = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            RecordTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(),
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Ticket_Description__c = 'test',
            CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
            Ticket_Type__c = 'Complaint',
            Description_of_Available_Returns__c = 'Returns Test',
            Country_of_origin__c  = 'ASIA PAC UNK-Instrument SN',
            Business_Unit__c  = 'IA-CC',
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            CMSNext__c = 'Open',
            Registration_Ticket_Status__c = 'Open',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = true
        ), true);
        System.debug('complaintTicket123'+ complaintTicket.Country_of_origin__c);
        
        Test.startTest();
        Translation_Vendor__c transVend = [Select id,Status__c,Name from Translation_Vendor__c where Name = 'Do Not Use' Limit 1];
        System.debug('transVend123'+ transVend);
        //Test case with all upper case for Name field from Country objecct
        Country__c objCountryIndia = new Country__c ();
            objCountryIndia.Name = 'ASIA PAC UNK-INSTRUMENT SN';
            objCountryIndia.Division__c = 'ADD';
            objCountryIndia.Country_Code__c = 'XXX';
            objCountryIndia.Language__c = 'English';
            objCountryIndia.Primary_Vigilance_Contact__c = usr.id;
            objCountryIndia.Preferred_Translation_Vendor__c = transVend.id;
            objCountryIndia.Translations_Required_flag__c = true ;
        Insert objCountryIndia;
        System.debug('objCountryIndia123'+ objCountryIndia);	
         
        String TransalationTaskRTId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Attachment Translation').getRecordTypeId();

        Translation_Task__c objTranslationTask = (Translation_Task__c)TestDataFactory.createSObject(new Translation_Task__c(
            RecordTypeId = TransalationTaskRTId,
            Assignee_Name__c = usr.Id ,
            Parent_Ticket__c = complaintTicket.Id,
            CMPL123Rule_Key_Value__c = 'Translation_Task',
            CMPL123_WF_Status__c = 'Opened'
        ), true);
       
       // objTranslationTask.CMPL123_WF_Status__c = 'Closed-Done';
      //  update objTranslationTask;
        System.assertEquals(
            'English',
            [SELECT Language__c FROM Translation_Task__c WHERE Id = :objTranslationTask.Id].Language__c
        );
        System.assertEquals(
            transVend.id,
            [SELECT Vendor_Name__c FROM Translation_Task__c WHERE Id = :objTranslationTask.Id].Vendor_Name__c
        );

        Test.stopTest();
    }
//CHaRM R5: End

    /*
    * @Method       : createAttachmentTranslation
    * @Description  : update Translation Task to 'Closed-Done'
    * @Return       : N/A
    * @Params       : N/A
    */
    @IsTest
    static void createAttachmentTranslation(){
        // Get the Complaint Record
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c WHERE Customer_Reply_Required__c = false AND pRE_Status__c  = 'No' LIMIT 1];

        //Get User
        User usr = [SELECT Id FROM User WHERE LastName = 'last'];

        // Create Translation Task
        String TransalationTaskRTId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Attachment Translation').getRecordTypeId();

        Translation_Task__c objTranslationTask = (Translation_Task__c)TestDataFactory.createSObject(new Translation_Task__c(
            RecordTypeId = TransalationTaskRTId,
            Assignee_Name__c = usr.Id ,
            Parent_Ticket__c = complaintTicket.Id,
            CMPL123Rule_Key_Value__c = 'Translation_Task',
            CMPL123_WF_Status__c = 'Opened'
        ), true);

        Test.startTest();
        // Update Transalation Task
        objTranslationTask.CMPL123_WF_Status__c = 'Closed-Done';
        objTranslationTask.CMPL123_WF_Action__c = 'Reopen';
        TestDataFactory.updateSObject(objTranslationTask);

        // Update Transalation Task
        objTranslationTask.CMPL123_WF_Status__c = 'In Process';
        TestDataFactory.updateSObject(objTranslationTask);

        // Update Transalation Task
        objTranslationTask.Adhoc_Fields__c = 'Customer Name';
        TestDataFactory.updateSObject(objTranslationTask);
        //Update Complaint
        complaintTicket.Translation_Required_flag__c = false;
        update complaintTicket;
        CMPL123CME__Complaint__c objComplaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c WHERE Customer_Reply_Required__c = false AND pRE_Status__c  = 'No' LIMIT 1];
        DELETE objComplaintTicket;
        Test.stopTest();
	}

    @IsTest
    static void executeLogicFromWFRulesTest() {
        CMPL123CME__Complaint__c complaint = [
            SELECT Id, CMSNext_Ticket_Number__c, RecordType.DeveloperName
            FROM CMPL123CME__Complaint__c
            WHERE Customer_Reply_Required__c = false
                AND pRE_Status__c  = 'No'
            LIMIT 1
        ];

        complaint.CMSNext_Ticket_Number__c = '056056FC1050021';
        update complaint;

        User usr = [SELECT Id FROM User WHERE LastName = 'last'];

        //Create Translation Vendor
        Translation_Vendor__c transVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new Translation_Vendor__c(
            Name = 'Test Vendor',
        	Division__c = 'ADD',
        	Status__c = 'Active',
        	Vendor_Email__c = 'test@test.com'
        ), true);

        Translation_Task__c objTranslationTask = (Translation_Task__c) TestDataFactory.createSObject(new Translation_Task__c(
            RecordTypeId = Schema.SObjectType.Translation_Task__c.getRecordTypeInfosByName().get('Attachment Translation').getRecordTypeId(),
            Assignee_Name__c = usr.Id ,
            Parent_Ticket__c = complaint.Id,
            CMPL123_WF_Status__c = 'Opened',
            Vendor_Name__c = transVendor.Id
        ), true);

        Translation_Task__c updatedTT = [SELECT Registration_Number__c FROM Translation_Task__c WHERE Id = :objTranslationTask.Id];

        System.assertEquals(
            complaint.CMSNext_Ticket_Number__c + '(' + complaint.RecordType.DeveloperName + ')',
            updatedTT.Registration_Number__c
        );

        String actionPerformedBy = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();

        Test.startTest();

        updatedTT.CMPL123_WF_Status__c = 'In Process';
        updatedTT.CMPL123_WF_Action__c = 'Promote';
        update updatedTT;

        updatedTT = [SELECT Assigned_Date__c, Promote_By__c
                                            FROM Translation_Task__c
                                            WHERE Id = :updatedTT.Id];

        System.assertEquals(actionPerformedBy, updatedTT.Promote_By__c);
        System.assertEquals(Date.today(), updatedTT.Assigned_Date__c);

        updatedTT.CMPL123_WF_Status__c = 'Opened';
        updatedTT.CMPL123_WF_Action__c = 'Request More Information';
        updatedTT.Request_More_Information_Provided__c = 'test';
        updatedTT.Request_More_Information__c = 'test test';
        update updatedTT;

        updatedTT = [SELECT CMPL123Task_Key_Value__c, Request_More_Information_Provided__c, Promote_By__c
                                            FROM Translation_Task__c
                                            WHERE Id = :updatedTT.Id];

        System.assertEquals('TranslationOpentoInprogress', updatedTT.CMPL123Task_Key_Value__c);
        System.assertEquals(null, updatedTT.Request_More_Information_Provided__c);
        System.assertEquals(null, updatedTT.Promote_By__c);

        updatedTT.CMPL123_WF_Status__c = 'In Process';
        updatedTT.CMPL123_WF_Action__c = 'Promote';
        update updatedTT;

        updatedTT.CMPL123_WF_Status__c = 'Task sent to vendor';
        updatedTT.CMPL123_WF_Action__c = 'Send to Vendor';
        update updatedTT;

        updatedTT = [SELECT Sent_to_Vendor_By__c
                                            FROM Translation_Task__c
                                            WHERE Id = :updatedTT.Id];

        System.assertEquals(actionPerformedBy, updatedTT.Sent_to_Vendor_By__c);

        updatedTT.CMPL123_WF_Status__c = 'Translation Pending Review';
        updatedTT.CMPL123_WF_Action__c = 'Translation Provided by Vendor';
        update updatedTT;

        updatedTT = [SELECT Vendor_Name__r.Name
                                            FROM Translation_Task__c
                                            WHERE Id = :updatedTT.Id];

        System.assertEquals(transVendor.Name, updatedTT.Vendor_Name__r.Name);

        updatedTT.CMPL123_WF_Status__c = 'In Process';
        updatedTT.CMPL123_WF_Action__c = 'Send Back to In Process';
        update updatedTT;

        updatedTT = [SELECT Translation_Provided_by_Vendor_By__c
                                            FROM Translation_Task__c
                                            WHERE Id = :updatedTT.Id];

        System.assertEquals(null, updatedTT.Translation_Provided_by_Vendor_By__c);

        updatedTT.CMPL123_WF_Status__c = 'Task sent to vendor';
        updatedTT.CMPL123_WF_Action__c = 'Send to Vendor';
        update updatedTT;

        updatedTT.CMPL123_WF_Status__c = 'Translation Pending Review';
        updatedTT.CMPL123_WF_Action__c = 'Translation Provided by Vendor';
        update updatedTT;

        updatedTT.CMPL123_WF_Status__c = 'Closed-Done';
        updatedTT.CMPL123_WF_Action__c = 'Populate Translations';
        update updatedTT;

        updatedTT = [SELECT Task_Completed_By__c
                                            FROM Translation_Task__c
                                            WHERE Id = :updatedTT.Id];

        System.assertEquals(actionPerformedBy, updatedTT.Task_Completed_By__c);

        updatedTT.CMPL123_WF_Status__c = 'In Process';
        updatedTT.CMPL123_WF_Action__c = 'Reopen';
        update updatedTT;

        updatedTT = [SELECT Reopened_By__c, Task_Completed_By__c, Translation_Provided_by_Vendor_By__c
                                            FROM Translation_Task__c
                                            WHERE Id = :updatedTT.Id];

        System.assertEquals(actionPerformedBy, updatedTT.Reopened_By__c);
        System.assertEquals(null, updatedTT.Task_Completed_By__c);
        System.assertEquals(null, updatedTT.Translation_Provided_by_Vendor_By__c);

        updatedTT.CMPL123_WF_Status__c = 'Closed-Voided';
        updatedTT.CMPL123_WF_Action__c = 'Void';
        update updatedTT;

        updatedTT = [SELECT Task_Completion_Date__c
                                            FROM Translation_Task__c
                                            WHERE Id = :updatedTT.Id];

        System.assert(updatedTT.Task_Completion_Date__c.isSameDay(DateTime.now()));

        Test.stopTest();
    }
}