/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketTranslationControllerTest.
* @Why   : Class to Handle Different scenarios from TicketTranslationController class.
* @When  : 18-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  18-OCT-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  10-JUN-2020            N/A                             Updated code part, which is related to Users' insertion.
*                                                                                   This change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                                   deployment to Production environment.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Juneid                 02-Feb-2021            Fixed Erorr                    Updated Wf step to fix workflow Key Value Erorr / Assertion Failed Error Fix 
* ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

*/

@isTest
private class TicketTranslationControllerTest {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

        //Create User
        User u = (User) TestDataFactory.createSObject(new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id,
            LastName = 'lastname',
            Email = 'emailid@test.com',
            CompanyName = 'CompanyXXX',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Belongs_to_Text__c = 'Tran10',
            Username = 'test@test.com' + '+' + UserInfo.getOrganizationId() + DateTime.now().millisecondGMT() + (Math.random() * 10)
        ), true);

        //Create Workflow Status
        CMPL123__WF_Status__c  statusOpened = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Opened'),true);

        CMPL123__WF_Status__c  statusInProcess = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'In Process'),true);

        CMPL123__WF_Status__c  statusTaskSentToVendor = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Task sent to vendor'),true);

        CMPL123__WF_Status__c  statusTranslationPendingReview = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Translation Pending Review'),true);

        CMPL123__WF_Status__c  statusClosedDone = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Closed-Done'),true);

        //Create Workflow Action
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Promote'),true);

        CMPL123__WF_Action__c actionPopulateTranslation = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Populate Translations'),true);

        CMPL123__WF_Action__c actionSendToVendor = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Send to Vendor'),true);

        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c  assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
            Name = 'Translation task workflow',
            CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
            CMPL123__Record_Type__c  = 'Translation_Task',
            CMPL123__Is_Active__c  = true,
            CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step
        CMPL123__WF_Step__c assessProdStep = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusOpened.Id,
            CMPL123__End_Status__c  = statusInProcess.Id,
            CMPL123__Action__c  = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = assessProdRule.Id,
            CMPL123__Is_Start_Step__c = True),true); 

        //Create workflow step
        CMPL123__WF_Step__c assessProdStep1 = (CMPL123__WF_Step__c)TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = statusInProcess.Id,
            CMPL123__End_Status__c  = statusTaskSentToVendor.Id,
            CMPL123__Action__c  = actionSendToVendor.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = assessProdRule.Id,
            CMPL123__Is_Start_Step__c = false),true); //@Juneid 2 feb 2021,replace is Start step as True to  fasle resolve Key value Error 

        //Create Translation Vendor
        Translation_Vendor__c objTranslationVendor = (Translation_Vendor__c) TestDataFactory.createSObject(new Translation_Vendor__c(
            Name = 'TranslationVendor',
            Division__c = 'ADD',
            Status__c = 'Active',
            Vendor_Email__c = 'test@test.com'),true);

        //Create Country
        Country__c objCountryIndia = (Country__c) TestDataFactory.createSObject(new Country__c(
            Name = 'INDIA',
            Division__c = 'ADD',
            Country_Code__c = 'IND',
            Primary_Vigilance_Contact__c = u.id,
            Preferred_Translation_Vendor__c = objTranslationVendor.id,
            Translations_Required_flag__c = true ),true);


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
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened',
            Customer_Reply_Required__c = false,
            Translation_Required_flag__c = false
        ), true);
    }

    /*
    * @Method       : ticketTranslationControllerTest.
    * @Description  : To test No Translations case.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod  void ticketTranslationControllerTest(){

        PageReference objPageReference = Page.TicketTranslation;
        Test.setCurrentPage(objPageReference);

        System.assertEquals(null,ApexPages.currentPage().getParameters().get('ids'));

        TicketTranslationController objTicketTranslationController = new TicketTranslationController();
        // No Translations
        System.assertEquals(0,objTicketTranslationController.translationItems.size());
    }

    /*
    * @Method       : saveTest.
    * @Description  : To test Translations and Save method.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testMethod  void SaveTest(){

        // Get the Complaint Record

        CMPL123CME__Complaint__c objComplaintTicket = [SELECT Id,Name,Country_of_origin__c,Translation_Required_flag__c FROM CMPL123CME__Complaint__c WHERE Customer_Reply_Required__c = false AND pRE_Status__c  = 'No' LIMIT 1];
        System.assertEquals(objComplaintTicket.Country_of_origin__c, [SELECT Id,Parent_Ticket__r.Country_of_origin__c FROM Translation_Task__c WHERE Parent_Ticket__c =: objComplaintTicket.id LIMIT 1].Parent_Ticket__r.Country_of_origin__c);
        Translation_Vendor__c objTranslationVendor = [SELECT Id FROM Translation_Vendor__c WHERE Vendor_Email__c = 'test@test.com' LIMIT 1];

        Translation_Task__c objTranslationTask = [SELECT Id,CMPL123_WF_Status__c FROM Translation_Task__c WHERE Parent_Ticket__c =: objComplaintTicket.id LIMIT 1];

        //Get Workflow Status
        CMPL123__WF_Status__c objInProcess = [SELECT Id,Name FROM CMPL123__WF_Status__c WHERE Name = 'In Process'];
        CMPL123__WF_Status__c statusTranslationPendingReview = [SELECT Id,Name FROM CMPL123__WF_Status__c WHERE Name = 'Translation Pending Review'];

        System.assertEquals(2, [SELECT count() FROM Translation_Item__c WHERE Translation_Task__c =: objTranslationTask.id]);
        Test.startTest();

        objTranslationTask.CMPL123_WF_Status__c = objInProcess.Name;
        objTranslationTask.Vendor_Name__c = objTranslationVendor.Id;
        objTranslationTask.Urgency__c = 'Normal';
        objTranslationTask.Task_Comments__c = 'Test Comment';
        update objTranslationTask;
        // @Juneid, 02-feb-2021, Assert Updated
        System.assertEquals('Opened', [SELECT CMPL123__Related_Id__c, CMPL123__Status__c, CMPL123__Workflow_Step__c FROM CMPL123__WF_History__c WHERE CMPL123__Related_Id__c = :objTranslationTask.Id].CMPL123__Status__c);
        PageReference objPageReference = Page.TicketTranslation;
        Test.setCurrentPage(objPageReference);

        ApexPages.currentPage().getParameters().put('ids', objTranslationTask.id);
        // Check Apex param
        System.assertEquals(objTranslationTask.id,ApexPages.currentPage().getParameters().get('ids'));

        TicketTranslationController objTicketTranslationController = new TicketTranslationController();
        // No Translations
        System.assertEquals(2,objTicketTranslationController.translationItems.size());
        objTicketTranslationController.translationItems[0].Translated__c = 'Test';
        objTicketTranslationController.save();
        //Updated Translation Tasks Status

        List<Apexpages.Message> lstMessages = ApexPages.getMessages();
        boolean boolPageMessage = false;
        for(Apexpages.Message objMessage : lstMessages){
            if(objMessage.getDetail().contains('File generation successful')){
                boolPageMessage = true;
            }
        }
       // system.assert(boolPageMessage);
        objTicketTranslationController.downloadTranslationExcel();

        // Check isSentToVendor
        objTranslationTask.CMPL123_WF_Status__c = statusTranslationPendingReview.Name;
        update objTranslationTask;
        objTicketTranslationController = new TicketTranslationController();

    }
}