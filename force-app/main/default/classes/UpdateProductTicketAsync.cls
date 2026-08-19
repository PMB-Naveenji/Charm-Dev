/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateProductTicketAsync.
* @Why   : Global class, used for updating the value of Reportable Confirmed Malfunction Description of Product Ticket from Product.
* @When  : 31-OCT-2018.
* @Where : From ADDProductTriggerhandler class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  31-OCT-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class UpdateProductTicketAsync implements Database.Batchable<sObject>{
    //To store the set of Product Ids
    private Set<Id> setProductIds = New Set<Id>();

    /*
    * @Method       : UpdateProductTicketAsync.
    * @Description  : Constructor.
    * @Invoke       : From ADDProductTriggerhandler Class.
    * @Return       : N/A.
    * @Params       : Set<Id> setProdIds.
    */
    public UpdateProductTicketAsync(Set<Id> setProdIds) {
        setProductIds = setProdIds;
    }

    /*
    * @Method       : start.
    * @Description  : Get Product Ticket records.
    * @Invoke       : From UpdateProductTicketAsync Class.
    * @Return       : Database.QueryLocator.
    * @Params       : Database.BatchableContext BC.
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,Reportable_Confirmed_Malfunction_Descrip__c,Product__r.Reportable_Confirmed_Malfunction_Descrip__c FROM Product_Ticket__c WHERE Event_Ticket__r.CMPL123CME__CMPL123_WF_Status__c != \'Closed-Done\' AND Event_Ticket__r.CMPL123CME__CMPL123_WF_Status__c != \'Closed-Voided\' AND Product__c != null AND Product__c IN: setProductIds';
        return Database.getQueryLocator(query);
    }

    /*
    * @Method       : execute.
    * @Description  : Updating the value of Reportable Confirmed Malfunction Description of Product Ticket from Product.
    * @Invoke       : From UpdateProductTicketAsync Class.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC, List<Ticket_Search_Result__c> lstScope.
    */
    global void execute(Database.BatchableContext BC, List<Product_Ticket__c> lstScope){
        List<Product_Ticket__c> lstProductTickets = New List<Product_Ticket__c>();
        for(Product_Ticket__c objProductTicket : lstScope){
            objProductTicket.Reportable_Confirmed_Malfunction_Descrip__c = objProductTicket.Product__r.Reportable_Confirmed_Malfunction_Descrip__c;
        }
        update lstScope;
    }

    /*
    * @Method       : finish.
    * @Description  : finish process.
    * @Invoke       : From UpdateProductTicketAsync Class.
    * @Return       : N/A.
    * @Params       : Database.BatchableContext BC.
    */
    global void finish(Database.BatchableContext BC) {
    }
}