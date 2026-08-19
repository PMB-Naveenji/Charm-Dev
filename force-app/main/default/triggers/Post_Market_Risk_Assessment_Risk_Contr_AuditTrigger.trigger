/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Post_Market_Risk_Assessment_Risk_Contr_AuditTrigger.
* @Why   : Handles all the customization involved on Post_Market_Risk_Assessment_Risk_Contr__c object.
* @When  : 07-FEB-2019.
* @Where : From Post_Market_Risk_Assessment_Risk_Contr__c object events.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID                Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                   07-FEB-2019            Work ID / Case ID              Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   28-DEC-2020            TWD Upgrade issue              Added 'ADDS4RiskManagementTriggerHandler.executeLogicFromWFRules()'
*                                                                                   method calls.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

trigger Post_Market_Risk_Assessment_Risk_Contr_AuditTrigger on Post_Market_Risk_Assessment_Risk_Contr__c (before insert, before update, before delete,
                                                                                                            after insert, after update) {
    if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c && ADDS4RiskManagementTriggerHandler.stopRecursionForClonedRecord == false) {
        if (Trigger.isInsert && Trigger.isBefore) {
            // Place your code.
            ADDS4RiskManagementTriggerHandler.preventCloseIfActionTaskNotClosed();

            //  TWD Upgrade issue - Fix START
            ADDS4RiskManagementTriggerHandler.executeLogicFromWFRules();
            //  TWD Upgrade issue - Fix END
        }
        /* After Insert */
        else if (Trigger.isInsert && Trigger.isAfter) {
            CMPL123.AuditHandler.handleAudit();
        }
        /* Before Update */
        else if (Trigger.isUpdate && Trigger.isBefore) {
            Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> mapPostMarketRiskAsses = new Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> (Trigger.newMap);
            Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> oldMapPostMarketRiskAsses = new Map<Id,Post_Market_Risk_Assessment_Risk_Contr__c> (Trigger.oldMap);

            for (Post_Market_Risk_Assessment_Risk_Contr__c pMRAobj :mapPostMarketRiskAsses.values()) {
                //Clear Typographical Rejection Reason on Approve action
                if (pMRAobj.CMPL123_WF_Action__c == AspenConstants.STR_WF_Action_Approve
                        && pMRAobj.CMPL123_WF_Action__c != oldMapPostMarketRiskAsses.get(pMRAobj.Id).CMPL123_WF_Action__c) {
                    pMRAobj.Typographical_Rejection_Reason__c = '';
                    //pMRAobj.Reopening_Rationale__c = '';
                }

                // Added this code and deactivated the process builder for assigning the quality notes on PMRA
                if (pMRAobj.CMPL123_WF_Status__c != oldMapPostMarketRiskAsses.get(pMRAobj.Id).CMPL123_WF_Status__c
                        && pMRAobj.CMPL123_WF_Status__c == AspenConstants.STR_Closed_Done) {
                    pMRAobj.Quality_Notes__c = '';
                    //pMRAobj.Reopening_Rationale__c = '';
                }
            }

            ADDS4RiskManagementTriggerHandler.checkRegulatoryAssessmentCount(mapPostMarketRiskAsses, oldMapPostMarketRiskAsses);
            //ADDS4RiskManagementTriggerHandler.updateDateAndActionPerformedByFields(trigger.new);
            ADDS4RiskManagementTriggerHandler.preventCloseIfActionTaskNotClosed();
            ADDS4RiskManagementTriggerHandler.validateHazardAssessments(mapPostMarketRiskAsses, oldMapPostMarketRiskAsses);
            ADDS4RiskManagementTriggerHandler.checkAdditionalApprovalCount(mapPostMarketRiskAsses, oldMapPostMarketRiskAsses);
            //Added as part of defect #1324
            ADDS4RiskManagementTriggerHandler.setReopenRationale(mapPostMarketRiskAsses, oldMapPostMarketRiskAsses);
            ADDS4RiskManagementTriggerHandler.checkEditAccess(mapPostMarketRiskAsses, oldMapPostMarketRiskAsses);

            //  TWD Upgrade issue - Fix START
            ADDS4RiskManagementTriggerHandler.executeLogicFromWFRules();
            //  TWD Upgrade issue - Fix END

           /* User user = [Select Id, Profile.Name from User where Id =: UserInfo.getUserId()];
            if (user.Profile.Name != 'System Administrator') {

                ADDS4RiskManagementTriggerHandler.addFieldLocker(mapPostMarketRiskAsses, oldMapPostMarketRiskAsses);
            }*/

            CMPL123.AuditHandler.handleAudit();
        }
        /* After Update */
        else if (Trigger.isUpdate && Trigger.isAfter) {
            CMPL123.AuditHandler.handleAudit();

            for (Post_Market_Risk_Assessment_Risk_Contr__c risk :Trigger.new) {
                if (risk.Is_Cloned__c && risk.CreatedDate != risk.LastModifiedDate) {
                    risk.addError(System.Label.Post_Market_Risk_Assessment_Risk_Contr_Record_Locked);
                }
            }

            ADDS4RiskManagementTriggerHandler.cloneWhenReopen();
            System.debug('Post_Market_Risk_Assessment_Risk_Contr_AuditTrigger.AfterUpdate - Before calling autoCreateRiskAsstChildRecord method');
            ADDS4RiskManagementTriggerHandler.autoCreateRiskAsstChildRecord();
            ADDS4RiskManagementTriggerHandler.checkRiskAssessmentProduct();
            ADDS4RiskManagementTriggerHandler.checkHazardAssessment();

            /*if(Trigger.old[0].CMPL123_WF_Status__c != Trigger.new[0].CMPL123_WF_Status__c){
                ADDS4RiskManagementTriggerHandler.preventSubmitHazardAssessmentForApproval(Trigger.new[0]);
            }*/

            ADDS4RiskManagementTriggerHandler.preventSubmitHazardAssessmentForApproval();
            /*ADDS4RiskManagementTriggerHandler.autoPostWorkflowActions();*/
        }
        /* Before Delete */
        else if (Trigger.isDelete && Trigger.isBefore) {
            CMPL123.AuditHandler.handleAudit();
        }
        /* After Delete */
        else if (Trigger.isDelete && Trigger.isAfter) {
            // Place your code.
        }
    }
}