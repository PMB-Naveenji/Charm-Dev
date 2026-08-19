/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : TicketSearchTrigger  
* @Why   : To Handles all the customization involved on Re_Open_Justification__c object.
* @When  : 06-JAN-2021  
* @Where : From Ticket_Serach__c object Events
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:  
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description 
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                  06-JAN-2021              TWD Upgrade issue    Created
* --------------------------------------------------------------------------------------------------------------------------------------
*/
trigger TicketSearchTrigger on Ticket_Serach__c (before insert, before update,before delete,after insert,after update){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new TicketSearchTriggerHandler().run();
    }
}