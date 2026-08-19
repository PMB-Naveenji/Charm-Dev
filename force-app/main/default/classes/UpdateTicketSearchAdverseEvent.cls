/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateTicketSearchAdverseEvent.
* @Why   : global  class, used for updating the value of Is Ticket Adverse Event? field in
*          Ticket search if Ticket Was an adverse event identified field change.
* @When  : 12-FEB-2019.
* @Where : From UpdateTicketSearchResults Class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  12-FEB-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class UpdateTicketSearchAdverseEvent implements Database.Batchable<sObject> {
    // Boolean variable to store restrict validation rule
    global Boolean boolRestrictValidationRulesPriorStatus = null;
    List<Id> lstTicketIds = new List<Id>();

    /*
    * @Method       : UpdateTicketSearchAdverseEvent.
    * @Description  : Constructor.
    * @Invoke       : From UpdateTicketSearchAdverseEvent Class.
    * @Return       : N/A.
    * @Params       : List<Id> setTicketIds.
    */
    public UpdateTicketSearchAdverseEvent(List<Id> setTicketIds) {
        lstTicketIds = setTicketIds;
    }

    /*
    * @Method       : start.
    * @Invoke       : From UpdateTicketSearchAdverseEvent Class.
    * @Description  : Get Ticket Search records.
    * @Return       : Database.QueryLocator.
    * @Params       : Database.BatchableContext BC.
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, Is_Ticket_Adverse_Event__c,Ticket__r.Was_an_Adverse_Event_Identified__c, Ticket__c FROM Ticket_Search_Result__c WHERE Ticket__c IN : lstTicketIds');
    }

    /*
    * @Method       : execute.
    * @Invoke       : From UpdateTicketSearchAdverseEvent Class.
    * @Description  : process Ticket Search records.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<Ticket_Search_Result__c > lstScope.
    */
    global void execute(Database.BatchableContext BC, List<Ticket_Search_Result__c > lstScope){

        for(Ticket_Search_Result__c objTicketSearchResult : lstScope){
           objTicketSearchResult.Is_Ticket_Adverse_Event__c = objTicketSearchResult.Ticket__r.Was_an_Adverse_Event_Identified__c;
        }
        update lstScope;
    }

    /*
    * @Method       : finish.
    * @Invoke       : From UpdateTicketSearchAdverseEvent Class.
    * @Description  : finish process.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext BC) {
    }
}