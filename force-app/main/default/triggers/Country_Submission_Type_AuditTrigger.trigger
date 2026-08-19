/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Country_Submission_Type_AuditTrigger
* @Why   : To Handles all the customization involved on Country_Submission_Type__c object.
* @When  : 07-FEB-2019  
* @Where : From Country_Submission_Type__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger Country_Submission_Type_AuditTrigger on Country_Submission_Type__c (before update, 
    before delete, after insert, after update){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDCountrySubmissionTypeHandler().run();
    }
    
    
}