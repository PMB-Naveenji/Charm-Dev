/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDTicketReviewTriggerHandler
* @Why   : Handles all the customization involved on Ticket Note object.
* @When  : 06-APR-2017
* @Where : From Ticket_Review_AuditTrigger trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID            Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   06-APR-2017             Work ID / Case ID          Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   23-APR-2020             CHARM-2484 in scope of     Updated
*                                                   CHARM-2400 (Defect #67)
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                   15-06-2020              Code Audit                 Updated Jira reference with reference from Defect Tracker. 
*                                                                              Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   06-JAN-2021             TWD Upgrade issue          Added Logic from WF rules that are moved to apex
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDTicketReviewTriggerHandler extends TriggerHandler {
    
    /**
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeInsert() {
        //TWD Upgrade issue start
        List <Ticket_Review__c> newList = (List <Ticket_Review__c>)Trigger.New;       
        wfLogic(newList, null);
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
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
    }

    /**
    * @Method       : beforeUpdate
    * @Invoke       : Events from TriggerHandler before update
    * @Description  : To handle all the logic in before update event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void beforeUpdate() {
        //TWD Upgrade issue start
        List <Ticket_Review__c> newList = (List <Ticket_Review__c>)Trigger.New; 
        Map <Id, Ticket_Review__c> oldMap = (Map <Id, Ticket_Review__c>)Trigger.OldMap;       
        wfLogic(newList, oldMap);
        //TWD Upgrade issue end.
        //code which invokes 123Compliance platform audit and workflow code
        //Defect #67 (CHARM-2484) start
        CMPL123.AuditHandler.handleAudit();
        //Defect #67 (CHARM-2484) end
    }
    
    /**
    * @Method       : afterUpdate
    * @Invoke       : Events from TriggerHandler after update
    * @Description  : To handle all the logic in after update event
    * @Return       : N/A
    * @Params       : N/A
    **/ 
    public override void afterUpdate() {
        //code which invokes 123Compliance platform audit and workflow code
        CMPL123.AuditHandler.handleAudit();
        
        List<Ticket_Review__c> ticketReviews = (List<Ticket_Review__c>)Trigger.New;
        Map<Id,Ticket_Review__c> oldTicketReviewMap = (Map<Id,Ticket_Review__c>)Trigger.oldMap;
        Set<Id> parentAwarenessChangeIds = new  Set<Id>();
        Set<Id> followupAwarenessChangeIds = new  Set<Id>();
        for(Ticket_Review__c tr : ticketReviews){
            Ticket_Review__c oldTicketReview = oldTicketReviewMap.get(tr.Id);
            if(Trigger.oldMap != null && tr.Parent_Awareness_Date__c != oldTicketReview.Parent_Awareness_Date__c){
            	parentAwarenessChangeIds.add(tr.Id);   
            }
            if(Trigger.oldMap != null && tr.Follow_Up_Awareness_Date__c != oldTicketReview.Follow_Up_Awareness_Date__c){
            	followupAwarenessChangeIds.add(tr.Id);  
            }
        }
        if(parentAwarenessChangeIds.size() > 0 || followupAwarenessChangeIds.size() > 0){
            updateeMDRDueDateField(parentAwarenessChangeIds, followupAwarenessChangeIds);
        }
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
    
    /*
    * @Method       : updateeMDRDueDateField
    * @Description  : Method to Update Date Due field on EMDR on ticket review 
    * 				  on parent/follow-up awareness date field change.
    * @Return       : N/A
    * @Params       : Set of ticket review record Id's
    */
    public static void updateeMDRDueDateField(Set<Id> parentAwarenessChangeIds, Set<Id> followupAwarenessChangeIds){
        List<CMPL123CME__EMDR__c> lstEmdrDueDateToBeUpdated = new List<CMPL123CME__EMDR__c>();
        Integer emdrCalenderDays;
        if(parentAwarenessChangeIds.size() > 0 || followupAwarenessChangeIds.size() > 0){
        	Set<Id> combinedTicketReviewIds = new Set<Id>();
            combinedTicketReviewIds.addAll(parentAwarenessChangeIds);
            combinedTicketReviewIds.addAll(followupAwarenessChangeIds);
            for(CMPL123CME__EMDR__c emdr : [SELECT Id, RecordType.Name, CMPL123CME__MDR_Due_Date__c, Ticket_Review__c, 
                Ticket_Review__r.Parent_Awareness_Date__c, Submission_Type__c, Submission_Type__r.Calendar_Days__c, Ticket_Review__r.Follow_Up_Awareness_Date__c  FROM 
                CMPL123CME__EMDR__c WHERE Ticket_Review__c IN :combinedTicketReviewIds 
                AND (CMPL123CME__CMPL123_WF_Status__c = 'Opened' OR CMPL123CME__CMPL123_WF_Status__c = 'MFR Report # Generated')]){
                emdrCalenderDays = emdr.Submission_Type__c != null && emdr.Submission_Type__r.Calendar_Days__c != null 
                    ? Integer.valueOf(emdr.Submission_Type__r.Calendar_Days__c) : 0;
                if(emdr.RecordType.Name == 'Initial'){
                    if(emdr.CMPL123CME__MDR_Due_Date__c == null && parentAwarenessChangeIds.contains(emdr.Ticket_Review__c) && 
                        emdr.Ticket_Review__r.Parent_Awareness_Date__c != null && emdrCalenderDays != null ){
                        emdr.CMPL123CME__MDR_Due_Date__c = emdr.Ticket_Review__r.Parent_Awareness_Date__c + emdrCalenderDays;
                        lstEmdrDueDateToBeUpdated.add(emdr);
                    }
                }else{
                    if(emdr.CMPL123CME__MDR_Due_Date__c == null && followupAwarenessChangeIds.contains(emdr.Ticket_Review__c) 
                       && emdr.Ticket_Review__r.Follow_Up_Awareness_Date__c != null){
                       emdr.CMPL123CME__MDR_Due_Date__c = emdr.Ticket_Review__r.Follow_Up_Awareness_Date__c + 30;
                       lstEmdrDueDateToBeUpdated.add(emdr);
                    }
                }
            }
            if(lstEmdrDueDateToBeUpdated.size() > 0){
                update lstEmdrDueDateToBeUpdated;
            }
        }
    }
    /**
    * @Method       : wfLogic
    * @Description  : Logic from WF rules that were disabled.    
    * @Return       : N/A
    * @Params       : List <Ticket_Review__c> ticketReviews, Map <Id, Ticket_Review__c> oldReviewById
    **/ 
    public static void wfLogic(List <Ticket_Review__c> ticketReviews, Map <Id, Ticket_Review__c> oldReviewById){
        for (Ticket_Review__c ticketReview: ticketReviews) {
            //WF: Remove_Due_Date_On_Inactive_Review
            //Ticket Review is updated from Active to Inactive, remove due date.
            if (ticketReview.Status__c == 'Inactive' && (oldReviewById == null 
                || (oldReviewById != null && oldReviewById.get(ticketReview.Id).Status__c != ticketReview.Status__c))) {
                    ticketReview.Last_Search_Date__c = null;
            }
            //Restore Due Date On Active
            if (ticketReview.Status__c == 'Active' && ticketReview.Last_Search_Log_created_Date_Time__c != null && (oldReviewById == null 
                || (oldReviewById != null && oldReviewById.get(ticketReview.Id).Status__c != ticketReview.Status__c))) {
                    ticketReview.Last_Search_Date__c = date.valueOf(ticketReview.Last_Search_Log_created_Date_Time__c);
            }
        }
    }

}