/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS4TicketTriggerHandler.
* @Why   : Handles all the customisation required on sprint 4 on Ticket and related child object.
* @When  : 23-MAR-2017.
* @Where : From CMPL123CME_Complaint_AuditTrigger trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				23-MAR-2017			   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 13-AUG-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDS4TicketTriggerHandler{
    /*
    * @Method       : beforeUpdateEventHandler.
    * @Description  : To throw error when med eval is not closed and user try to close the ticket.
    * @Invoke       : From CMPL123CME_Complaint_AuditTrigger trigger.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void beforeUpdateEventHandler(){
        if(Trigger.isUpdate){
            List<CMPL123CME__Complaint__c> newTickets = (List<CMPL123CME__Complaint__c>)Trigger.new;
            Map<Id,CMPL123CME__Complaint__c> oldComplaintsMap = (Map<Id,CMPL123CME__Complaint__c>)Trigger.oldMap;
            List<CMPL123CME__Questionnaire__c> medEvalsList = [SELECT Id, CMPL123CME__Complaint__c,
                CMPL123_WF_Status__c FROM CMPL123CME__Questionnaire__c
                WHERE (CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided') AND
                CMPL123CME__Complaint__c =: newTickets];
            for(CMPL123CME__Complaint__c newTicket : newTickets){
                if(newTicket.CMPL123CME__CMPL123_WF_Status__c !=
                    oldComplaintsMap.get(newTicket.Id).CMPL123CME__CMPL123_WF_Status__c&&
                    newTicket.CMPL123CME__CMPL123_WF_Status__c == 'Closed-Done' && medEvalsList.size() > 0){
                    newTicket.addError(System.Label.Ticket_Open_Medical_Evaluations);
                }
            }
        }
    }
}