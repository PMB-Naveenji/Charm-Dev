/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : TicketSearchTriggerHandler
* @Why   : Handles all the customization involved on ADDTrend item maintainance request handler object.
* @When  : 06-JAN-2021
* @Where : From TicketSearchTrigger trigger
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:  
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                  Modification ID       Description 
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                    06-JAN-2021           TWD Upgrade issue     Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public class TicketSearchTriggerHandler extends TriggerHandler {
    /*
    * @Method       : beforeInsert
    * @Invoke       : Events from TriggerHandler before insert
    * @Description  : To handle all the logic in before insert event
    * @Return       : N/A
    * @Params       : N/A
    */
    public override void beforeInsert() {
        //TWD Upgrade issue start.
        List <Ticket_Serach__c> newSearches = (List <Ticket_Serach__c>) Trigger.new;
        Set <Id> evaluationInvestigationTaskIds = new Set <Id>();
        for (Ticket_Serach__c newSearch: newSearches) {
            evaluationInvestigationTaskIds.add(newSearch.Evaluation_Investigation_Task__c); 
        }
        Map <Id, Task__c> evalInvTaskById = new Map <Id, Task__c>([SELECT Related_Investigation_Evaluation__r.CMPL123CME__Complaint__r.Ticket_Description__c 
                                                                    FROM Task__c 
                                                                    WHERE Id in: evaluationInvestigationTaskIds]);
        for (Ticket_Serach__c newSearch: newSearches) {
            if (newSearch.Evaluation_Investigation_Task__c != null && evalInvTaskById.containsKey(newSearch.Evaluation_Investigation_Task__c)
                && evalInvTaskById.get(newSearch.Evaluation_Investigation_Task__c).Related_Investigation_Evaluation__r.CMPL123CME__Complaint__r.Ticket_Description__c != null) {
                    newSearch.Ticket_Description__c = evalInvTaskById.get(newSearch.Evaluation_Investigation_Task__c).Related_Investigation_Evaluation__r.CMPL123CME__Complaint__r.Ticket_Description__c;
            }
        }
        //TWD Upgrade issue end.
    }
}