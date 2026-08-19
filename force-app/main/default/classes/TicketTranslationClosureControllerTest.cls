/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketTranslationClosureControllerTest.
* @Why   : Class to handle different scenarios from TicketTranslationClosureController.
* @When  : 17-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  17-OCT-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  04-JUN-2020            Code Audit                      Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                  15-JUN-2020            Code Audit                      Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class TicketTranslationClosureControllerTest {
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

         //Create Workflow Status
        CMPL123__WF_Status__c  statusOpened = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Opened'),true);

        //Create Workflow Status
        CMPL123__WF_Status__c  statusInProcess = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'In Process'),true);

        //Create Workflow Status
        CMPL123__WF_Status__c  statusTranslationPendingReview = (CMPL123__WF_Status__c ) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
            Name = 'Translation Pending Review'),true);

            //Create Workflow Action
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c  ) TestDataFactory.createSObject(new CMPL123__WF_Action__c  (
            Name = 'Promote'),true);

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
            Translation_Required_flag__c = true
        ), true);
    }

    /*
    * @Method       : TicketTranslationClosureController_Test.
    * @Description  : Having translated values.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void testUpdateTranslations(){

        // Get the Complaint Record
        CMPL123CME__Complaint__c complaintTicket = [SELECT Id,Name,Translation_Required_flag__c FROM CMPL123CME__Complaint__c WHERE Customer_Reply_Required__c = false AND pRE_Status__c  = 'No' LIMIT 1];

        Translation_Task__c objTranslationTask = [SELECT Id,CMPL123_WF_Status__c FROM Translation_Task__c WHERE Parent_Ticket__c =: complaintTicket.id AND (CMPL123_WF_Status__c = 'Opened') LIMIT 1];

        //Get Workflow Status
        CMPL123__WF_Status__c statusTranslationPendingReview = [SELECT Id,Name FROM CMPL123__WF_Status__c WHERE Name = 'Translation Pending Review'];

        Test.startTest();
        List<Translation_Item__c> lstTranslationItemsNew = new List<Translation_Item__c>();

        // Translated Items to Approve/Review
        List<Translation_Item__c> lstTranslationItems = [SELECT Id,Field_Name__c,Translated__c FROM Translation_Item__c WHERE Translation_Task__c =: objTranslationTask.id];
        for(Translation_Item__c objTranslationItem : lstTranslationItems){
            if(objTranslationItem.Field_Name__c == 'Ticket Description') {
                objTranslationItem.Translated__c = 'Translated1';
            }
            else if(objTranslationItem.Field_Name__c == 'Description of Available Returns') {
                objTranslationItem.Translated__c = 'Translated2';
            }
            else {
                objTranslationItem.Translated__c = 'Translated3';
            }
            lstTranslationItemsNew.add(objTranslationItem);
        }
        update lstTranslationItemsNew;

        System.assertEquals(2, [SELECT count() FROM Translation_Item__c WHERE Translation_Task__c = :objTranslationTask.id]);
        Test.stopTest();

        objTranslationTask.CMPL123_WF_Status__c = statusTranslationPendingReview.Name;
        update objTranslationTask;

        PageReference objPageReference = Page.TicketTranslationClosure;
        Test.setCurrentPage(objPageReference);

        ApexPages.currentPage().getParameters().put('ids', objTranslationTask.id);
        // Check Apex param
        System.assertEquals(objTranslationTask.id,ApexPages.currentPage().getParameters().get('ids'));

        TicketTranslationClosureController objTicketTranslationClosureController = new TicketTranslationClosureController();

        //Validate count of Items with translated values
        System.assertEquals(2,objTicketTranslationClosureController.translationItems.size());
        objTicketTranslationClosureController.updateTranslations();
    }

    /*
    * @Method       : testUpdateTranslationsWithOutId.
    * @Description  : Not Having param.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void testUpdateTranslationsWithOutId(){

        PageReference objPageReference = Page.TicketTranslationClosure;
        Test.setCurrentPage(objPageReference);
        ApexPages.currentPage().getParameters().put('ids',null);

        System.assertEquals(null,ApexPages.currentPage().getParameters().get('ids'));

        TicketTranslationClosureController objTicketTranslationClosureController = new TicketTranslationClosureController();
        // No items having translated values
        System.assertEquals(0,objTicketTranslationClosureController.translationItems.size());
        objTicketTranslationClosureController.updateTranslations();

    }
}