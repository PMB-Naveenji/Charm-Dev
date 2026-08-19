/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Hazard_Assessment_AuditTrigger
* @Why   : To Handles all the customization involved on Hazard_Assessment__c object.
* @When  : 07-FEB-2019	
* @Where : From Hazard_Assessment__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			    07-FEB-2019			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger Hazard_Assessment_AuditTrigger on Hazard_Assessment__c (before insert,before update,before delete,after insert,after update,after delete){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c && ADDS4RiskManagementTriggerHandler.stopRecursionForClonedRecord == false) {
        new ADDHazardAssessmentTriggerHandler().run();
    }
    
}