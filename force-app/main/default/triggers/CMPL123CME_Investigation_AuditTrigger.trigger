/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : CMPL123CME_Investigation_AuditTrigger
* @Why   : To Handles all the customization involved on CMPL123CME__Investigation__c object.
* @When  : 07-FEB-2019	
* @Where : From 	CMPL123CME__Investigation__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			     07-FEB-2019		    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger CMPL123CME_Investigation_AuditTrigger on CMPL123CME__Investigation__c (before insert, before update,before delete,after insert,after update,after delete){
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {        
        TicketUtil.addTrace('CMPL123CME_Investigation_AuditTrigger');
        new ADDInvestigationHandler().run();

        // 28FEB19 - DEF#120 - Removed the Batch processing
        if(ComplaintTriggerHandler.systemProdEval) { return; }
        
        if(Trigger.isInsert ||  Trigger.isUpdate ){
            //TODO : below class Code is not correct
            EvaluationHandlerTemp temp = new EvaluationHandlerTemp();
            temp.afterEventHandler();
        }
        if (Trigger.isAfter) {
            ReportsRelatedDataUtil.updateComplaintWithInvestigationsData(Trigger.old, Trigger.new);
        }
    }
}