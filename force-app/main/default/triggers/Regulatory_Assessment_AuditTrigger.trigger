/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Regulatory_Assessment_AuditTrigger
* @Why   : To Handles all the customization involved on Regulatory_Assessment__c object.
* @When  : 07-FEB-2019      
* @Where : From Regulatory_Assessment__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019                 Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger Regulatory_Assessment_AuditTrigger on Regulatory_Assessment__c (before insert,before update,before delete,after insert,after update,after delete){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c && ADDS4RiskManagementTriggerHandler.stopRecursionForClonedRecord == false) {
        new ADDRegulatoryAssessmentTriggerHandler().run();
    }
    
    /*
    if(trigger.isUpdate && trigger.isBefore){
        for(Regulatory_Assessment__c regassessment : trigger.new){
            
           if(regassessment.CMPL123_WF_Action__c == 'Reopen'){
                regassessment.Reopened_By__c = UserInfo.getName(); 
                regassessment.Reopen_Date__c  = System.now();
            }
            if(regassessment.CMPL123_WF_Action__c == 'Void'){
                regassessment.Voided_By__c  = UserInfo.getName(); 
                regassessment.Voided_On__c  = System.now();
            }
        }
    }
    */
    
}