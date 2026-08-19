/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3_LeveragedTicketListController.
* @Why   : Handles all the customization involved on ADDS3_LeveragedTicketList page.
* @When  : 23-MAR-2017.
* @Where : From ADDS3_LeveragedTicketList page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				23-MAR-2017			   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 12-AUG-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 07-SEP-2020            Code Audit                  Added 'escapeSingleQuotes()' method call.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS3_LeveragedTicketListController {
    public List<Ticket_Product_Evaluation_Investigation__c> investigationChildren { set; get; }

    /*
    * @Method       : Constructor.
    * @Description  : To initialize class variables.
    * @Invoke       : From ADDS3_LeveragedTicketList page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    */
    public ADDS3_LeveragedTicketListController(ApexPages.StandardController controller) {
        String investigationRecordId = ApexPages.currentPage().getParameters().get('id');

        investigationChildren = new List<Ticket_Product_Evaluation_Investigation__c>();

        if (investigationRecordId != null) {
            String queryString = 'SELECT Id, Ticket__c, Investigation_Evaluation__c, Name';
            String returnList = ApexPages.currentPage().getParameters().get('q');

            Set<String> defaultFields = new Set<String>{ 'Id', 'Ticket__c', 'Investigation_Evaluation__c', 'Name' };

            for (Schema.FieldSetMember f :SObjectType.Ticket_Product_Evaluation_Investigation__c.FieldSets.ADDS3_Custom_RL_Investigation_Layout.getFields()) {
                if (!defaultFields.contains(f.getFieldPath())) {
                    queryString += ',' + f.getFieldPath();
                }
            }

            //queryString = queryString.removeEnd(',');

            queryString = queryString + ' FROM Ticket_Product_Evaluation_Investigation__c WHERE Investigation_Evaluation__c = :investigationRecordId';

            if (returnList != null) {
                queryString = queryString + ' ORDER BY CreatedDate DESC';
            } else {
                queryString = queryString + ' ORDER BY CreatedDate DESC LIMIT 5';
            }

            investigationChildren = Database.query(String.escapeSingleQuotes(queryString));
        }
    }
}