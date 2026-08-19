/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3_LeverageInvestigationController.
* @Why   : Handles all the customization involved on ADDS3_LeverageInvestigation page.
* @When  : 23-MAR-2017.
* @Where : From ADDS3_LeverageInvestigation page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				  23-MAR-2017		    Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   04-JUN-2020           Code Audit                  Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020           Code Audit                  Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   12-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   07-SEP-2020           Code Audit                  Added 'escapeSingleQuotes()' method call.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS3_LeverageInvestigationController{
    public List< CMPL123CME__Investigation__c > results{get;set;} // search results
    public string searchText{get;set;} //search keyword
    public string recordId{get;set;}
    public string selectedInvestigationId{get;set;}
    public Boolean isSuccess{set;get;}

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the class variables.
    * @Invoke       : From ADDS3_LeverageInvestigation page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public ADDS3_LeverageInvestigationController() {
        isSuccess = false;
        recordId = System.currentPageReference().getParameters().get('id');
        searchText = System.currentPageReference().getParameters().get('lksrch');
        runSearch();
    }

    /*
    * @Method       : search.
    * @Description  : To perform the keyword search.
    * @Invoke       : From ADDS3_LeverageInvestigation Page.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference search() {
        runSearch();
        return null;
    }

    /*
    * @Method       : runSearch.
    * @Description  : To run search by calling performSearch method.
    * @Invoke       : From ADDS3_LeverageInvestigation Page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private void runSearch() {
        //TODO prepare query string for complex searches & prevent injections
        results = performSearch(searchText);
    }

    /*
    * @Method       : performSearch.
    * @Description  : To perform the search and return the list of records.
    * @Invoke       : From ADDS3OverrideSourceTicket class.
    * @Return       : List<CMPL123CME__Investigation__c>.
    * @Params       : string searchText.
    */
    public List<CMPL123CME__Investigation__c> performSearch(string searchText) {
        String queryString = 'SELECT Id, Name';
        Set<String> defaultFields = new Set<String>{ 'Id' };

        for (Schema.FieldSetMember f :SObjectType.CMPL123CME__Investigation__c.FieldSets.ADDS3_Leverage_Investigation_Search.getFields()) {
            if (!defaultFields.contains(f.getFieldPath())) {
                queryString += ',' + f.getFieldPath() ;
            }
        }

        String WF_Status = 'Closed-Done';

        queryString = queryString + ' FROM CMPL123CME__Investigation__c';
        queryString = queryString + ' WHERE CMPL123CME__Complaint__c != :recordId AND CMPL123_WF_Status__c = :WF_Status';

        if (searchText != '' && searchText != null) {
            queryString = queryString + ' AND (Name LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'';

            for (Schema.FieldSetMember f :SObjectType.CMPL123CME__Investigation__c.FieldSets.ADDS3_Leverage_Investigation_Search.getFields()) {
                if (f.getFieldPath() != 'Name' && String.valueOf(f.getType()) != 'REFERENCE'&& String.valueOf(f.getType()) != 'BOOLEAN'
                    && String.valueOf(f.getType()) != 'DATE' && String.valueOf(f.getType()) != 'DATETIME') {
                    queryString = queryString + ' OR ' + f.getFieldPath() + ' LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'' ;
                }
            }

            queryString = queryString + ')';
        }

        queryString = queryString + ' ORDER BY CreatedDate DESC LIMIT 25';

        return database.query(queryString);
    }

    /*
    * @Method       : leverageSelectedInvesigation.
    * @Description  : To handle leverage selected investigation.
    * @Invoke       : From ADDS3_LeverageInvestigation page.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference leverageSelectedInvesigation() {

        if(selectedInvestigationId != null && recordId != null){
            List<Ticket_Product_Evaluation_Investigation__c> ticketProductInvestigations = new List<Ticket_Product_Evaluation_Investigation__c>();
            Set<Id> setSelectedInvestigationIds = New Set<Id>();
            for(String investigationId : selectedInvestigationId.split(';')){
                setSelectedInvestigationIds.add(investigationId.split('-')[0]);
            }

            Map<Id, CMPL123CME__Investigation__c> mapInvestigations = New Map<Id, CMPL123CME__Investigation__c>([SELECT Id,Product_List_Numbers__c,Product_Lot_Numbers__c,Registration_Number__c FROM CMPL123CME__Investigation__c WHERE Id IN: setSelectedInvestigationIds]);

            for (String investigationId : selectedInvestigationId.split(';')) {
                String invId = investigationId.split('-')[0];
                String rationale;
                if(investigationId.substringAfter('-') != '' && investigationId.substringAfter('-').length() > 0){
                    rationale = investigationId.split('-')[1];
                String strSearchable = mapInvestigations.get(invId).Product_List_Numbers__c +'\n'+ mapInvestigations.get(invId).Product_Lot_Numbers__c+'\n'+ mapInvestigations.get(invId).Registration_Number__c;
                ticketProductInvestigations.add(new Ticket_Product_Evaluation_Investigation__c(Investigation_Evaluation__c = invId,
                    Leverage_Rationale__c = rationale, Ticket__c = recordId, Type__c = 'Leveraged', Searchable__c = strSearchable));
                }
            }
            try {
                insert ticketProductInvestigations;
                isSuccess = false;
            } catch (Exception exp) {
                ApexPages.addMessages(exp);
                isSuccess = true;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,Label.Ticket_Product_Evaluation_Investigation_Select_One));
            isSuccess = true;
        }
        return null;
    }
}