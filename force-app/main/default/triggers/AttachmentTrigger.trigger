/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : AttachmentTrigger
* @Why   : To Handles all the customization involved on Attachment object.
* @When  : 07-FEB-2019	
* @Where : From Attachment object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			     07-FEB-2019		    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Dinesh Kumar    	     08-JAN-2025		    Updated the attachment Trigger to validate 200 Characters for individual file and 2000 
                                                    Characters for combined all files attached in Before and After Insert
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger AttachmentTrigger on Attachment (before Insert, before update, before delete, after Insert, after update,after delete) {

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDAttachmentTriggerhandler().run();
        
    }
    //CHaRM R6: Updated the attachment Trigger to validate 200 Characters for individual file and 2000 Characters for combined all files attached in Before and After Insert
    if(Trigger.isInsert && Trigger.isBefore)
 {        CMPL123CME.AttachmentHandler.validateAttachment(Trigger.new,new Map<Id,Attachment>());    }
 else if(Trigger.isUpdate && Trigger.isBefore)
 {        CMPL123CME.AttachmentHandler.validateAttachment(Trigger.new,Trigger.oldMap);    }
  
}