/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : pREQuestionListController.
* @Why   : To display the customized related list.
* @When  : 22-MAR-2017.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 22-MAR-2017         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 18-AUG-2020         Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 07-SEP-2020         Code Audit                        Added 'escapeSingleQuotes()' method call.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class PREQuestionListController {
    public List<pRE_Question__c> complaintChildren_pRE { set; get; }

    /*
    * @Method       : PREQuestionListController constructor.
    * @Description  : To ApexPages Standard Controller. Query the complaint related pRE question records with Answer field is yes.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    */
    public PREQuestionListController (ApexPages.StandardController controller) {
        String complaintRecordId = ApexPages.currentPage().getParameters().get('id');

        complaintChildren_pRE = new List<pRE_Question__c>();

        if (complaintRecordId != null) {
            String queryString = 'SELECT Id, Question_Category__c, Name, Answer__c';
            Set<String> defaultFields = new Set<String>{ 'Id', 'Question_Category__c', 'Name', 'Answer__c' };

            for (Schema.FieldSetMember f :SObjectType.pRE_Question__c.FieldSets.ADDS3_pRE_Question_List.getFields()) {
                if (!defaultFields.contains(f.getFieldPath())) {
                    queryString += ',' + f.getFieldPath();
                }
            }

            String answerValue = 'Y';

            queryString = queryString + ' FROM pRE_Question__c WHERE Answer__c = :answerValue AND pRE_Information__r.Complaint__c = :complaintRecordId';
            queryString = queryString + ' ORDER BY CreatedDate DESC';

            complaintChildren_pRE = Database.query(String.escapeSingleQuotes(queryString));
        }
    }
}