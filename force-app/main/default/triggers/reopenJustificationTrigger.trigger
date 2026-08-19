/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : reopenJustificationTrigger
* @Why   : To Handles all the customization involved on Re_Open_Justification__c object.
* @When  : 07-FEB-2019	
* @Where : From Re_Open_Justification__c object Events
--------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			   07-FEB-2019			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger reopenJustificationTrigger on Re_Open_Justification__c (after insert, after update) {
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        
        ADDTranslations.ChildObjectTranslations();
        
    }
}