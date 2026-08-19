/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS4TicketTriggerHandler_Test.
* @Why   : ADDS4TicketTriggerHandler_Test class for the ADDS4TicketTriggerHandler class.
* @When  : 15-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                15-OCT-2018           Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                13-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDS4TicketTriggerHandler_Test {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setup(){

        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

           // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c complaintRecord = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            Division__c  = 'ADD',
            pRE_Status__c  = 'Yes',
            Country_of_origin__c  = 'INDIA',
            RecordTypeId = complaintRTId,
            CMPL123CME__CMPL123_WF_Status__c  = 'Opened'
        ), true);

      }

    /*
    * @Method       : beforeUpdateTest.
    * @Description  : To test the ADDS4TicketTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    static testmethod void beforeUpdateTest(){

        Test.startTest();

        // Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,Name,Product_Ticket_List_Number__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = 'Yes' LIMIT 1];




        //Create Medical Evaluation
        CMPL123CME__Questionnaire__c question = (CMPL123CME__Questionnaire__c)TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
        										CMPL123CME__Complaint__c = complaint.Id),true);

        // Update Complaint
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done';

        try {
             TestDataFactory.updateSObject(complaint);
        }

        catch(Exception e){

            //Assert the error message was displayed
        	System.assert(e.getMessage().contains('User cannot close a tickets when open medical evaluations'));
        }

        Test.stopTest();

    }
}