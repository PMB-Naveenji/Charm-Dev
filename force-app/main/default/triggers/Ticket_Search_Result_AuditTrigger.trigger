/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Ticket_Search_Result_AuditTrigger
* @Why   : To Handles all the customization involved on Ticket_Search_Result__c object.
* @When  : 07-FEB-2019  
* @Where : From Ticket_Review__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                  07-FEB-2019              Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Ticket_Search_Result_AuditTrigger on Ticket_Search_Result__c (before insert,before update,before delete,after insert,after update,after delete){
//Commented to remove Before Insert Event. This is causing issue while saving records from Report SnapShot to Ticket Search Result object.

//trigger Ticket_Search_Result_AuditTrigger on Ticket_Search_Result__c (before update,before delete,after insert,after update,after delete){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDTicketSearchResultTriggerHandler().run();
    }
    
}