/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Tracking_Trending_Review_Task_AuditTrigger
* @Why   : To Handles all the customization involved on Tracking_Trending_Review_Task__c object.
* @When  : 07-FEB-2019  
* @Where : From Tracking_Trending_Review_Task__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                  07-FEB-2019              Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                  29-DEC-2020              TWD Updgrade issue   Added before insert event.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Tracking_Trending_Review_Task_AuditTrigger on Tracking_Trending_Review_Task__c (before insert, before update,before delete,after insert,after update){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDTTReviewTaskTriggerhandler().run();
    }
}