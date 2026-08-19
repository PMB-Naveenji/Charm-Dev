/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDUpdateRMHazardLevel.
* @Why   : Handles the customization involved on Hazard Assessment object.
* @When  : 23-MAR-2017.
* @Where : From ADDUpdateRMHazardLevel class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID              Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				23-MAR-2017			   Work ID / Case ID            Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 17-AUG-2020            Code Audit                   Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDUpdateRMHazardLevel{
    /*
    * @Method       : updateRMHazardLevel.
    * @Description  : To update hazard level on parent PMRA record.
    * @Invoke       : From N/A Process builder flow.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @InvocableMethod
    public static void updateRMHazardLevel(List<Hazard_Assessment__c> records){
       ADDS4HazardsAssessmentTriggerHandler.updateRiskLevelHandler(records, 'fieldChanged');
       Hazard_Assessment__c  objHazardAssesment= records[0];
       if(objHazardAssesment.CMPL123_WF_Status__c == 'Closed-Done'){
           ADDS4HazardsAssessmentTriggerHandler.updateRiskLevelHandler(records, 'workflowChanged');
       }
    }
}