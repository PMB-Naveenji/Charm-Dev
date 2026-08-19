/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS4HazardsAssessmentTriggerHandler.
* @Why   : Handles all the customization involved on Hazard Assessment object.
* @When  : 23-MAR-2017.
* @Where : From ADDHazardAssessmentTriggerHandler class, ADDS4HazardsAssessmentTriggerHandler class, ADDUpdateRMHazardLevel class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				23-MAR-2017			   Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 05-MAR-2019            Defect #425                 Added checkRMFCount() method.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                 11-AUG-2020            Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ADDS4HazardsAssessmentTriggerHandler{
    /*
    * @Method       : autoPostWorkflowActionsinRiskManagements.
    * @Description  : To handle auto post Workflow Action.
    * @Invoke       : From ADDHazardAssessmentTriggerHandler class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void autoPostWorkflowActionsinRiskManagements(){
        //Variable declarations
        List<Hazard_Assessment__c> newHazards = (List<Hazard_Assessment__c>)Trigger.new;
        Map<Id, Hazard_Assessment__c> oldHazardsMap = (Map<Id, Hazard_Assessment__c>)Trigger.oldMap;
        Set<String> riskManagementIds = new Set<String>();
        List<Post_Market_Risk_Assessment_Risk_Contr__c> updatedRiskManagements =
            new List<Post_Market_Risk_Assessment_Risk_Contr__c>();
        for(Hazard_Assessment__c newhazard : newHazards){
            if(newhazard.Post_Market_Risk_Assessment_Risk_Contr__c != null){
                riskManagementIds.add(newhazard.Post_Market_Risk_Assessment_Risk_Contr__c);
            }
        }
        List<Post_Market_Risk_Assessment_Risk_Contr__c> riskMangaments = [SELECT ID,
                                                                          CMPL123Task_Key_Value__c,CMPL123_WF_Status__c, Is_a_Risk_Evaluation_Required__c,
                                                                          Is_Opt_Risk_Control_Measure_Proposed__c,
                                                                          (SELECT ID, CMPL123_WF_Status__c,
                                                                           Post_Market_Risk_Assessment_Risk_Contr__c FROM Hazard_Assessments__r
                                                                           WHERE CMPL123_WF_Status__c != 'Closed-Done' AND CMPL123_WF_Status__c != 'Closed-Voided')
                                                                          FROM Post_Market_Risk_Assessment_Risk_Contr__c WHERE Id IN: riskManagementIds];
        if(Trigger.isUpdate){
            for(Post_Market_Risk_Assessment_Risk_Contr__c riskMangement : riskMangaments){

                Set<String> pendingParentHazards = new Set<String>();
                Set<String> pendingEvalHazards = new Set<String>();
                Set<String> riskEvals = new Set<String>();
                Set<String> closedHazards = new Set<String>();

                if(riskMangement.Hazard_Assessments__r.size() > 0){
                    for(Hazard_Assessment__c hazard : riskMangement.Hazard_Assessments__r){
                        if(riskMangement.CMPL123_WF_Status__c == 'Hazard Assessment In Process' &&
                           hazard.CMPL123_WF_Status__c == 'Pending Parent Hazard Assessment Approval'){
                               pendingParentHazards.add(hazard.Id);
                           }
                        if(riskMangement.CMPL123_WF_Status__c == 'Risk Evaluation In Process' &&
                           hazard.CMPL123_WF_Status__c == 'Pending Parent Risk Evaluation Approval'){
                               pendingEvalHazards.add(hazard.Id);
                           }
                        if(riskMangement.CMPL123_WF_Status__c == 'Hazard Assessment In Process' &&
                           (hazard.CMPL123_WF_Status__c == 'Risk Evaluation Background' ||
                            hazard.CMPL123_WF_Status__c == 'Pending Route')){
                                riskEvals.add(hazard.Id);
                            }
                        if(riskMangement.CMPL123_WF_Status__c == 'Risk Evaluation in Process' &&
                           (hazard.CMPL123_WF_Status__c == 'Closed-Voided' ||
                            hazard.CMPL123_WF_Status__c == 'Closed-Done')){
                                closedHazards.add(hazard.Id);
                            }
                    }
                    if(pendingParentHazards.size() == riskMangement.Hazard_Assessments__r.size()){
                        updatedRiskManagements.add(new Post_Market_Risk_Assessment_Risk_Contr__c(
                            id = riskMangement.Id,
                            CMPL123Task_Key_Value__c = 'SubmitHazard'
                        ));
                    }
                    if(pendingEvalHazards.size() == riskMangement.Hazard_Assessments__r.size()){
                        updatedRiskManagements.add(new Post_Market_Risk_Assessment_Risk_Contr__c(
                            id = riskMangement.Id,
                            CMPL123Task_Key_Value__c = 'RiskEval'
                        ));
                    }
                    if(riskEvals.size() == riskMangement.Hazard_Assessments__r.size()){
                        updatedRiskManagements.add(new Post_Market_Risk_Assessment_Risk_Contr__c(
                            id = riskMangement.Id,
                            CMPL123Task_Key_Value__c = 'SubmitRiskEval'
                        ));
                    }
                    if(closedHazards.size() == riskMangement.Hazard_Assessments__r.size()){
                        updatedRiskManagements.add(new Post_Market_Risk_Assessment_Risk_Contr__c(
                            id = riskMangement.Id,
                            CMPL123Task_Key_Value__c = 'RCMRecom'
                        ));
                    }
                }

            }
            if(updatedRiskManagements.size() >0){
                update updatedRiskManagements;
            }
        }
    }

    /*
    * @Method       : updateRiskLevelHandler.
    * @Description  : To update risk level in parent post market risk control object from child hazard assessment.
    * @Invoke       : From ADDUpdateRMHazardLevel class.
    * @Return       : N/A.
    * @Params       : List<Hazard_Assessment__c> records, String Changed.
    */
    public static void updateRiskLevelHandler(List<Hazard_Assessment__c> records, String Changed){
        Boolean excuted =  false;
        Hazard_Assessment__c updatableHazardAssessments;

        List<Integer> statusList = new List<Integer>();
        List<Integer> currentStatusList = new List<Integer>();
        Hazard_Assessment__c HA = records[0];
        Map<String,Integer> statusMap = new Map<String,Integer> {
            'High' => 1,
                'Medium' => 2,
                'Low' => 3
                };

                    statusList.clear();
        if(!excuted && HA.Post_Market_Risk_Assessment_Risk_Contr__c != null){
            for(Hazard_Assessment__c hazard : [Select Id, Health_Hazard_Risk_Level__c,
                                               Current_Residual_Risk_Level__c,
                                               Post_Market_Risk_Assessment_Risk_Contr__c FROM Hazard_Assessment__c
                                               WHERE Post_Market_Risk_Assessment_Risk_Contr__c =: HA.Post_Market_Risk_Assessment_Risk_Contr__c
                                               AND Health_Hazard_Risk_Level__c IN: statusMap.keyset()]){

                                                   if(statusMap.get(hazard.Health_Hazard_Risk_Level__c) != null){
                                                       statusList.add(statusMap.get(hazard.Health_Hazard_Risk_Level__c));
                                                       currentStatusList.add(statusMap.get(hazard.Current_Residual_Risk_Level__c));
                                                   }
                                               }
            if(changed == 'workflowChanged'){
                String overallStatus;
                statusList.sort();
                currentStatusList.sort();
                if(statusList.size() > 0){
                    if(statusList[0] == 1) {
                        overallStatus = 'High';
                    } else if(statusList[0] == 2){
                        overallStatus = 'Medium';
                    } else if(statusList[0] == 3){
                        overallStatus = 'Low';
                    }
                }
                else if(currentStatusList.size() > 0){
                    if(currentStatusList[0] == 1) {
                        overallStatus = 'High';
                    } else if(currentStatusList[0] == 2){
                        overallStatus = 'Medium';
                    } else if(currentStatusList[0] == 3){
                        overallStatus = 'Low';
                    }
                }
                else{
                    overallStatus = 'None';
                }
                if (overallStatus != null) {
                    update new Post_Market_Risk_Assessment_Risk_Contr__c(
                        Id = HA.Post_Market_Risk_Assessment_Risk_Contr__c,
                        Overall_Final_Risk_Level__c = overallStatus);
                    excuted = true;
                }
            }
        }
    }
    //W-000495 - The system shall not move Hazard Assessment from ‘Hazard Assessment in Process’ to ‘Pending Parent Hazard Assessment Approval’ status  without at least one RMF record
    /*
    * @Method       : checkRMFCount.
    * @Description  : To move process approvals on Hazard Assessment object.
    * @Invoke       : From ADDHazardAssessmentTriggerHandler class.
    * @Return       : N/A.
    * @Params       : Map<Id,Hazard_Assessment__c> mapHazardAssessments.
    */
    public static void checkRMFCount(Map<Id,Hazard_Assessment__c> mapHazardAssessments){
        //Added on 05 MAR 2019 for defect 425
        for(Hazard_Assessment__c objHazardAssessment : [SELECT Id, (SELECT Id FROM RMFs__r), CMPL123_WF_Status__c, For_delay_of_results_is_maximum_tolerab__c FROM Hazard_Assessment__c WHERE Id IN: mapHazardAssessments.keySet()]){
            if(objHazardAssessment.RMFs__r.size() == 0 && objHazardAssessment.CMPL123_WF_Status__c == 'Pending Parent Hazard Assessment Approval' && objHazardAssessment.For_delay_of_results_is_maximum_tolerab__c != 'No'){
                mapHazardAssessments.get(objHazardAssessment.Id).addError(System.Label.Hazard_Assessment_RMF_Required);
            }
        }

    }
}