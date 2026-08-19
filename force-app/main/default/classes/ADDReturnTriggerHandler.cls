/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDReturnTriggerHandler
* @Why   : Handles all the customization involved on Return object.
* @When  : 06-APR-2017
* @Where : From Return_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                06-APR-2017            Work ID / Case ID     Created.
*      rsitc                22-JUNE-2020           #123.1/CHARM-2878     Adjusted Ticket Last Modified Date updating.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   06-JAN-2021            TWD Upgrade issue     Added Logic from WF rules is moved to apex
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDReturnTriggerHandler extends TriggerHandler {
    
/**
* @Method       : beforeInsert
* @Invoke       : Events from TriggerHandler before insert
* @Description  : To handle all the logic in before insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeInsert() {
        //TWD Upgrade issue start
		List <Return__c> lstReturnsNew = (List <Return__c>)Trigger.New;  
        wfLogic(lstReturnsNew, null);
        //TWD Upgrade issue end.
    }
    
/**
* @Method       : afterInsert
* @Invoke       : Events from TriggerHandler after insert
* @Description  : To handle all the logic in after insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterInsert() {
        // Def #123.1/CHARM-2878: added processedTicketIds
        Set<Id> processedTicketIds = new Set<Id>();
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        updateExternalID();
        if(TicketUpdateUtility.executeFlag){
            TicketUpdateUtility.executeFlag = false;
            Set<Id> parentIds = new Set<Id>();
            List< Return__c > newReturns = (List< Return__c >)Trigger.New;
            for(Return__c ret : newReturns){
                parentIds.add(ret.Ticket__c); 
            }
            if(parentIds != null && parentIds.size() > 0){
                // #123.1/CHARM-2878: set updateTicketCustomLastModifDate to true in order to update custom Last Modified date
                UpdateParentUtility.updateTicketCustomLastModifDate = true;
                // Call the utility method to update the parent
                processedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
            }       
        }
        // Def #123.1/CHARM-2878: update parent ticket standard and custom Last Modified Date fields
        UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, processedTicketIds, 'Ticket__c', true);    
    }

/**
* @Method       : beforeUpdate
* @Invoke       : Events from TriggerHandler before update
* @Description  : To handle all the logic in before update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeUpdate() {
         List< Return__c > lstReturnsNew = (List< Return__c >)Trigger.New;  
         Map<Id, Return__c > newReturnsMap = (Map<Id, Return__c >)Trigger.newMap;
         Map<Id, Return__c > oldReturnsMap = (Map<Id, Return__c >)Trigger.oldMap;
         for(Return__c objReturn : lstReturnsNew){
            if(String.isBlank(objReturn.Return_Id__c)){
                objReturn.Return_Id__c = objReturn.Id;
            }
        }
        setReopenRationale(newReturnsMap, oldReturnsMap);
        //TWD Upgrade issue start
        wfLogic(lstReturnsNew, oldReturnsMap);
        //TWD Upgrade issue end.
        //code which invokes 123Compliance platform audit and workflow code
         CMPL123.AuditHandler.handleAudit();
    }
    
/**
* @Method       : afterUpdate
* @Invoke       : Events from TriggerHandler after update
* @Description  : To handle all the logic in after update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterUpdate() {
        // Def #123.1/CHARM-2878: added processedTicketIds
        Set<Id> processedTicketIds = new Set<Id>();
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        
        List< Return__c > newReturns = (List< Return__c >)Trigger.New;
        Map<Id, Return__c > oldReturnMap = (Map<Id, Return__c >)Trigger.oldMap;
        Set<String> complaintIds = new Set<String>();
        Set<Id> parentIds = new Set<Id>();
        /*
        used to auto-promote event to complete status when all child are closed.
        W-1214 
        */       
        if(Trigger.isUpdate){
            for(Return__c returnRecord : newReturns){
                parentIds.add(returnRecord.Ticket__c);
                if(returnRecord.Ticket__c != null && (returnRecord.CMPL123_WF_Status__c == 'Closed-Done' 
                    || returnRecord.CMPL123_WF_Status__c == 'Closed-Void') && oldReturnMap != null
                    && returnRecord.CMPL123_WF_Status__c != oldReturnMap.get(returnRecord.Id).CMPL123_WF_Status__c){
                    complaintIds.add(returnRecord.Ticket__c);    
                }
            } 
            if(complaintIds.size() > 0)
                CustomerResponseTriggerHandler.processEligibleComplaintsToComplete(complaintIds);
        }
        if(TicketUpdateUtility.executeFlag && parentIds != null && parentIds.size() > 0){
            TicketUpdateUtility.executeFlag = false;
            // #123.1/CHARM-2878: set updateTicketCustomLastModifDate to true in order to update custom Last Modified date
            UpdateParentUtility.updateTicketCustomLastModifDate = true;
            // Call the utility method to update the parent
            processedTicketIds = TicketUpdateUtility.updateParentOnChildUpdate(parentIds);
        }
        // Def #123.1/CHARM-2878: update parent ticket standard and custom Last Modified Date fields
        UpdateParentUtility.updateTicketLastModifiedDate(Trigger.new, processedTicketIds, 'Ticket__c', true);    
    }

/**
* @Method       : beforeDelete
* @Invoke       : Events from TriggerHandler before delete
* @Description  : To handle all the logic in before delete event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeDelete() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }   
     
/**
* @Method       : afterDelete
* @Invoke       : Events from TriggerHandler after delete
* @Description  : To handle all the logic in after delete event
* @Return       : N/A
* @Params       : N/A
**/  
    public override void afterDelete() {
    }   
    
    private static void updateExternalID(){
      List< Return__c > lstReturnsNew = (List< Return__c >)Trigger.New;  
        List< Return__c > lstReturnstoUpdate = new List< Return__c >();
        for(Return__c objReturn : lstReturnsNew){
            if(String.isBlank(objReturn.Return_Id__c)){
                Return__c objReturnNew = new Return__c();
                objReturnNew.Id = objReturn.Id;
                objReturnNew.Return_Id__c = objReturn.Id;
                lstReturnstoUpdate.add(objReturnNew);
            }
        }
        if(lstReturnstoUpdate.size() > 0){
            update lstReturnstoUpdate;
        }
    }
    
    /**
    * @Method       : setReopenRationale
    * @Description  : used to set reopen rationale from workflow history 
    * @Return       : N/A
    * @Params       : Map<Id,Return__c> newRecordMap, 
    *                 Map<Id,Return__c> oldRecordMap 
    **/ 
    public static void setReopenRationale(Map<Id,Return__c> newRecordMap, 
                                          Map<Id,Return__c> oldRecordMap){
        Return__c oldRecord;
        Return__c newRecord;
        if(newRecordMap.keyset().size() == 1){
            for(Return__c sobj : newRecordMap.values()){
                newRecord = sobj;
                oldRecord = oldRecordMap.get(sobj.Id);
            }   
            if(newRecord.CMPL123_WF_Action__c != null && newRecord.CMPL123_WF_Action__c.containsIgnorecase('Reopen') 
                && newRecord.CMPL123_WF_Action__c != oldRecord.CMPL123_WF_Action__c){
                newRecord.Reopen_Rationale__c = ADDUtil.fetchReopenWorkflowHistory(newRecord.Id);
            }
        }
    }
    
    /**
    * @Method       : wfLogic
    * @Description  : Logic from WF rules that were disable. WF: Autoset Registration Number     
    * @Return       : N/A
    * @Params       : List <Return__c> returns, Map <Id, Return__c> oldReturnById
    **/ 
    public static void wfLogic(List <Return__c> returns, Map <Id, Return__c> oldReturnById){
    
        //TWD Upgrade issue start
        //WF: Autoset Registration Number
        Set <Id> ticketIds = new Set <Id>();
        Set <Id> actionPerformedByIds = new Set <Id>();
        
        for (Return__c ret: returns) {
            actionPerformedByIds.add(ret.CMPL123_WF_Action_Performed_By__c);
            if (oldReturnById == null){
                //WF: Update 123 workflow   
                ret.CMPL123Rule_Key_Value__c = 'RETURN_WORKFLOW';
                ticketIds.add(ret.Ticket__c);
            }
            
        }
        Map <Id, CMPL123CME__Complaint__c> ticketById = new Map <Id, CMPL123CME__Complaint__c>([SELECT CMSNext_Ticket_Number__c, RecordType.DeveloperName, Service_Type__c 
                                                                                                FROM CMPL123CME__Complaint__c 
                                                                                                WHERE Id in: ticketIds]);
        Map <Id, User> userById = new Map <Id, User>([SELECT FirstName, LastName
                                                    FROM User 
                                                    WHERE Id in: actionPerformedByIds]);                                                                                        
        for (Return__c ret: returns) {
            if (oldReturnById == null && ret.Ticket__c != null && ticketById.containsKey(ret.Ticket__c) && ticketById.get(ret.Ticket__c).CMSNext_Ticket_Number__c != null){
                if (ticketById.get(ret.Ticket__c).RecordType.DeveloperName == 'Complaint') {
                   ret.Registration_Number__c = ticketById.get(ret.Ticket__c).CMSNext_Ticket_Number__c +
                                             '(' + ticketById.get(ret.Ticket__c).RecordType.DeveloperName + ')';
                } else if (ticketById.get(ret.Ticket__c).RecordType.DeveloperName == 'Inquiry') {
                    ret.Registration_Number__c = ticketById.get(ret.Ticket__c).CMSNext_Ticket_Number__c +
                                             '(' + ticketById.get(ret.Ticket__c).RecordType.DeveloperName + ')';
                } else if (ticketById.get(ret.Ticket__c).RecordType.DeveloperName == 'Service') {
                    ret.Registration_Number__c = ticketById.get(ret.Ticket__c).CMSNext_Ticket_Number__c +
                                             '(' + ticketById.get(ret.Ticket__c).Service_Type__c + ' ' + 
                                              ticketById.get(ret.Ticket__c).RecordType.DeveloperName + ')';
                }
                
            }
            //WF: Workflow - Close  
            if (ret.CMPL123_WF_Action__c == 'Close' && (oldReturnById == null 
                || (oldReturnById != null && oldReturnById.get(ret.Id).CMPL123_WF_Action__c != ret.CMPL123_WF_Action__c))) {
                    ret.Reopened_By__c = null;
                    ret.Reopened_On__c = null;
                    ret.Closed_By__c = userById.get(ret.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' +
                                            userById.get(ret.CMPL123_WF_Action_Performed_By__c)?.LastName + ' ';
                    ret.Closed_On__c = ret.CMPL123_WF_Action_Performed_On__c;
                
            }
            //WF: Workflow - Reopen 
            if (ret.CMPL123_WF_Action__c == 'Reopen' && (oldReturnById == null 
                || (oldReturnById != null && oldReturnById.get(ret.Id).CMPL123_WF_Action__c != ret.CMPL123_WF_Action__c))) {
                    ret.Reopened_By__c = userById.get(ret.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' +
                                            userById.get(ret.CMPL123_WF_Action_Performed_By__c)?.LastName + ' ';
                    ret.Reopened_On__c = ret.CMPL123_WF_Action_Performed_On__c;
                    ret.Closed_By__c = null;
                    ret.Closed_On__c = null;
            }
        }
        //TWD Upgrade issue end
    }
}