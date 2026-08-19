/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : RelatedProductEvaluationListController.
* @Why   : Contoller to get the related Product Evaluation/Investigation List.
* @When  : 23-MAR-2017.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 23-MAR-2017         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 21-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 07-SEP-2020         Code Audit                        Added 'escapeSingleQuotes()' method call.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class RelatedProductEvaluationListController {
    public List<Task_Product_Evaluation_Investigation__c> childTasks { set; get; }
    public String investigationTaskId { set; get; }
    private ApexPages.StandardController standardController;

    /*
    * @Method       : RelatedProductEvaluationListController Constructor.
    * @Invoke       : Events from RelatedProductEvaluationListController.
    * @Description  : To handle Related Product Evaluation List Controller.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController standardController.
    */
    public RelatedProductEvaluationListController(ApexPages.StandardController standardController) {
        this.standardController = standardController;

        investigationTaskId = ApexPages.currentPage().getParameters().get('id');
        childTasks = new List<Task_Product_Evaluation_Investigation__c>();

        if (investigationTaskId != null) {
            String queryString = 'SELECT Id, Investigation_Evaluation__c, Task__c, Name, Source_Leveraged__c, Leverage_Rationale__c';
            String returnList = ApexPages.currentPage().getParameters().get('q');

            Set<String> defaultFields = new Set<String>{ 'Id', 'Investigation_Evaluation__c', 'Task__c', 'Name', 'Source_Leveraged__c', 'Leverage_Rationale__c' };

            for (Schema.FieldSetMember f :SObjectType.Task_Product_Evaluation_Investigation__c.FieldSets.Product_Investigation_Evaluation.getFields()) {
                if (!defaultFields.contains(f.getFieldPath())) {
                    queryString += ',' + f.getFieldPath();
                }
            }

            queryString = queryString + ' FROM Task_Product_Evaluation_Investigation__c WHERE Task__c =: investigationTaskId';
            if (returnList != null) {
                queryString = queryString + ' ORDER BY DESC';
            } else {
                queryString = queryString + ' ORDER BY CreatedDate DESC LIMIT 10';
            }

            childTasks = Database.query(String.escapeSingleQuotes(queryString));
        }
    }
}