/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : HealthHazardAssessmentReportController.
* @Why   : Groups records by entered 'field' method parameter.
* @When  : 17-MAY-2019.
* @Where : From PostMarketRiskEvalHealthHazardAssessment.page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    17-MAY-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    18-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    07-SEP-2020            Code Audit           Added 'escapeSingleQuotes()' method call.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class HealthHazardAssessmentReportController {
    private static final String IDS = 'ids';
    private static final String NAMES = 'names';

    /*
    * @Property     : healthHazardAssessments.
    * @Description  : Queries Health_Hazard_Assessment__c records if they weren't already queried.
    * @Invoke       : From PostMarketRiskEvalHealthHazardAssessment.page.
    * @Return       : List<Health_Hazard_Assessment__c>.
    * @Params       : N/A.
    */
    @TestVisible
    public List<Health_Hazard_Assessment__c> healthHazardAssessments {
        get {
            if (null == healthHazardAssessments) {
                List<Id> ids = getRecordsIdentifiers(IDS);
                List<String> names = getRecordsIdentifiers(NAMES);
                String query = 'SELECT Name,Potential_Harm__c, Current_Severity_Level__c, Probability_of_Occurrence_of_Harm__c,'
                                + ' Health_Hazard_Risk_Level__c, Health_Hazard_Risk_Rationale__c,'
                                + ' Hazard_Assessment__r.Secondary_Medical_Affairs_Assessor__r.Name,'
                                + ' Hazard_Assessment__r.Medical_Affairs_Assessor__r.Name,'
                                + ' Hazard_Assessment__r.Post_Market_Risk_Assessment_Risk_Contr__r.Version_Number__c,'
                                + ' Hazard_Assessment__r.Post_Market_Risk_Assessment_Risk_Contr__r.Name'
                            + ' FROM Health_Hazard_Assessment__c';

                query += getWhereClauseOrLimit(ids, names);

                healthHazardAssessments = Database.query(String.escapeSingleQuotes(query));
            }

            return healthHazardAssessments;
        }

        private set;
    }

    /*
    * @Property     : isDataAvailable.
    * @Description  : Checks if queried healthHazardAssessments isn't empty.
    * @Invoke       : From PostMarketRiskEvalHealthHazardAssessment.page.
    * @Return       : Boolean.
    * @Params       : N/A.
    */
    @TestVisible
    public Boolean isDataAvailable {
        get {
            if (null == isDataAvailable) {
                isDataAvailable = !healthHazardAssessments.isEmpty();
            }

            return isDataAvailable;
        }

        private set;
    }

    /*
    * @Method       : getWhereClauseOrLimit.
    * @Description  : Returns Limit or Where Clause basing on names or ids.
    * @Invoke       : From healthHazardAssessments property.
    * @Return       : Where Clause string.
    * @Params       : List<Id> ids, List<String> names.
    */
    @TestVisible
    private String getWhereClauseOrLimit(List<Id> ids, List<String> names) {
        if (!names.isEmpty()) {
            return ' WHERE Name IN :names';
        } else if (!ids.isEmpty()) {
            return ' WHERE Id IN :ids';
        }

        return ' LIMIT 150';
    }

    /*
    * @Method       : getRecordsIdentifiers.
    * @Description  : Parses url parameters.
    * @Invoke       : From healthHazardAssessments property.
    * @Return       : List<String>.
    * @Params       : String urlParamKey.
    */
    @TestVisible
    private List<String> getRecordsIdentifiers(String urlParamKey) {
        String urlParam = System.currentPageReference().getParameters().get(urlParamKey);
        if (String.isNotBlank(urlParam)) {
            return String.escapeSingleQuotes(urlParam.escapeJava()).split('[ ;,.]+');
        }

        return new List<String>();
    }
}