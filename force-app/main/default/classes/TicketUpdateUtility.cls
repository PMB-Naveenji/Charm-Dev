/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : TicketUpdateUtility
* @Why   : Handles the updating of tickets
* @When  : 18-JAN-2019
* @Where : From ADDCustomAttachmentTriggerHandler class,  ADDInvestigationHandler class, ADDInvestigationTaskTriggerHandler class, ADDMDRequestTriggerHandler class,
ADDReturnTriggerHandler class, ADDTranslations class,  ADDTranslationTaskTriggerhandler class, 
ComplaintTriggerHandler class, TicketUpdateUtility class, Customer_Response_AuditTrigger Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin  				18-JAN-2019			   Work ID / Case ID     Created.
*      rsitc                05-JUNE-2020           #123/CHARM-2729       Adjusted return result of updateParentOnChildUpdate method
*      rsitc                22-JUNE-2020           #123.1/CHARM-2878       Removed custom Last Modified Date updating
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class TicketUpdateUtility {
    public static Boolean executeFlag = true;
    public static Boolean childToParentUpdateFlag = false;      // 30JAN19 - IssueID#170 - Fix for Child to Parent and Ready for Closure
    public static boolean medEvalTaskRunOnce = true;   // flag to stop recursive creation of med eval task.
    
    /**
* @Method       : updateParentOnChildUpdate
* @Invoke       : From ADDCustomActivityTriggerhandler class, ADDCustomAttachmentTriggerHandler class, ADDInvestigationHandler class, ADDInvestigationTaskTriggerHandler class,
ADDMDRequestTriggerHandler class, ADDReturnTriggerHandler class, ADDTranslationTaskTriggerhandler class,ComplaintTriggerHandler class,TicketUpdateUtility class,
Customer_Response_AuditTrigger Trigger
* @Description  : To update parent on child update
* @Return       : N/A
* @Params       : Set<Id> ticketIds
**/     
    // Def #123/CHARM-2729: changed void return result to set of ticket ids 
    public static Set<Id> updateParentOnChildUpdate(Set<Id> ticketIds){
        TicketUtil.addTrace('TicketUpdateUtility.updateParentOnChildUpdate' + ticketIds);
        // Def #123/CHARM-2729: added Set<Id> processedTicketIds
        Set<Id> processedTicketIds = new Set<Id>();
        // 31JAN19 No need to update the parent for creation
        if(ComplaintTriggerHandler.executeOnceBeforeInsert) { return processedTicketIds; }           
        // Remove the NULL from the Set
        if(ticketIds != null && ticketIds.size() > 0){
            ticketIds.remove(null);
        }else {
            return processedTicketIds;
        }
        
        User usr = [SELECT Profile_Name__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(usr.Profile_Name__c != 'ASPEN Integration' && usr.Profile_Name__c != 'System Administrator Data Loader' && ticketIds.size() > 0){
            List<CMPL123CME__Complaint__c> ticketList = new List<CMPL123CME__Complaint__c>();
            
            // 30JAN19 - IssueID#170 - Fix for Child to Parent and Ready for Closure
            TicketUpdateUtility.childToParentUpdateFlag = true;
            
            for(CMPL123CME__Complaint__c ticket 
                : [SELECT Id, Ready_to_Close__c, Ticket_Type__c, MDC_All_ACKs_Received__c, CMPL123Task_Key_Value__c, CMPL123CME__CMPL123_WF_Status__c, Division__c, CMSNext__c,
                   CMPL123CME__CMPL123_WF_Action__c,
                   (SELECT Id FROM CMPL123CME__Investigations__r WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed-Done' LIMIT 1),
                   (SELECT Id FROM Customer_Responses__r WHERE CMPL123_WF_Status__c != 'Closed-Voided' AND CMPL123_WF_Status__c != 'Closed-Done' LIMIT 1),
                   (SELECT Id FROM Returns__r WHERE CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided' LIMIT 1),
                   (SELECT Id FROM Evaluation_Investigation_Tasks__r WHERE CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided' LIMIT 1),
                   (SELECT Id FROM Meaningful_Data_Requests__r WHERE Request_Status__c != 'Completed' AND Request_Status__c != 'Voided' LIMIT 1),
                   (SELECT Id FROM Translation_Tasks__r WHERE CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided' LIMIT 1),
                   (SELECT Id FROM CMPL123CME__Questionnaires__r WHERE CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided' LIMIT 1)
                   FROM CMPL123CME__Complaint__c WHERE Id IN : ticketIds]) {
                       CMPL123CME__Complaint__c ticketRecord = new CMPL123CME__Complaint__c();
                       
                       // 26MAR19 - Added Ticket_Type__c field filter for DEF#628
                       // 02APR19 - Modified for handling all the auto promotion
                       if(ticket.Ticket_Type__c == 'Complaint') {
                           TicketUtil.addTrace('Complaint WF Status -> ' + ticket.CMPL123CME__CMPL123_WF_Status__c);
                           if (ticket.CMPL123CME__Investigations__r.size() == 0 && 
                               ticket.Evaluation_Investigation_Tasks__r.size() == 0 &&
                               ticket.Customer_responses__r.size() == 0 && 
                               ticket.Returns__r.size() == 0 && 
                               ticket.Meaningful_Data_Requests__r.size() == 0 && 
                               ticket.Translation_Tasks__r.size() == 0) {
                                   if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Opened' && ticket.MDC_All_ACKs_Received__c) {    // 15APR19 - Added MDC Check as fix for DEF#285
                                       ticketRecord.Ready_to_Close__c = 'Yes';
                                       ticketRecord.CMPL123Task_Key_Value__c = 'ComplaintComplete';     // 13MAR19 - Added as fix for DEF#285
                                   } else if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Complaint Complete' && ticket.CMSNext__c == 'Closed') {
                                       ticketRecord.CMPL123Task_Key_Value__c = 'FurtherRequired';
                                       // Call the batch job to update the Task Key Value to Promote to Final Review in Progress
                                   } else if(ticket.CMPL123CME__Questionnaires__r.size() == 0 && ticket.MDC_All_ACKs_Received__c) {
                                       if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Registration Closed') {
                                           ticketRecord.CMPL123Task_Key_Value__c = 'complaintrcfr';
                                           ticketRecord.Ready_to_Close__c = '';
                                           // Call a batch job to update the Task Key Value to Promote to Closed-Done
                                       } else if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Final Review In Progress' && ticket.Division__c == 'ADD') {
                                           ticketRecord.CMPL123Task_Key_Value__c = 'addautofra';
                                       }
                                   }
                                   // Added - 15MAY2019 - #944
                                   if(ticket.CMPL123CME__CMPL123_WF_Status__c == 'Complaint Complete' && ticketRecord.Ready_to_Close__c != 'Yes' && ticket.MDC_All_ACKs_Received__c) {
                                       ticketRecord.Ready_to_Close__c = 'Yes';
                                   }
                                   //TicketUpdateUtility.childToParentUpdateFlag = false;  // 12APR19 - MR - Validating CTH Looping
                               } else {
                                   ticketRecord.Ready_to_Close__c = 'No';
                               }
                       } else if(ticket.MDC_All_ACKs_Received__c 
                                 && ticket.CMPL123CME__CMPL123_WF_Status__c == 'Opened' 
                                 && ticket.Translation_Tasks__r.size() == 0 
                                 && ticket.Customer_Responses__r.size() == 0) {
                                     if(ticket.Ticket_Type__c == 'Inquiry' && ticket.CMSNext__c == 'Closed' && ticket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen' && ticket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen - Translation Required') { //15APR19 - added CMS Next Check, as per Visio
                                         ticketRecord.CMPL123Task_Key_Value__c = 'closeInquiry';
                                     } else if(ticket.Ticket_Type__c == 'Service' && ticket.CMPL123CME__Questionnaires__r.size() == 0 && ticket.CMSNext__c == 'Closed' && ticket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen' && ticket.CMPL123CME__CMPL123_WF_Action__c != 'Reopen - Translation Required') {//15APR19 - added CMS Next Check, as per Visio
                                         ticketRecord.CMPL123Task_Key_Value__c = 'closeService';
                                     }
                                 }
                        // #123.1/CHARM-2878: avoid blind update if nothing is changed
                       if (ticketRecord.Ready_to_Close__c != null && (ticket.Ready_to_Close__c != ticketRecord.Ready_to_Close__c)
                            || ticketRecord.CMPL123Task_Key_Value__c != null 
                            && (ticket.CMPL123Task_Key_Value__c != ticketRecord.CMPL123Task_Key_Value__c)) {
                                ticketRecord.Id = ticket.Id;
                                // #123.1/CHARM-2878: Removed custom Last Modified Date updating
                                //ticketRecord.Last_Modified_Date_Time__c = System.now();
                                ticketList.add(ticketRecord);
                                // Def #123/CHARM-2729: add ticket id to set if ticket is going to be updated
                                processedTicketIds.add(ticket.Id);
                            }
                       
                   }
            UPDATE ticketList;
            // 30JAN19 - IssueID#170 - Fix for Child to Parent and Ready for Closure
            TicketUpdateUtility.childToParentUpdateFlag = false;
        }
        // Def #123/CHARM-2729: added return result
        return processedTicketIds;
    }
}