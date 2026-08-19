/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Capgemini
* @What  : ContentDocumentTriggerEUMIR
* @Why   : To Handles all the customization involved on EUMIR Attachment 
* @When  : 27-AUG-2021
* @Where : From ContentDocument Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Varsha                27-AUG-2021               Charm Release 2       Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger ContentDocumentTriggerEUMIR on ContentDocumentLink (before Insert, before update, before delete, after Insert, after update,after delete) {
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ContentDocumentEUMIRTriggerHandler().run();
    }
}