/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : RiskAsstCustomReportController.
* @Why   : Class to get the related child records and display in the VF Page.
* @When  : 23-MAR-2017.
* @Where : From RiskAsstCustomReportController.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                        Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                        Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                        Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class RiskAsstCustomReportController {
    static final String IDS = 'ids';
    static final String NAMES = 'names';
    final SObjectType PMRA_TYPE = Schema.Post_Market_Risk_Assessment_Risk_Contr__c.SObjectType;
    final SObjectType HAZARD_ASSESSMENT_TYPE = Schema.Hazard_Assessment__c.SObjectType;
    final SObjectType REGULATORY_ASSESSMENT_TYPE = Schema.Regulatory_Assessment__c.SObjectType;
    final SObjectType ACTION_TASK_TYPE = Schema.Action_Task__c.SObjectType;
    final SObjectType ADDITIONAL_APPROVAL_TYPE = Schema.Additional_Approval__c.SObjectType;

    @TestVisible
    public List<PostMarketHAHHARMFWrapper> lstWrapPostMarketHAHHARMF {
        get;
        set;
    }

    @TestVisible
    public class PostMarketHAHHARMFWrapper {
        public Post_Market_Risk_Assessment_Risk_Contr__c objPostRisk {
            get;
            set;
        }
        public List<Hazard_Assessment__c> lstHAs {
            get;
            set;
        }
        public List<AttachmentWrapper> riskAttachments {
            get {
                if (null == riskAttachments) {
                    riskAttachments = new List<AttachmentWrapper>();
                }
                return riskAttachments;
            }
            private set;
        }
    }

    public class AttachmentWrapper  implements Comparable{
        public String name {
            get;
            set;
        }
        public String description {
            get;
            set;
        }

        public Integer compareTo(Object compareTo) {
            AttachmentWrapper compareToAttachment = (AttachmentWrapper) compareTo;
            if (name == compareToAttachment.name) return 0;
            if (name > compareToAttachment.name) return 1;
            return -1;
        }
    }

    /*
    * @Method       : RiskAsstCustomReportController.
    * @Description  : Constructor.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public RiskAsstCustomReportController() {
        generateReport();
    }

    /*
    * @Method       : generateReport.
    * @Description  : To generate risk asst report.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    void generateReport() {
        final List<Schema.SObjectType> objectsWithAttachments = new List<Schema.SObjectType>{
            PMRA_TYPE, HAZARD_ASSESSMENT_TYPE, REGULATORY_ASSESSMENT_TYPE,
            ACTION_TASK_TYPE, ADDITIONAL_APPROVAL_TYPE
        };
        lstWrapPostMarketHAHHARMF = new List<PostMarketHAHHARMFWrapper>();
        List<String> riskIds = getRecordsIdentifiers(IDS);
        List<String> riskNames = getRecordsIdentifiers(NAMES);
        String riskAssessmentsQuery = getQueryForRiskAssessments(riskIds, riskNames);
        List<Post_Market_Risk_Assessment_Risk_Contr__c> lstPostMarkets =
                Database.query(riskAssessmentsQuery + getWhereClause(riskIds, riskNames));

        Set<Id> setHAIds = new Set<Id>();
        Map<Id, Set<Id>> attachmentParentsIdsByPMRA = new Map<Id, Set<Id>>();
        Map<Schema.SObjectType, DescribeFieldResult> attachmentRelationDecriptionByType =
                getAttachmentRelationDescriptionByType(objectsWithAttachments);
        Map<Schema.SObjectType, Set<Id>> attachmentsParentsIdsByType =
                initializeAttachmentsParentIdsByTypeMap(attachmentRelationDecriptionByType);
        Map<Schema.SObjectType, String> childrenRelatioshipNames =  getChildrenRelatioshipNames(objectsWithAttachments);

        for (Post_Market_Risk_Assessment_Risk_Contr__c objPostMarketRiskAssessmentRisk : lstPostMarkets) {
            Set<Id> attachmentParentsIds = new Set<Id>{objPostMarketRiskAssessmentRisk.Id};
            for (SObjectType childType: childrenRelatioshipNames.keyset()) {
                Set<Id> childIds = getChildIds(objPostMarketRiskAssessmentRisk.getSObjects(
                        childrenRelatioshipNames.get(childType))
                );
                if (childIds.size() == 0) {
                    continue;
                }
                if (attachmentsParentsIdsByType.containsKey(childType)) {
                    attachmentsParentsIdsByType.get(childType).addAll(childIds);
                }
                attachmentParentsIds.addAll(childIds);
                if (childType == HAZARD_ASSESSMENT_TYPE) {
                    setHAIds = childIds;
                }
            }
            if (attachmentsParentsIdsByType.containsKey(PMRA_TYPE)) {
                attachmentsParentsIdsByType.get(PMRA_TYPE).add(objPostMarketRiskAssessmentRisk.Id);
            }
            attachmentParentsIdsByPMRA.put(objPostMarketRiskAssessmentRisk.Id, attachmentParentsIds);

        }

        List<Attachment__c> attachments =  queryAttachments(attachmentsParentsIdsByType,attachmentRelationDecriptionByType);
        Map<Id, List<Hazard_Assessment__c>> mapPMHAs = getHazardAssesmentsAndChildsByPMRA(setHAIds);
        for (Post_Market_Risk_Assessment_Risk_Contr__c objPostMarketRiskAssessmentRisk : lstPostMarkets) {
            PostMarketHAHHARMFWrapper objwrapPostMarketHAHHARMF = new PostMarketHAHHARMFWrapper();
            for (Attachment__c attachment : attachments) {
                List<AttachmentWrapper> attachmentWrappers = getAttachmentWrapperIfRelated(attachment,
                        attachmentParentsIdsByPMRA.get(objPostMarketRiskAssessmentRisk.Id),
                        attachmentRelationDecriptionByType.values());
                    objwrapPostMarketHAHHARMF.riskAttachments.addAll(attachmentWrappers);
            }
            objwrapPostMarketHAHHARMF.riskAttachments.sort();
                    objwrapPostMarketHAHHARMF.objPostRisk = objPostMarketRiskAssessmentRisk;
            objwrapPostMarketHAHHARMF.lstHAs = new List<Hazard_Assessment__c>();
            if (!mapPMHAs.isEmpty() && mapPMHAs.containsKey(objPostMarketRiskAssessmentRisk.Id)) {
                objwrapPostMarketHAHHARMF.lstHAs.addAll(mapPMHAs.get(objPostMarketRiskAssessmentRisk.Id));
            }
            lstWrapPostMarketHAHHARMF.add(objwrapPostMarketHAHHARMF);
        }
    }

    /*
    * @Method       : getQueryForRiskAssessments.
    * @Description  : Returns string query of PMRA with childs.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : String.
    * @Params       : List<Id> riskIds, List<String> riskNames.
    */
    String getQueryForRiskAssessments(List<Id> riskIds, List<String> riskNames) {
        return 'SELECT Id,Name,Division__c, Source__c,Source_Reference_Number__c,Short_Description_of_Issue__c,'
                + ' Quality_Assessor__r.Name, Site_Owner_New__c, Business_Unit__c, Hazard_Assessment_Approved_By__c,'
                + ' Recognition_Date__c, Closure_Date__c, Comments__c, Final_Senior_Management_Decision_Date__c,'
                + ' CMPL123_WF_Status__c, Version_Number__c, Description_of_Issue__c,' +
                +' Rationale_if_No_Hazards_Are_Identified__c, Potential_Hazard_Types_Associated_with_I__c,'
                + ' If_Other_Describe__c,Overall_Final_Risk_Level__c,Risk_Contorl_MeasureTo_Be_Taken__c,'
                + ' Is_HHR_greater_than_documented_in_RMF__c, Is_a_Risk_Control_Measure_Required__c,'
                + ' Is_Opt_Risk_Control_Measure_Proposed__c,Proposed_Risk_Control_Measure__c,'
                + ' Proposed_Risk_Control_Measure_Rationale__c, Reportability_Decision__c,'
                + ' Is_a_21_CFR_806_Report_required__c, Rationalle_for_Reportability_Decision__c,'
                + ' MDR_needed_for_reportable_RCM__c, Is_the_MDR_a_5_day_or_30_day_MDR__c,'
                + ' Risk_Control_Management_Decision_Date__c, QA_Manager_Approval_By__c,'
                + ' QA_Manager_Approval_On__c,Medical_Affairs_Approval_By__c, Medical_Affairs_Approval_On__c,'
                + ' Regulatory_Affairs_Approval_By__c, Regulatory_Affairs_Approval_On__c,'
                + ' Technical_Manager_Approval_By__c, Technical_Manager_Approval_On__c,Head_of_Quality_Approval_By__c,'
                + ' Head_of_Quality_Approval_On__c,Head_of_Medical_Affairs_Approval_By__c,'
                + ' Head_of_Medical_Affairs_Approval_On__c,Head_of_Regulatory_Affairs_Approval_By__c,'
                + ' Head_of_Regulatory_Affairs_Approval_On__c,Head_of_Technical_Approval_By__c,'
                + ' Head_of_Technical_Approval_On__c,DVP_Marketing_Approval_By__c,DVP_Marketing_Approval_On__c,'
                + ' DVP_Medical_Affairs_Approval_By__c,DVP_Medical_Affairs_Approval_On__c,'
                + ' DVP_Regulatory_Affairs_Approval_On__c,DVP_Quality_Assurance_Approval_By__c,'
                + ' DVP_Quality_Assurance_Approval_On__c,Director_Core_Global_Service_Ops_On__c,'
                + ' Director_Core_Global_Service_Ops_By__c, Initial_Hazard_Assessment_By__r.Name,'
                + ' Event_which_could_lead_to_a_hazard__c, Hazard_Assessment_Approved_On__c,'
                + ' Overall_Health_Hazard_Risk_Level__c, Risk_Evaluation_Quality_Approved_By__c,'
                + ' Risk_Evaluation_Exec_Quality_Approved_By__c,'
                + ' Risk_Evaluation_Quality_Approved_On__c, Risk_Evaluation_Exec_Quality_Approved_On__c,'
                + ' Risk_Control_Measure_Recommendation_Rati__c, DVP_Regulatory_Affairs_Approval_By__c,'
                + ' (SELECT Id FROM Hazard_Assessments__r), (SELECT Id, Name, Assignee__c,'
                + ' Assignee__r.Name, Impact_to_Labeling__c, Impact_to_Claims__c,'
                + ' Impact_to_Product_s_Intended_Use__c, Impact_to_Design_Reqs_Specs__c,'
                + ' Impact_to_a_US_Submission__c, Impact_to_an_International_Submission__c,'
                + ' Is_there_a_Regulatory_Impact__c, No_Regulatory_Impact_Rationale__c,'
                + ' Extent_of_Regulatory_Impact__c, Impact_to_Product_Performance__c,'
                + ' Additional_Descr_of_Regulatory_Impact__c,Existing_Mitigating_Factors__c, Approved_By__c,'
                + ' Approved_On__c, Completed_By__c, Completed_Date__c,'
                + ' CMPL123_WF_Status__c, Approved_On_GMT__c, Completed_Date_GMT__c FROM Regulatory_Assessments__r ),'
                + ' (SELECT Name, Batch_Lot_Serial__c, Product_Name__c, Product_List_Number__c FROM Risk_Assessment_Products__r),'
                + ' (SELECT Name, Action_Description__c, Action_Type__c, Other_Action_Type__c, Action_Activity_Completed__c,'
                + ' Action_Activity_Completion_Date__c, Completed_By__c, Completed_Date__c, CMPL123_WF_Status__c'
                + ' FROM Action_Tasks__r),'
                + ' (SELECT Approval_Type__c, Approve_By__c, Approve_On__c, Name, CMPL123_WF_Status__c'
                + ' FROM Additional_Approval__r)'
                + ' FROM Post_Market_Risk_Assessment_Risk_Contr__c';
    }

    /*
    * @Method       : getChildIds.
    * @Description  : Returns set of ids of all childs.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : Set<Id>.
    * @Params       : List<SObject> children.
    */
    Set<Id> getChildIds(List<SObject> children) {
        Set<Id> ids = new Set<Id>();
        if (null != children) {
            for (SObject child : children) {
                ids.add(child.Id);
            }
        }
        return ids;
    }

    /*
    * @Method       : getAttachmentWrapperIfRelated.
    * @Description  : Returns list of related AttachmentWrapper.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : List<AttachmentWrapper>.
    * @Params       : Attachment__c attachment, Set<Id> attachmentParentsIds, List<DescribeFieldResult> fields.
    */
    List<AttachmentWrapper> getAttachmentWrapperIfRelated(Attachment__c attachment, Set<Id> attachmentParentsIds,
            List<DescribeFieldResult> fields) {
        final SObjectField attachmentName = Attachment__c.Name.getDescribe().getSobjectField();
        final SObjectField attachmentDescription = Attachment__c.Attachment_Description__c.getDescribe().getSobjectField();
        final String parentObjectName = 'Name';
        List<RiskAsstCustomReportController.AttachmentWrapper> attachments =
                new List<RiskAsstCustomReportController.AttachmentWrapper>();
        attachmentParentsIds.remove(null);
        for (DescribeFieldResult fieldDescribe : fields) {
            if (attachmentParentsIds.contains((Id) attachment.get(fieldDescribe.getName()))) {
                RiskAsstCustomReportController.AttachmentWrapper attachmentWrapper =
                        new RiskAsstCustomReportController.AttachmentWrapper();
                attachmentWrapper.name = (String) attachment.get(attachmentName) + ', '
                        + (String) attachment.getSobject(fieldDescribe.getRelationshipName())
                        .get(parentObjectName);
                attachmentWrapper.description = (String) attachment.get(attachmentDescription);
                attachments.add(attachmentWrapper);
            }
        }
        return attachments;
    }

    /*
    * @Method       : getChildrenRelatioshipNames.
    * @Description  : Returns map of children relationship names.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : Map<Schema.SObjectType, String>.
    * @Params       : final List<Schema.SObjectType> childrenTypes.
    */
    Map<Schema.SObjectType, String> getChildrenRelatioshipNames(final List<Schema.SObjectType> childrenTypes) {
        Map<Schema.SObjectType, String> childrenRelatioshipNameToType = new Map<SObjectType, String>();
        Schema.DescribeSObjectResult PMRADescription = PMRA_TYPE.getDescribe();
        for (Schema.ChildRelationship childRelationship : PMRADescription.getChildRelationships()) {
            if (childrenTypes.contains(childRelationship.getChildSObject())
                    && childRelationship.getChildSObject() != PMRA_TYPE) {
                childrenRelatioshipNameToType.put(childRelationship.getChildSObject(),
                        childRelationship.getRelationshipName());
            }
        }
        return childrenRelatioshipNameToType;
    }

    /*
    * @Method       : queryAttachments.
    * @Description  : Returns list of queried attachments.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : List<Attachment__c>.
    * @Params       : Map<Schema.SObjectType,
    *                   Set<Id>> attachmentsParentsIdsByType,
    *                   Map<Schema.SObjectType,
    *                   DescribeFieldResult> attachmentRelationDecriptionByType.
    */
    List<Attachment__c> queryAttachments(Map<Schema.SObjectType, Set<Id>> attachmentsParentsIdsByType,
            Map<Schema.SObjectType, DescribeFieldResult> attachmentRelationDecriptionByType) {
        final String QUERY_FORMAT  = 'SELECT Name, Attachment_Description__c, {0} FROM Attachment__c WHERE {1}';
        // Variables initializing for dynamic binding in query
        Set<Id> hazardAssessmentAttacments = attachmentsParentsIdsByType.get(HAZARD_ASSESSMENT_TYPE);
        Set<Id> regulatoryAssessmentAttacments = attachmentsParentsIdsByType.get(REGULATORY_ASSESSMENT_TYPE);
        Set<Id> actionTaskAttacments = attachmentsParentsIdsByType.get(ACTION_TASK_TYPE);
        Set<Id> additionalApprovalAttacments = attachmentsParentsIdsByType.get(ADDITIONAL_APPROVAL_TYPE);
        Set<Id> pmraAttachments = attachmentsParentsIdsByType.get(PMRA_TYPE);

        List<String> whereConditionmembers = new List<String>{
                attachmentRelationDecriptionByType.get(PMRA_TYPE).getName() + ' IN :pmraAttachments',
                attachmentRelationDecriptionByType.get(HAZARD_ASSESSMENT_TYPE).getName() + ' IN :hazardAssessmentAttacments',
                attachmentRelationDecriptionByType.get(REGULATORY_ASSESSMENT_TYPE).getName() + ' IN :regulatoryAssessmentAttacments',
                attachmentRelationDecriptionByType.get(ACTION_TASK_TYPE).getName() + ' IN :actionTaskAttacments',
                attachmentRelationDecriptionByType.get(ADDITIONAL_APPROVAL_TYPE).getName() + ' IN :additionalApprovalAttacments'
        };
        List<String> fieldNamesToSelect = new List<String>();
        for (Schema.SObjectType sObjType : attachmentsParentsIdsByType.keySet()) {
            String relationshipName = attachmentRelationDecriptionByType.get(sObjType).getRelationshipName();
            String fieldName = attachmentRelationDecriptionByType.get(sObjType).getName();
            fieldNamesToSelect.add(String.format('{0}, {1}.{2}', new List<String> {fieldName, relationshipName, 'Name'}));
        }
        String query = String.format(QUERY_FORMAT, new List<String> {
                String.join(fieldNamesToSelect, ', '),
                String.join(whereConditionmembers, ' OR ')
        });
        return Database.query(query);
    }

    /*
    * @Method       : getHazardAssesmentsAndChildsByPMRA.
    * @Description  : Returns map of queried Hazard Assessment records with childs.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : Map<Id, List<Hazard_Assessment__c>>.
    * @Params       : Set<Id> hazarAssesmentsIds.
    */
    Map<Id, List<Hazard_Assessment__c>> getHazardAssesmentsAndChildsByPMRA(Set<Id> hazarAssesmentsIds) {
        Map<Id, List<Hazard_Assessment__c>> mapHazardAssesmentsByRisk = new Map<Id, List<Hazard_Assessment__c>>();
        for (Hazard_Assessment__c objHazardAssessment
                : [
                SELECT Id, Name, Assignee__c, Assignee__r.Name, Description_of_the_Hazard__c,
                        For_Incorrect_Results_describe__c, For_delay_of_results_is_maximum_tolerab__c,
                        Delay_of_results_associated_with_an_ASR__c, Rationale_Associated_to_Delay_of_Results__c,
                        Is_the_hazard_identified_in_the_RMF__c, Known_hazard_src_pred_freq_IDd_in_RMF__c,
                        RMF_Source_Reference_and_Location__c, RMF_Description_of_Hazard__c,
                        RMF_Descr_of_Source_Cause_of_Hazard__c, RMF_Severity__c, RMF_Predicted_Frequency_Category__c,
                        RMF_Frequencey_Type__c, RMF_Residual_Risk_Level__c, Update_to_RMF_required__c,
                        Approach_for_Data_Analysis__c, Descr_Data_Used_Data_Anlys_Rationale__c,
                        Estimated_Current_Frequency_of_Hazard__c, Current_Frequency_of_Hazard_Category__c,
                        Current_Residual_Risk_Level__c, Does_the_Curt_Est_Freq_trigger_risk_eval__c,
                        Opt_Risk_Evaluation_Will_be_Performed__c, Optional_Risk_Evaluation_Rationale__c,
                        Describe_Existing_Control_Measures_RMF__c, Complaint_Search_Criteria_and_Results__c,
                        Hazard_easily_identifiable_If_so_how__c, Medical_Affairs_Assessor__c,
                        Secondary_Medical_Affairs_Assessor__c, Potential_Harm__c, Current_Severity_Level__c,
                        Probability_of_Occurrence_of_Harm__c, Health_Hazard_Risk_Level__c,
                        Health_Hazard_Risk_Rationale__c, Update_to_RMF_required_per_HHA__c,
                        Medical_Affairs_Assessor__r.Name, Secondary_Medical_Affairs_Assessor__r.Name,
                        Post_Market_Risk_Assessment_Risk_Contr__c, CMPL123_WF_Status__c, Hazard_Type__c,
                        RMF_Severity_New__c, RMF_Predicted_Frequency_Category_New__c, RMF_Residual_Risk_Level_New__c,
                        Update_to_RMF_required_Justification__c, Hazard_Assessment_Completed_By__c,
                        Hazard_Assessment_Completed_Date__c, HHA_Completed_By__c, HHA_Completed_Date__c,
                (
                        SELECT CreatedById, Current_Severity_Level__c, Health_Hazard_Risk_Level__c,
                                Health_Hazard_Risk_Rationale__c, Id, IsDeleted, LastViewedDate, Name,
                                Potential_Harm__c, Probability_of_Occurrence_of_Harm__c
                        FROM Health_Hazard_Assessments__r
                ), (
                        SELECT Id, Name, Known_hazard_src_pred_freq_ID_d_in_RMF__c, RMF_Source_Reference_and_Location__c,
                                RMF_Description_of_Hazard__c, RMF_Descr_of_Source_Cause_of_Hazard__c, RMF_Severity__c,
                                RMF_Predicted_Frequency_Category__c, RMF_Residual_Risk_Level__c
                        FROM RMFs__r
                )
                FROM Hazard_Assessment__c
                WHERE Id IN:hazarAssesmentsIds
                ORDER BY Post_Market_Risk_Assessment_Risk_Contr__c
        ]) {
            if (!mapHazardAssesmentsByRisk.containsKey(objHazardAssessment.Post_Market_Risk_Assessment_Risk_Contr__c)) {
                mapHazardAssesmentsByRisk.put(objHazardAssessment.Post_Market_Risk_Assessment_Risk_Contr__c, new List<Hazard_Assessment__c>{
                        objHazardAssessment
                });
            }
            else {
                mapHazardAssesmentsByRisk.get(objHazardAssessment.Post_Market_Risk_Assessment_Risk_Contr__c).add(objHazardAssessment);
            }
        }
        return mapHazardAssesmentsByRisk;
    }

    /*
    * @Method       : getWhereClause.
    * @Description  : Returns string with WHERE clause.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : String.
    * @Params       : List<String> riskIds, List<String> riskNames.
    */
    @TestVisible
    String getWhereClause(List<String> riskIds, List<String> riskNames) {
        if (!riskNames.isEmpty()) {
            return ' WHERE Name IN :riskNames';
        }
        if (!riskIds.isEmpty()) {
            return ' WHERE Id IN :riskIds';
        }
        return ' LIMIT 50';
    }

    /*
    * @Method       : getAttachmentRelationDescriptionByType.
    * @Description  : Returns map with relationship description by type.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : Map<Schema.SObjectType, DescribeFieldResult>.
    * @Params       : List<Schema.SObjectType> objectsWithAttachments.
    */
    @TestVisible
    Map<Schema.SObjectType, DescribeFieldResult> getAttachmentRelationDescriptionByType(List<Schema.SObjectType> objectsWithAttachments) {
        Map<Schema.SObjectType, DescribeFieldResult> relatioNamesByType = new Map<Schema.SObjectType, DescribeFieldResult>();
        for (SObjectField field : Attachment__c.SObjectType.getDescribe().fields.getMap().values()) {
            DescribeFieldResult fieldDescription = field.getDescribe();
            if (fieldDescription.getReferenceTo().size() == 0) continue;
            if (objectsWithAttachments.contains(fieldDescription.getReferenceTo().get(0))) {
                relatioNamesByType.put(fieldDescription.getReferenceTo().get(0), fieldDescription);
            }
        }
        return relatioNamesByType;
    }

    /*
    * @Method       : initializeAttachmentsParentIdsByTypeMap.
    * @Description  : Returns map with SOjbect type and set if ids.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : Map<Schema.SObjectType, Set<Id>>.
    * @Params       : Map<Schema.SObjectType, DescribeFieldResult> attachmentRelationNameByType.
    */
    @TestVisible
    Map<Schema.SObjectType, Set<Id>> initializeAttachmentsParentIdsByTypeMap(Map<Schema.SObjectType,
            DescribeFieldResult> attachmentRelationNameByType) {
        Map<Schema.SObjectType, Set<Id>> attachmentsParentIdsByType = new Map<SObjectType, Set<Id>>();
        for (Schema.SObjectType sObjType : attachmentRelationNameByType.keySet()) {
            attachmentsParentIdsByType.put(sObjType, new Set<Id>());
        }
        return attachmentsParentIdsByType;
    }

    /*
    * @Method       : getRecordsIdentifiers.
    * @Description  : Returns list with secured url param.
    * @Invoke       : From 'generateReport()' method.
    * @Return       : List<String>.
    * @Params       : String urlParamKey.
    */
    @TestVisible
    List<String> getRecordsIdentifiers(String urlParamKey) {
        String urlParam = System.currentPageReference().getParameters().get(urlParamKey);
        if (String.isNotBlank(urlParam)) {
            return String.escapeSingleQuotes(urlParam.escapeJava()).split('[ ;,.]+');
        }
        return new List<String>();
    }
}