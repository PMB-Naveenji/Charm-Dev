/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Return_AuditTrigger
* @Why   : To Handles all the customization involved on Return__c object.
* @When  : 07-FEB-2019	
* @Where : From Return__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			     07-FEB-2019			Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Return_AuditTrigger on Return__c (before insert,before update,before delete,after insert,after update,after delete) {
   
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('Return_AuditTrigger');
        new ADDReturnTriggerHandler().run();
        ReturnNotReturnedRationale returnNotReturnedRationaleObj = new ReturnNotReturnedRationale();
        ReturnTrackingNumber returnTrackingNumberObj = new ReturnTrackingNumber();
        ReturnThirdRequestedDate returnThirdRequestedDateObj = new ReturnThirdRequestedDate();

        // Note that these trigger conditions are the only conditions that the 3 customValidators
        // that are called currently care about.  If the trigger conditions in the validators change,
        // this code (or unit tests) may break.
        if (Trigger.isAfter && Trigger.isUpdate) {

            for (Integer i = 0; i < Trigger.new.size(); i++) {
                Return__c newVal = Trigger.new[i];
                Return__c old;
                //No trigger.old on insert
                if (Trigger.old != null) {
                    old = Trigger.old.size() <= i ? Trigger.old[i] : newVal;
                } else {
                    old = newVal;
                }
                returnNotReturnedRationaleObj.CustomValidation(old, newVal);
                returnTrackingNumberObj.CustomValidation(old, newVal);
                returnThirdRequestedDateObj.CustomValidation(old, newVal);
            }
        }
    }
}